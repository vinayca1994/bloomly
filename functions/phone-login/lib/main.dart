import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'otp.dart';

const _database = 'bloomly';
const _challenges = 'otp_challenges';
const _limits = 'otp_limits';
const _profiles = 'profiles';

/// Starts SMS lookup, or sends and checks a WhatsApp code.
///
/// SMS still finishes in the app with `createPhoneToken`. WhatsApp stores only
/// a hash, and returns an Appwrite session secret after the code matches.
Future<dynamic> main(dynamic context) async {
  try {
    final body = '${context.req.body ?? ''}';
    final reply = await _dispatch(body, DateTime.now().toUtc());
    return context.res.json(reply.body, reply.status);
  } on FormatException {
    return context.res.json({'error': 'Expected a JSON body.'}, 400);
  } catch (_) {
    context.log('phone-login');
    return context.res.json({'error': otpStartFailed}, 500);
  }
}

class _Reply {
  const _Reply(this.body, [this.status = 200]);

  final Map<String, dynamic> body;
  final int status;
}

Future<_Reply> _dispatch(String body, DateTime now) async {
  final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
  if (decoded is! Map) {
    return const _Reply({'error': 'Expected a JSON body.'}, 400);
  }
  final payload = Map<String, dynamic>.from(decoded);
  final action = payload['action']?.toString() ?? 'start';
  final channel = payload['channel']?.toString() ?? 'sms';
  if (action == 'verify' && channel == 'whatsapp') {
    return _verifyWhatsApp(payload, now);
  }
  if (action == 'start' && channel == 'whatsapp') {
    return _startWhatsApp(payload, now);
  }
  if (action == 'start' && channel == 'sms') return _startSms(payload);
  return const _Reply({'error': 'Choose WhatsApp or SMS.'}, 400);
}

Future<_Reply> _startSms(Map<String, dynamic> payload) async {
  if (Platform.environment['SMS_LOGIN'] != '1') {
    return const _Reply({
      'error': 'SMS sign-in is not available yet. Use WhatsApp.',
    }, 400);
  }
  final phone = payload['phone']?.toString() ?? '';
  if (!mobilePattern.hasMatch(phone)) {
    return const _Reply({'error': otpBadPhone}, 400);
  }
  final tables = TablesDB(_client());
  final limited = await _claimSend(tables, phone, DateTime.now().toUtc());
  if (limited != null) return _Reply({'error': limited}, 400);
  final users = Users(_client());
  final account = await _ensureUser(users, phone);
  return _Reply({'ok': true, 'userId': account.id});
}

Future<_Reply> _startWhatsApp(
    Map<String, dynamic> payload, DateTime now) async {
  final phone = payload['phone']?.toString() ?? '';
  if (!mobilePattern.hasMatch(phone)) {
    return const _Reply({'error': otpBadPhone}, 400);
  }
  final env = Platform.environment;
  final mock = mockOtpEnabled(env) && isMockPhone(phone);
  if (!mock && !whatsAppReady(env)) {
    return const _Reply({'error': whatsAppNotSetUp}, 400);
  }
  final pepper = pepperFor(
    configured: env['OTP_PEPPER'] ?? '',
    phone: phone,
    mockEnabled: mockOtpEnabled(env),
  );
  if (pepper.isEmpty) return const _Reply({'error': whatsAppNotSetUp}, 400);

  final tables = TablesDB(_client());
  final users = Users(_client());
  final known = await users.list(queries: [Query.equal('phone', phone), Query.limit(1)]);
  if (known.users.isNotEmpty) {
    final existing = await _readChallenge(tables, known.users.first.$id);
    if (existing != null) {
      final wait = cooldownError(
        sentAtMillis: epochMillis(existing['sentAt']),
        nowMillis: now.millisecondsSinceEpoch,
      );
      if (wait != null) return _Reply({'error': wait}, 400);
    }
  }
  final limited = await _claimSend(tables, phone, now);
  if (limited != null) return _Reply({'error': limited}, 400);
  final account = await _ensureUser(users, phone);

  final code = mock ? mockCode : _sixDigits(Random.secure());
  if (!mock) {
    try {
      await _sendWhatsApp(env, phone, code);
    } on WhatsAppSendException {
      return const _Reply({'error': otpSendFailed}, 502);
    }
  }
  final expiresAt = now.add(otpLifetime).millisecondsSinceEpoch;
  await _saveChallenge(
    tables,
    userId: account.id,
    phone: phone,
    codeHash: codeHash(pepper: pepper, userId: account.id, code: code),
    expiresAtMillis: expiresAt,
    sentAtMillis: now.millisecondsSinceEpoch,
  );
  return _Reply({'ok': true, 'userId': account.id});
}

Future<_Reply> _verifyWhatsApp(
    Map<String, dynamic> payload, DateTime now) async {
  final userId = payload['userId']?.toString() ?? '';
  final code = payload['code']?.toString().trim() ?? '';
  if (!userIdPattern.hasMatch(userId) || !otpPattern.hasMatch(code)) {
    return const _Reply({'error': otpRequestNew}, 400);
  }
  final tables = TablesDB(_client());
  final row = await _readChallenge(tables, userId);
  if (row == null) return const _Reply({'error': otpRequestNew}, 400);
  final phone = '${row['phone'] ?? ''}';
  if (!mobilePattern.hasMatch(phone)) {
    return const _Reply({'error': otpRequestNew}, 400);
  }

  final pepper = pepperFor(
    configured: Platform.environment['OTP_PEPPER'] ?? '',
    phone: phone,
    mockEnabled: mockOtpEnabled(Platform.environment),
  );
  if (pepper.isEmpty) return const _Reply({'error': whatsAppNotSetUp}, 400);
  if (isExpired(
      expiresAtMillis: epochMillis(row['expiresAt']),
      nowMillis: now.millisecondsSinceEpoch)) {
    await _deleteChallenge(tables, userId);
    return const _Reply({'error': otpExpired}, 400);
  }
  final attempts = readAttempts(row['attempts']);
  final claim = nextAttempt(attempts: attempts);
  if (claim.blocked) {
    await _deleteChallenge(tables, userId);
    return const _Reply({'error': otpTooMany}, 400);
  }
  final stamp = _stamp(Random.secure());
  await tables.updateRow(
    databaseId: _database,
    tableId: _challenges,
    rowId: userId,
    data: {'attempts': claim.attempts, 'attemptStamp': stamp},
  );
  final again = await _readChallenge(tables, userId);
  if (again == null || '${again['attemptStamp'] ?? ''}' != stamp) {
    return const _Reply({'error': otpWrong}, 400);
  }
  final expected = codeHash(pepper: pepper, userId: userId, code: code);
  if (!sameHash('${again['codeHash'] ?? ''}', expected)) {
    if (claim.attempts >= otpMaxAttempts) {
      await _deleteChallenge(tables, userId);
      return const _Reply({'error': otpTooMany}, 400);
    }
    return const _Reply({'error': otpWrong}, 400);
  }

  final users = Users(_client());
  await _ensureCustomerProfile(users, userId);
  await users.updatePhoneVerification(userId: userId, phoneVerification: true);
  final token = await users.createToken(userId: userId, expire: 900);
  if (token.secret.isEmpty) return const _Reply({'error': otpStartFailed}, 500);
  await _deleteChallenge(tables, userId);
  return _Reply({'userId': userId, 'secret': token.secret});
}

Future<({String id, bool isNew})> _ensureUser(Users users, String phone) async {
  final existing =
      await users.list(queries: [Query.equal('phone', phone), Query.limit(1)]);
  if (existing.users.isNotEmpty) {
    return (id: existing.users.first.$id, isNew: false);
  }
  try {
    final created = await users.create(userId: ID.unique(), phone: phone);
    return (id: created.$id, isNew: true);
  } on AppwriteException catch (error) {
    if (error.code != 409) rethrow;
    final again = await users
        .list(queries: [Query.equal('phone', phone), Query.limit(1)]);
    if (again.users.isEmpty) rethrow;
    return (id: again.users.first.$id, isNew: false);
  }
}

Future<Map<String, dynamic>?> _readChallenge(
    TablesDB tables, String userId) async {
  try {
    final row = await tables.getRow(
        databaseId: _database, tableId: _challenges, rowId: userId);
    return row.data;
  } on AppwriteException catch (error) {
    if (error.code == 404) return null;
    rethrow;
  }
}

Future<void> _saveChallenge(
  TablesDB tables, {
  required String userId,
  required String phone,
  required String codeHash,
  required int expiresAtMillis,
  required int sentAtMillis,
}) async {
  final data = {
    'phone': phone,
    'codeHash': codeHash,
    'expiresAt': '$expiresAtMillis',
    'sentAt': '$sentAtMillis',
    'attempts': 0,
    'attemptStamp': '',
  };
  try {
    await tables.updateRow(
        databaseId: _database, tableId: _challenges, rowId: userId, data: data);
  } on AppwriteException catch (error) {
    if (error.code != 404) rethrow;
    await tables.createRow(
      databaseId: _database,
      tableId: _challenges,
      rowId: userId,
      data: data,
      permissions: const [],
    );
  }
}

Future<void> _deleteChallenge(TablesDB tables, String userId) async {
  try {
    await tables.deleteRow(
        databaseId: _database, tableId: _challenges, rowId: userId);
  } on AppwriteException catch (error) {
    if (error.code != 404) rethrow;
  }
}

String _sixDigits(Random random) =>
    random.nextInt(1000000).toString().padLeft(6, '0');

String _stamp(Random random) => '${_sixDigits(random)}${_sixDigits(random)}';

Future<String?> _claimSend(TablesDB tables, String phone, DateTime now) async {
  final global = await _claimOne(
    tables,
    rowId: globalSendLimitId,
    phone: 'global',
    now: now,
    limit: otpGlobalSendLimit,
  );
  if (global != null) return global;
  return _claimOne(
    tables,
    rowId: sendLimitId(phone),
    phone: phone,
    now: now,
    limit: otpSendLimit,
  );
}

Future<String?> _claimOne(
  TablesDB tables, {
  required String rowId,
  required String phone,
  required DateTime now,
  required int limit,
}) async {
  Map<String, dynamic>? row;
  try {
    final existing = await tables.getRow(
      databaseId: _database,
      tableId: _limits,
      rowId: rowId,
    );
    row = existing.data;
  } on AppwriteException catch (error) {
    if (error.code != 404) rethrow;
  }
  final claim = claimSend(
    windowStart: epochMillis(row?['windowStart']),
    sendCount: readAttempts(row?['sendCount']),
    nowMillis: now.millisecondsSinceEpoch,
    limit: limit,
  );
  if (!claim.allowed) return otpSendLimited;
  final data = {
    'phone': phone,
    'windowStart': '${claim.windowStart}',
    'sendCount': claim.sendCount,
  };
  try {
    if (row == null) {
      await tables.createRow(
        databaseId: _database,
        tableId: _limits,
        rowId: rowId,
        data: data,
        permissions: const [],
      );
    } else {
      await tables.updateRow(
        databaseId: _database,
        tableId: _limits,
        rowId: rowId,
        data: data,
      );
    }
  } on AppwriteException catch (error) {
    if (error.code == 409) return otpSendLimited;
    rethrow;
  }
  return null;
}

Future<void> _ensureCustomerProfile(Users users, String userId) async {
  final tables = TablesDB(_client());
  try {
    await tables.getRow(databaseId: _database, tableId: _profiles, rowId: userId);
    return;
  } on AppwriteException catch (error) {
    if (error.code != 404) rethrow;
  }
  final user = await users.get(userId: userId);
  if (user.labels.contains('owner') || user.labels.contains('rider')) return;
  try {
    await tables.createRow(
      databaseId: _database,
      tableId: _profiles,
      rowId: userId,
      data: {
        'userId': userId,
        'name': user.name,
        'role': 'customer',
        'phone': user.phone,
        'email': user.email,
      },
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.read(Role.label('owner')),
      ],
    );
  } on AppwriteException catch (error) {
    if (error.code != 409) rethrow;
  }
}

class WhatsAppSendException implements Exception {
  const WhatsAppSendException();
}

Future<void> _sendWhatsApp(
    Map<String, String> env, String phone, String code) async {
  final payload = msg91OtpBody(
    template: whatsAppTemplate(env),
    phone: phone,
    code: code,
  );
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('https://control.msg91.com/api/v5/otp'),
    );
    request.followRedirects = false;
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set('authkey', env['MSG91_AUTH_KEY']!.trim());
    request.add(utf8.encode(jsonEncode(payload)));
    final response = await request.close().timeout(const Duration(seconds: 8));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        _msg91Failed(responseBody)) {
      throw const WhatsAppSendException();
    }
  } on WhatsAppSendException {
    rethrow;
  } catch (_) {
    throw const WhatsAppSendException();
  } finally {
    client.close(force: true);
  }
}

bool _msg91Failed(String responseBody) {
  final trimmed = responseBody.trim();
  if (trimmed.isEmpty || !trimmed.startsWith('{')) return false;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map) return false;
    return decoded['type']?.toString() == 'error' ||
        decoded['hasError'] == true;
  } on FormatException {
    return false;
  }
}

Client _client() {
  return Client()
      .setEndpoint(_env('APPWRITE_FUNCTION_API_ENDPOINT'))
      .setProject(_env('APPWRITE_FUNCTION_PROJECT_ID'))
      .setKey(_firstKey());
}

String _env(String key) => Platform.environment[key]?.trim() ?? '';

String _firstKey() {
  for (final key in ['APPWRITE_FUNCTION_API_KEY', 'APPWRITE_API_KEY']) {
    final value = _env(key);
    if (value.isNotEmpty) return value;
  }
  return '';
}
