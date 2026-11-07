import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/phone.dart';
import 'auth_result.dart';
import 'backend.dart';
import 'ids.dart';
import 'models.dart';
import 'online_payment.dart';
import 'stories.dart';

class AppwriteBackend extends BloomlyBackend {
  AppwriteBackend(this.config) {
    _client = Client()
        .setEndpoint(config.endpoint)
        .setProject(config.projectId);
    _tables = TablesDB(_client);
    _account = Account(_client);
    _storage = Storage(_client);
    _realtime = Realtime(_client);
    _functions = Functions(_client);
    unawaited(_load());
  }

  final AppConfig config;
  late final Client _client;
  late final TablesDB _tables;
  late final Account _account;
  late final Storage _storage;
  late final Realtime _realtime;
  late final Functions _functions;
  RealtimeSubscription? _subscription;
  Timer? _reconnect;
  Timer? _liveReload;
  var _liveReloadRunning = false;
  var _liveReloadAgain = false;

  bool _demo = false;

  @override
  bool ready = false;

  @override
  String? loadError;

  @override
  String? ordersError;

  static const _ordersLoadError = "Couldn't load deliveries. Pull to try again.";

  @override
  StoreSettings store = StoreSettings.fallback;

  @override
  List<ShopCategory> categories = [];

  @override
  List<Product> products = [];

  @override
  Profile? currentUser;

  @override
  List<OrderRecord> orders = [];

  List<Profile> _riders = [];
  final Map<String, RiderLocation> _locations = {};
  final Map<String, DeliveryReview> _reviews = {};

  List<Address> _cachedAddresses = [];
  final Map<String, Uint8List> _images = {};
  final Map<String, StreamController<OrderRecord?>> _watchers = {};

  @override
  Future<void> reload() async {
    ready = false;
    loadError = null;
    notifyListeners();
    await _load();
  }

  Future<void> _load() async {
    try {
      await _loadSession();
      await _refreshAddresses();
      await _reloadCatalog();
      await _reloadOrders();
      await _reloadDeliveryExtras();
      await expireStaleUpiOrders();
      await _listen();
      loadError = null;
    } on AppwriteException catch (error) {
      loadError = error.message ?? 'Could not reach Bloom.';
    } catch (_) {
      loadError = 'Could not reach Bloom.';
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  @override
  Future<void> onForeground() async {
    await _listen();
    await expireStaleUpiOrders();
  }

  Future<void> _listen() async {
    await _subscription?.close();
    _reconnect?.cancel();
    _subscription = _realtime.subscribe([
      Channel.tablesdb(Ids.database).table(Ids.orders).row().toString(),
      Channel.tablesdb(Ids.database).table(Ids.riderLocations).row().toString(),
      Channel.tablesdb(Ids.database).table(Ids.reviews).row().toString(),
    ]);
    _subscription!.stream.listen(
      (_) => _scheduleLiveReload(),
      onError: (Object _) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );
  }

  void _scheduleLiveReload() {
    _liveReload?.cancel();
    _liveReload = Timer(const Duration(milliseconds: 500), () {
      unawaited(_runLiveReload());
    });
  }

  Future<void> _runLiveReload() async {
    if (_liveReloadRunning) {
      _liveReloadAgain = true;
      return;
    }
    _liveReloadRunning = true;
    var failed = false;
    try {
      do {
        _liveReloadAgain = false;
        try {
          await _reloadOrders();
          await _reloadDeliveryExtras();
        } on AppwriteException {
          failed = true;
          ordersError = _ordersLoadError;
          notifyListeners();
        }
      } while (_liveReloadAgain && !failed);
    } finally {
      _liveReloadRunning = false;
    }
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 2), () {
      if (!ready) return;
      unawaited(_listen());
    });
  }

  Future<List<models.Row>> _all(String table) async {
    final collected = <models.Row>[];
    var offset = 0;
    while (true) {
      final page = await _tables.listRows(
        databaseId: Ids.database,
        tableId: table,
        queries: [Query.limit(100), Query.offset(offset)],
      );
      collected.addAll(page.rows);
      if (page.rows.length < 100) break;
      offset += 100;
    }
    return collected;
  }

  Future<void> _reloadCatalog() async {
    final storeDocs = await _all(Ids.store);
    if (storeDocs.isNotEmpty) {
      final loaded = _storeFrom(storeDocs.first);
      final fromEnv = config.upiId.trim();
      store = loaded.upiId.trim().isEmpty && fromEnv.isNotEmpty
          ? loaded.copyWith(
              upiId: fromEnv,
              upiName: config.upiName.trim().isEmpty
                  ? loaded.upiName
                  : config.upiName.trim(),
            )
          : loaded;
    }
    final categoryDocs = await _all(Ids.categories);
    categories = categoryDocs.map(_categoryFrom).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    final productDocs = await _all(Ids.products);
    final variantDocs = await _all(Ids.variants);
    products = [for (final doc in productDocs) _productFrom(doc, variantDocs)]
      ..sort((a, b) => a.sort.compareTo(b.sort));
  }

  @override
  Future<void> refreshOrders() async {
    try {
      await _reloadOrders();
    } on AppwriteException {
      ordersError = _ordersLoadError;
      notifyListeners();
    }
  }

  Future<void> _reloadOrders() async {
    final orderDocs = await _all(Ids.orders);
    var itemDocs = <models.Row>[];
    try {
      itemDocs = await _all(Ids.orderItems);
    } on AppwriteException {
      itemDocs = [];
    }
    orders = [for (final doc in orderDocs) _orderFrom(doc, itemDocs)]
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    ordersError = null;
    for (final order in orders) {
      _watchers[order.id]?.add(order);
    }
    notifyListeners();
  }

  @override
  Future<String?> signInDemo(String role) async {
    if (!kDebugMode) return 'Demo sign-in is off.';
    _demo = true;
    currentUser = switch (role) {
      'owner' => const Profile(
        id: 'owner-demo',
        name: 'Asha Rao',
        email: 'owner@bloomly.app',
        role: 'owner',
      ),
      'rider' => const Profile(
        id: 'rider-demo',
        name: 'Ravi',
        email: 'rider@bloomly.app',
        role: 'rider',
      ),
      _ => const Profile(
        id: 'customer-demo',
        name: 'Meera Nair',
        email: 'customer@bloomly.app',
        role: 'customer',
      ),
    };
    notifyListeners();
    return null;
  }

  Future<void> _loadSession() async {
    if (_demo) return;
    try {
      final user = await _account.get();
      currentUser = Profile(
        id: user.$id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.labels.contains('owner')
            ? 'owner'
            : user.labels.contains('rider')
            ? 'rider'
            : 'customer',
      );
    } on AppwriteException {
      currentUser = null;
    }
  }

  @override
  Uint8List? imageBytesFor(String productId) => _images[productId];

  @override
  List<Address> addressesFor(String userId) {
    return _cachedAddresses
        .where((address) => address.userId == userId)
        .toList();
  }

  @override
  OrderRecord? orderById(String id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  Stream<OrderRecord?> watchOrder(String id) {
    final controller = _watchers.putIfAbsent(
      id,
      () => StreamController<OrderRecord?>.broadcast(),
    );
    return controller.stream;
  }

  Future<void> _refreshAddresses() async {
    final user = currentUser;
    if (user == null) {
      _cachedAddresses = [];
      return;
    }
    final docs = await _all(Ids.addresses);
    _cachedAddresses = docs
        .map(_addressFrom)
        .where((address) => address.userId == user.id)
        .toList();
  }

  /// Appwrite rejects a new session while another one is still active.
  /// Signing in again has to end that session first, or a customer left
  /// on the store browser blocks the owner and riders.
  Future<T> _replacingSession<T>(Future<T> Function() create) async {
    try {
      return await create();
    } on AppwriteException catch (error) {
      if (error.type != 'user_session_already_exists') rethrow;
      try {
        await _account.deleteSession(sessionId: 'current');
      } on AppwriteException {
        throw error;
      }
      _demo = false;
      currentUser = null;
      _cachedAddresses = [];
      orders = [];
      return await create();
    }
  }

  Future<String?> _afterSignIn() async {
    await _loadSession();
    if (currentUser == null) return 'Could not sign in. Try again.';
    await _ensureProfile();
    try {
      await _refreshAddresses();
    } on AppwriteException {
      _cachedAddresses = [];
    }
    try {
      await _reloadOrders();
    } on AppwriteException {
      ordersError = _ordersLoadError;
    }
    notifyListeners();
    return null;
  }

  static const _rateLimitWait =
      'Too many attempts. Wait a few minutes, then try once.';

  String? _rateLimitMessage(AppwriteException error) {
    final message = (error.message ?? '').toLowerCase();
    if (error.code == 429 ||
        error.type == 'general_rate_limit_exceeded' ||
        message.contains('rate limit')) {
      return _rateLimitWait;
    }
    return null;
  }

  String _authMessage(AppwriteException error, String fallback) {
    final limited = _rateLimitMessage(error);
    if (limited != null) return limited;
    return switch (error.type) {
      'user_invalid_credentials' || 'user_not_found' =>
        'That email and password do not match.',
      'user_already_exists' => 'An account with this email already exists.',
      'user_invalid_token' || 'user_token_expired' =>
        'That code is wrong or expired. Request a new one.',
      'user_session_already_exists' => 'Sign out, then try again.',
      _ => error.message ?? fallback,
    };
  }

  @override
  Future<String?> signIn(String email, String password) async {
    _demo = false;
    try {
      final normalized = email.trim().toLowerCase();
      await _replacingSession(
        () => _account.createEmailPasswordSession(
          email: normalized,
          password: password,
        ),
      );
      return await _afterSignIn();
    } on AppwriteException catch (error) {
      return _authMessage(error, 'Could not sign in.');
    }
  }

  @override
  Future<String?> signUp(String name, String email, String password) async {
    try {
      final normalized = email.trim().toLowerCase();
      await _replacingSession(
        () => _account.create(
          userId: ID.unique(),
          email: normalized,
          password: password,
          name: name.trim(),
        ),
      );
      await _replacingSession(
        () => _account.createEmailPasswordSession(
          email: normalized,
          password: password,
        ),
      );
      return await _afterSignIn();
    } on AppwriteException catch (error) {
      return _authMessage(error, 'Could not create the account.');
    }
  }

  @override
  Future<PhoneLoginStart> startPhoneLogin(
    String phone, {
    required OtpChannel channel,
  }) async {
    if (channel == OtpChannel.email) {
      return const PhoneLoginStart.failure(
        'Use email sign-in for an email code.',
      );
    }
    final normalized = PhoneNumber.normalizeIndia(phone);
    if (normalized == null) {
      return const PhoneLoginStart.failure(
        'Enter a valid 10-digit mobile number.',
      );
    }
    if (channel == OtpChannel.sms && !smsLoginLive) {
      return const PhoneLoginStart.failure(
        'SMS sign-in is not available yet. Use WhatsApp.',
      );
    }
    try {
      final payload = await _execute(Ids.phoneLogin, {
        'action': 'start',
        'channel': channel.name,
        'phone': normalized,
      });
      final userId = payload['userId']?.toString() ?? '';
      if (userId.isEmpty) {
        return const PhoneLoginStart.failure('Could not start phone sign-in.');
      }
      if (channel == OtpChannel.sms) {
        await _replacingSession(
          () => _account.createPhoneToken(userId: userId, phone: normalized),
        );
      }
      return PhoneLoginStart(userId: userId, isNew: payload['isNew'] == true);
    } on BloomlyException catch (error) {
      return PhoneLoginStart.failure(error.message);
    } on AppwriteException catch (error) {
      return PhoneLoginStart.failure(
        _authMessage(error, 'Could not send the code.'),
      );
    }
  }

  @override
  Future<String?> verifyPhoneOtp({
    required String userId,
    required String code,
    required OtpChannel channel,
  }) async {
    try {
      _demo = false;
      final secret = await _otpSecret(
        userId: userId,
        code: code,
        channel: channel,
      );
      if (secret == null) return 'That code is wrong.';
      await _replacingSession(
        () => _account.createSession(userId: userId, secret: secret),
      );
      return await _afterSignIn();
    } on BloomlyException catch (error) {
      return error.message;
    } on AppwriteException catch (error) {
      return _authMessage(error, 'That code is wrong.');
    }
  }

  Future<String?> _otpSecret({
    required String userId,
    required String code,
    required OtpChannel channel,
  }) async {
    if (channel == OtpChannel.sms) return code.trim();
    final payload = await _execute(Ids.phoneLogin, {
      'action': 'verify',
      'channel': channel.name,
      'userId': userId,
      'code': code.trim(),
    });
    final secret = payload['secret']?.toString() ?? '';
    if (secret.isEmpty) return null;
    return secret;
  }

  @override
  Future<PhoneLoginStart> startEmailLogin(String email) async {
    final normalized = normalizeLoginEmail(email);
    if (normalized == null) {
      return const PhoneLoginStart.failure('Enter a valid email address.');
    }
    try {
      final token = await _account.createEmailToken(
        userId: ID.unique(),
        email: normalized,
      );
      if (token.userId.isEmpty) {
        return const PhoneLoginStart.failure('Could not send the code.');
      }
      return PhoneLoginStart(userId: token.userId);
    } on AppwriteException catch (error) {
      return PhoneLoginStart.failure(
        _authMessage(error, 'Could not send the code.'),
      );
    }
  }

  @override
  Future<String?> verifyEmailOtp({
    required String userId,
    required String code,
  }) async {
    _demo = false;
    try {
      await _replacingSession(
        () => _account.createSession(userId: userId, secret: code.trim()),
      );
      return await _afterSignIn();
    } on AppwriteException catch (error) {
      return _authMessage(error, 'That code is wrong.');
    }
  }

  @override
  Future<String?> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Add your name.';
    final user = currentUser;
    if (user == null) return 'Sign in first.';
    try {
      await _account.updateName(name: trimmed);
      try {
        await _execute(Ids.payments, {'action': 'updateName', 'name': trimmed});
      } on BloomlyException {
        // The account name is saved. The profile row can catch up later.
      }
      await _loadSession();
      notifyListeners();
      return null;
    } on AppwriteException catch (error) {
      return error.message ?? 'Could not save your name.';
    }
  }

  @override
  Future<RecoveryStart> sendPasswordReset(String email) async {
    try {
      final token = await _account.createRecoveryOTP(
        email: email.trim().toLowerCase(),
      );
      return RecoveryStart(userId: token.userId);
    } on AppwriteException catch (error) {
      return RecoveryStart.failure(
        _authMessage(error, 'Could not send a reset code.'),
      );
    }
  }

  @override
  Future<String?> completePasswordReset({
    required String userId,
    required String code,
    required String password,
  }) async {
    if (password.length < 8) return 'Use at least 8 characters.';
    try {
      await _account.updateRecoveryOTP(
        userId: userId,
        secret: code.trim(),
        password: password,
      );
      return null;
    } on AppwriteException catch (error) {
      return _authMessage(error, 'Could not reset the password.');
    }
  }

  @override
  Future<String?> signOut() async {
    if (_demo) {
      _demo = false;
      currentUser = null;
      _cachedAddresses = [];
      orders = [];
      notifyListeners();
      return null;
    }
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (error) {
      return error.message ??
          'Could not sign out. Check your connection and try again.';
    } catch (_) {
      return 'Could not sign out. Check your connection and try again.';
    }
    currentUser = null;
    _cachedAddresses = [];
    orders = [];
    notifyListeners();
    return null;
  }

  @override
  Future<String?> deleteAccount({String? password}) async {
    final user = currentUser;
    if (user == null) return 'Sign in first.';
    if (user.isOwner) return 'The store owner account cannot be deleted here.';
    if (user.isRider) return 'A rider account stays signed in here.';
    try {
      await _execute(Ids.payments, {
        'action': 'deleteAccount',
        'password': ?password,
      });
      currentUser = null;
      _cachedAddresses = [];
      orders = [];
      notifyListeners();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    } on AppwriteException catch (error) {
      return error.message ?? 'Could not delete the account.';
    }
  }

  @override
  Future<void> saveAddress(Address address) async {
    final user = currentUser;
    if (user == null) return;
    if (address.isDefault) {
      for (final existing in _cachedAddresses) {
        if (existing.isDefault && existing.id != address.id) {
          await _tables.updateRow(
            databaseId: Ids.database,
            tableId: Ids.addresses,
            rowId: existing.id,
            data: {'isDefault': false},
          );
        }
      }
    }
    final known = _cachedAddresses.any((item) => item.id == address.id);
    if (known) {
      await _tables.updateRow(
        databaseId: Ids.database,
        tableId: Ids.addresses,
        rowId: address.id,
        data: address.toMap(),
      );
    } else {
      await _tables.createRow(
        databaseId: Ids.database,
        tableId: Ids.addresses,
        rowId: address.id,
        data: address.toMap(),
        permissions: _addressPerms(user.id),
      );
    }
    await _refreshAddresses();
    notifyListeners();
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _tables.deleteRow(
      databaseId: Ids.database,
      tableId: Ids.addresses,
      rowId: id,
    );
    await _refreshAddresses();
    notifyListeners();
  }

  @override
  Future<OrderRecord> placeOrder({
    required String userId,
    required Address address,
    required List<CartLine> lines,
    String? idempotencyKey,
  }) async {
    final payload = await _execute(Ids.payments, {
      'action': 'create',
      'method': PaymentMethod.cod,
      'idempotencyKey': _checkoutKey(idempotencyKey),
      'address': address.toMap(),
      'lines': [for (final line in lines) line.toJson()],
    });
    await _reloadOrders();
    final order = orderById(payload['orderId']?.toString() ?? '');
    if (order == null) {
      throw BloomlyException('The order was placed but could not be opened.');
    }
    return order;
  }

  @override
  Future<OnlinePayment> startOnlinePayment({
    required String userId,
    required Address address,
    required List<CartLine> lines,
    String? idempotencyKey,
  }) async {
    final payload = await _execute(Ids.payments, {
      'action': 'create',
      'method': PaymentMethod.upi,
      'idempotencyKey': _checkoutKey(idempotencyKey),
      'address': address.toMap(),
      'lines': [for (final line in lines) line.toJson()],
    });
    await _reloadOrders();
    final orderId = payload['orderId']?.toString() ?? '';
    final order = orderById(orderId);
    if (order == null) {
      throw BloomlyException(
        'The payment was started but the order is missing.',
      );
    }
    final amount = payload['amountRupees'];
    final amountRupees = amount is num
        ? amount.round()
        : int.tryParse('$amount') ?? order.total;
    return OnlinePayment(
      order: order,
      amountRupees: amountRupees,
      keyId: payload['keyId']?.toString().trim() ?? '',
      razorpayOrderId: payload['razorpayOrderId']?.toString().trim() ?? '',
    );
  }

  @override
  Future<OnlinePayment> resumeOnlinePayment(String orderId) async {
    final payload = await _execute(Ids.payments, {
      'action': 'checkout',
      'orderId': orderId,
    });
    await _reloadOrders();
    final id = payload['orderId']?.toString() ?? orderId;
    final order = orderById(id);
    if (order == null) {
      throw BloomlyException('The payment was started but the order is missing.');
    }
    final amount = payload['amountRupees'];
    final amountRupees = amount is num
        ? amount.round()
        : int.tryParse('$amount') ?? order.total;
    return OnlinePayment(
      order: order,
      amountRupees: amountRupees,
      keyId: payload['keyId']?.toString().trim() ?? '',
      razorpayOrderId: payload['razorpayOrderId']?.toString().trim() ?? '',
    );
  }

  @override
  Future<String?> verifyOnlinePayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String signature,
  }) async {
    try {
      await _execute(Ids.payments, {
        'action': 'verify',
        'orderId': orderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'signature': signature,
      });
      await _reloadOrders();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> noteUpiPayment({
    required String orderId,
    required String reference,
  }) async {
    try {
      await _execute(Ids.payments, {
        'action': 'note',
        'orderId': orderId,
        'reference': reference,
      });
      await _reloadOrders();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> confirmUpiPayment(String orderId) async {
    try {
      await _execute(Ids.payments, {'action': 'confirm', 'orderId': orderId});
      await _reloadOrders();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> completeTestPayment(String orderId) async {
    if (orderId.isEmpty) return 'Order not found.';
    return 'This shop confirms UPI through Razorpay.';
  }

  Future<Map<String, dynamic>> _execute(
    String functionId,
    Map<String, dynamic> body,
  ) async {
    try {
      final execution = await _functions.createExecution(
        functionId: functionId,
        body: jsonEncode(body),
        xasync: false,
      );
      if (execution.responseBody.isEmpty) {
        throw BloomlyException('Bloom could not reach $functionId.');
      }
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is! Map) {
        throw BloomlyException('Bloom could not reach $functionId.');
      }
      final payload = Map<String, dynamic>.from(decoded);
      final error = payload['error']?.toString() ?? '';
      if (error.isNotEmpty || execution.responseStatusCode >= 400) {
        final shown = error.toLowerCase().contains('rate limit')
            ? _rateLimitWait
            : (error.isEmpty ? 'Bloom could not reach $functionId.' : error);
        throw BloomlyException(shown);
      }
      return payload;
    } on BloomlyException {
      rethrow;
    } on AppwriteException catch (error) {
      throw BloomlyException(
        _authMessage(error, 'Bloom could not reach $functionId.'),
      );
    }
  }

  @override
  List<Profile> get riders => List<Profile>.unmodifiable(_riders);

  @override
  RiderLocation? locationFor(String orderId) => _locations[orderId];

  @override
  DeliveryReview? reviewFor(String orderId) => _reviews[orderId];

  @override
  Future<String?> updateOrderStatus(String orderId, String status) async {
    try {
      await _execute(Ids.payments, {
        'action': 'advance',
        'orderId': orderId,
        'status': status,
      });
      await _reloadOrders();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> markRefunded(String orderId) async {
    try {
      await _execute(Ids.payments, {
        'action': 'markRefunded',
        'orderId': orderId,
      });
      await _reloadOrders();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  Future<void> _reloadDeliveryExtras() async {
    if (currentUser?.isOwner == true) {
      try {
        final payload = await _execute(Ids.payments, {'action': 'listRiders'});
        final rows = payload['riders'];
        _riders = [
          if (rows is List)
            for (final row in rows)
              if (row is Map)
                Profile(
                  id: '${row['id'] ?? ''}',
                  name: '${row['name'] ?? ''}',
                  email: '${row['email'] ?? ''}',
                  role: 'rider',
                ),
        ]..sort((a, b) => a.name.compareTo(b.name));
      } on BloomlyException {
        _riders = [];
      }
    } else {
      _riders = [];
    }
    try {
      final docs = await _all(Ids.riderLocations);
      _locations
        ..clear()
        ..addEntries([
          for (final doc in docs)
            if (_locationFrom(doc) case final location?)
              MapEntry(location.orderId, location),
        ]);
    } on AppwriteException {
      _locations.clear();
    }
    try {
      final docs = await _all(Ids.reviews);
      _reviews
        ..clear()
        ..addEntries([
          for (final doc in docs)
            MapEntry(_text(doc.data, 'orderId', doc.$id), _reviewFrom(doc)),
        ]);
    } on AppwriteException {
      _reviews.clear();
    }
  }

  @override
  Future<String?> createRider({
    required String name,
    required String email,
    required String password,
  }) async {
    if (currentUser?.isOwner != true) return 'Only the store can add a rider.';
    try {
      final payload = await _execute(Ids.payments, {
        'action': 'createRider',
        'name': name,
        'email': email,
      });
      await _reloadDeliveryExtras();
      notifyListeners();
      if (payload['recovery'] == false) {
        return 'The rider was added, but the sign-in email did not send. Ask them to tap Forgot password.';
      }
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> assignRider({
    required String orderId,
    required String riderId,
  }) async {
    if (currentUser?.isOwner != true) {
      return 'Only the store can assign a rider.';
    }
    try {
      await _execute(Ids.payments, {
        'action': 'assignRider',
        'orderId': orderId,
        'riderId': riderId,
      });
      await _reloadOrders();
      await _reloadDeliveryExtras();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> updateRiderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _execute(Ids.payments, {
        'action': 'updateLocation',
        'orderId': orderId,
        'latitude': latitude,
        'longitude': longitude,
      });
      await _reloadDeliveryExtras();
      final order = orderById(orderId);
      if (order != null) _watchers[orderId]?.add(order);
      notifyListeners();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> markDelivered(String orderId) async {
    try {
      await _execute(Ids.payments, {
        'action': 'markDelivered',
        'orderId': orderId,
      });
      await _reloadOrders();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> submitReview({
    required String orderId,
    required int freshness,
    required int rightItems,
    required int packing,
    required int onTime,
    required int polite,
    required int careful,
    String note = '',
  }) async {
    final rejected = DeliveryReview.rejectScores(
      freshness: freshness,
      rightItems: rightItems,
      packing: packing,
      onTime: onTime,
      polite: polite,
      careful: careful,
      note: note,
    );
    if (rejected != null) return rejected;
    try {
      await _execute(Ids.payments, {
        'action': 'submitReview',
        'orderId': orderId,
        'freshness': freshness,
        'rightItems': rightItems,
        'packing': packing,
        'onTime': onTime,
        'polite': polite,
        'careful': careful,
        'note': note,
      });
      await _reloadDeliveryExtras();
      final order = orderById(orderId);
      if (order != null) _watchers[orderId]?.add(order);
      notifyListeners();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> cancelOrder(String orderId) async {
    try {
      await _execute(Ids.payments, {'action': 'cancel', 'orderId': orderId});
      await _reloadOrders();
      return null;
    } on BloomlyException catch (error) {
      return error.message;
    }
  }

  @override
  Future<void> expireStaleUpiOrders() async {
    if (currentUser == null) return;
    try {
      await _execute(Ids.payments, {'action': 'expire'});
      await _reloadOrders();
    } on BloomlyException {
      // The schedule still cancels unpaid UPI orders if this call fails.
    }
  }

  @override
  Future<String?> uploadPromoMedia({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (bytes.length > 5000000) {
      throw BloomlyException('That file is over 5 MB.');
    }
    if (_demo) return null;
    final file = await _storage.createFile(
      bucketId: Ids.bucket,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: bytes, filename: filename),
      permissions: [Permission.read(Role.any())],
    );
    return '${config.endpoint}/storage/buckets/${Ids.bucket}/files/${file.$id}/view?project=${config.projectId}';
  }

  @override
  Future<void> updateStore(StoreSettings next) async {
    if (_demo) {
      store = next;
      notifyListeners();
      return;
    }
    try {
      await _tables.updateRow(
        databaseId: Ids.database,
        tableId: Ids.store,
        rowId: Ids.storeRow,
        data: next.toMap(),
      );
    } on AppwriteException catch (error) {
      final denied = error.code == 401 || error.type == 'user_unauthorized';
      if (denied) {
        throw BloomlyException(
          'Sign in with the store owner account to publish.',
        );
      }
      rethrow;
    }
    store = next;
    notifyListeners();
  }

  @override
  Future<void> setProductAvailable(String productId, bool available) async {
    await _tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.products,
      rowId: productId,
      data: {'isAvailable': available},
    );
    products = [
      for (final product in products)
        if (product.id == productId)
          product.copyWith(isAvailable: available)
        else
          product,
    ];
    notifyListeners();
  }

  @override
  Future<void> setVariantPrice(
    String productId,
    String variantId,
    int price,
  ) async {
    await _tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.variants,
      rowId: variantId,
      data: {'price': price},
    );
    products = [
      for (final product in products)
        if (product.id != productId)
          product
        else
          product.copyWith(
            variants: [
              for (final variant in product.variants)
                if (variant.id == variantId)
                  variant.copyWith(price: price)
                else
                  variant,
            ],
          ),
    ];
    notifyListeners();
  }

  @override
  Future<void> upsertProduct(Product product, {Uint8List? imageBytes}) async {
    var imageUrl = product.imageUrl ?? '';
    final id = product.id.isEmpty ? ID.unique() : product.id;
    if (imageBytes != null) {
      final file = await _storage.createFile(
        bucketId: Ids.bucket,
        fileId: ID.unique(),
        file: InputFile.fromBytes(bytes: imageBytes, filename: '$id.jpg'),
        permissions: [Permission.read(Role.any())],
      );
      imageUrl =
          '${config.endpoint}/storage/buckets/${Ids.bucket}/files/${file.$id}/view?project=${config.projectId}';
      _images[id] = imageBytes;
    }
    final data = product.toMap()..['imageUrl'] = imageUrl;
    final exists =
        product.id.isNotEmpty && products.any((item) => item.id == product.id);
    if (exists) {
      await _tables.updateRow(
        databaseId: Ids.database,
        tableId: Ids.products,
        rowId: id,
        data: data,
      );
    } else {
      await _tables.createRow(
        databaseId: Ids.database,
        tableId: Ids.products,
        rowId: id,
        data: data,
      );
    }
    for (var i = 0; i < product.variants.length; i++) {
      final variant = product.variants[i];
      final variantId = variant.id.isEmpty ? '$id-v$i' : variant.id;
      final payload = variant.toMap()..['productId'] = id;
      final known =
          variant.id.isNotEmpty &&
          products
              .where((item) => item.id == id)
              .expand((item) => item.variants)
              .any((item) => item.id == variant.id);
      if (known) {
        await _tables.updateRow(
          databaseId: Ids.database,
          tableId: Ids.variants,
          rowId: variantId,
          data: payload,
        );
      } else {
        await _tables.createRow(
          databaseId: Ids.database,
          tableId: Ids.variants,
          rowId: variantId,
          data: payload,
        );
      }
    }
    await _reloadCatalog();
    notifyListeners();
  }

  List<String> _addressPerms(String userId) => [
    Permission.read(Role.user(userId)),
    Permission.update(Role.user(userId)),
    Permission.delete(Role.user(userId)),
    Permission.read(Role.label('owner')),
    Permission.update(Role.label('owner')),
  ];

  Future<void> _ensureProfile() async {
    if (currentUser == null || currentUser!.isOwner || currentUser!.isRider) {
      return;
    }
    try {
      await _execute(Ids.payments, {'action': 'ensureProfile'});
    } on BloomlyException {
      // Sign-in still stands. The next open tries the profile again.
    }
  }

  String _checkoutKey(String? provided) {
    final key = provided?.trim() ?? '';
    if (RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$').hasMatch(key)) return key;
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'k$micros';
  }

  @override
  void dispose() {
    _reconnect?.cancel();
    _liveReload?.cancel();
    unawaited(_subscription?.close());
    for (final controller in _watchers.values) {
      controller.close();
    }
    super.dispose();
  }
}

StoreSettings _storeFrom(models.Row doc) {
  final data = doc.data;
  return StoreSettings(
    city: _text(data, 'city', StoreSettings.fallback.city),
    etaLabel: _text(data, 'etaLabel', StoreSettings.fallback.etaLabel),
    deliveryFee: _int(data, 'deliveryFee', StoreSettings.fallback.deliveryFee),
    freeDeliveryAbove: _int(
      data,
      'freeDeliveryAbove',
      StoreSettings.fallback.freeDeliveryAbove,
    ),
    pincode: _text(data, 'pincode', StoreSettings.fallback.pincode),
    upiId: _text(data, 'upiId', ''),
    upiName: _text(data, 'upiName', StoreSettings.fallback.upiName),
    storePhone: _text(data, 'storePhone', ''),
    promotions: decodePromotions(_text(data, 'promotions', '')),
  );
}

ShopCategory _categoryFrom(models.Row doc) {
  final data = doc.data;
  final parent = _text(data, 'parentSlug', '');
  return ShopCategory(
    id: doc.$id,
    name: _text(data, 'name', ''),
    slug: _text(data, 'slug', doc.$id),
    kind: _text(data, 'kind', 'vegetable'),
    parentSlug: parent.isEmpty ? null : parent,
    sort: _int(data, 'sort', 0),
    emoji: _text(data, 'emoji', '🛒'),
  );
}

Product _productFrom(models.Row doc, List<models.Row> variantDocs) {
  final data = doc.data;
  final image = _text(data, 'imageUrl', '');
  return Product(
    id: doc.$id,
    name: _text(data, 'name', ''),
    categorySlug: _text(data, 'categorySlug', ''),
    description: _text(data, 'description', ''),
    imageUrl: image.isEmpty ? null : image,
    isAvailable: _bool(data, 'isAvailable'),
    region: _text(data, 'region', ''),
    sort: _int(data, 'sort', 0),
    variants: [
      for (final variant in variantDocs)
        if (_text(variant.data, 'productId', '') == doc.$id)
          _variantFrom(variant),
    ],
  );
}

Variant _variantFrom(models.Row doc) {
  final data = doc.data;
  return Variant(
    id: doc.$id,
    productId: _text(data, 'productId', ''),
    label: _text(data, 'label', ''),
    price: _int(data, 'price', 0),
    mrp: _int(data, 'mrp', 0),
    isAvailable: _bool(data, 'isAvailable'),
  );
}

Address _addressFrom(models.Row doc) {
  final data = doc.data;
  return Address(
    id: doc.$id,
    userId: _text(data, 'userId', ''),
    label: _text(data, 'label', 'Home'),
    line: _text(data, 'line', ''),
    area: _text(data, 'area', ''),
    city: _text(data, 'city', ''),
    pincode: _text(data, 'pincode', ''),
    landmark: _text(data, 'landmark', ''),
    isDefault: _bool(data, 'isDefault'),
    latitude: _double(data, 'latitude'),
    longitude: _double(data, 'longitude'),
  );
}

OrderRecord _orderFrom(models.Row doc, List<models.Row> itemDocs) {
  final data = doc.data;
  return OrderRecord(
    id: doc.$id,
    userId: _text(data, 'userId', ''),
    addressSnapshot: _text(data, 'addressSnapshot', ''),
    status: _text(data, 'status', OrderStatus.placed),
    subtotal: _int(data, 'subtotal', 0),
    deliveryFee: _int(data, 'deliveryFee', 0),
    total: _int(data, 'total', 0),
    paymentMethod: _text(data, 'paymentMethod', PaymentMethod.cod),
    paymentStatus: _text(data, 'paymentStatus', PaymentStatus.pending),
    gatewayOrderId: _text(data, 'gatewayOrderId', ''),
    gatewayPaymentId: _text(data, 'gatewayPaymentId', ''),
    upiTxnRef: _text(data, 'upiTxnRef', ''),
    riderId: _text(data, 'riderId', ''),
    riderName: _text(data, 'riderName', ''),
    customerPhone: _text(data, 'customerPhone', ''),
    destLatitude: _double(data, 'destLatitude'),
    destLongitude: _double(data, 'destLongitude'),
    placedAt: DateTime.tryParse(_text(data, 'placedAt', '')) ?? DateTime.now(),
    items: [
      for (final item in itemDocs)
        if (_text(item.data, 'orderId', '') == doc.$id) _itemFrom(item),
    ],
  );
}

OrderItem _itemFrom(models.Row doc) {
  final data = doc.data;
  return OrderItem(
    id: doc.$id,
    orderId: _text(data, 'orderId', ''),
    productId: _text(data, 'productId', ''),
    name: _text(data, 'name', ''),
    variantLabel: _text(data, 'variantLabel', ''),
    unitPrice: _int(data, 'unitPrice', 0),
    qty: _int(data, 'qty', 0),
  );
}

String _text(Map<String, dynamic> data, String key, String fallback) {
  final value = data[key];
  if (value == null) return fallback;
  return value.toString();
}

double? _double(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

int _int(Map<String, dynamic> data, String key, int fallback) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? fallback;
}

bool _bool(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value == 'true';
}

RiderLocation? _locationFrom(models.Row doc) {
  final data = doc.data;
  final latitude = _double(data, 'latitude');
  final longitude = _double(data, 'longitude');
  if (latitude == null || longitude == null) return null;
  return RiderLocation(
    orderId: _text(data, 'orderId', doc.$id),
    latitude: latitude,
    longitude: longitude,
    updatedAt:
        DateTime.tryParse(_text(data, 'updatedAt', '')) ?? DateTime.now(),
  );
}

DeliveryReview _reviewFrom(models.Row doc) {
  final data = doc.data;
  return DeliveryReview(
    orderId: _text(data, 'orderId', doc.$id),
    userId: _text(data, 'userId', ''),
    riderId: _text(data, 'riderId', ''),
    freshness: _int(data, 'freshness', 0),
    rightItems: _int(data, 'rightItems', 0),
    packing: _int(data, 'packing', 0),
    onTime: _int(data, 'onTime', 0),
    polite: _int(data, 'polite', 0),
    careful: _int(data, 'careful', 0),
    note: _text(data, 'note', ''),
    createdAt:
        DateTime.tryParse(_text(data, 'createdAt', '')) ?? DateTime.now(),
  );
}
