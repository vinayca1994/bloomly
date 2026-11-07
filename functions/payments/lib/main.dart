import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as models;

import 'razorpay_api.dart';
import 'rules.dart';

const _database = 'bloomly';
const _store = 'store';
const _storeRow = 'main';
const _products = 'products';
const _variants = 'variants';
const _orders = 'orders';
const _orderItems = 'order_items';
const _locations = 'rider_locations';
const _reviews = 'reviews';
const _profiles = 'profiles';
const _addresses = 'addresses';
const _events = 'payment_events';

const _genericError = 'Could not update the order.';

/// Orders, Razorpay capture, delivery, reviews, and account deletion.
///
/// The API key writes money and status. A customer session cannot.
/// Razorpay calls this function without a session. That request is accepted
/// only when its signature matches the webhook secret.
String _header(dynamic context, String name) {
  try {
    final headers = context.req.headers;
    if (headers is Map) {
      for (final entry in headers.entries) {
        if (entry.key.toString().toLowerCase() == name) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) return value.first.toString();
          return value?.toString() ?? '';
        }
      }
    }
  } catch (_) {
    return '';
  }
  return '';
}

String _firstNonEmpty(String header, String envKey) {
  if (header.isNotEmpty) return header;
  return Platform.environment[envKey] ?? '';
}

Future<dynamic> main(dynamic context) async {
  final raw = _rawBody(context);
  final action = _actionOf(raw);
  try {
    final trigger = _firstNonEmpty(
      _header(context, 'x-appwrite-trigger'),
      'APPWRITE_FUNCTION_TRIGGER',
    );
    if (trigger == 'schedule' || trigger == 'interval') {
      final result = await _expire();
      return context.res.json(result);
    }
    final signature = _header(context, 'x-razorpay-signature');
    if (signature.isNotEmpty || isRazorpayEventBody(raw)) {
      final result = await _webhook(raw, signature);
      return context.res.json(result, result['error'] == null ? 200 : 400);
    }
    final result = await handle(
      body: raw,
      userId: _firstNonEmpty(
        _header(context, 'x-appwrite-user-id'),
        'APPWRITE_FUNCTION_USER_ID',
      ),
      now: DateTime.now().toUtc(),
    );
    return context.res.json(result, result['error'] == null ? 200 : 400);
  } on AppwriteException catch (error) {
    context.log('$action ${error.code} ${error.type} ${error.message}');
    final missing = error.code == 404;
    return context.res.json(
      {'error': missing ? 'Order not found.' : _genericError},
      missing ? 400 : 500,
    );
  } catch (error) {
    context.log('$action $error');
    return context.res.json({'error': _genericError}, 500);
  }
}

String _rawBody(dynamic context) {
  try {
    final raw = context.req.bodyRaw;
    if (raw is String) return raw;
  } catch (_) {}
  try {
    final text = context.req.bodyText;
    if (text is String) return text;
  } catch (_) {}
  final body = context.req.body;
  if (body is String) return body;
  return '';
}

String _actionOf(String body) {
  try {
    final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    if (decoded is Map) return decoded['action']?.toString() ?? 'create';
  } on FormatException {
    return 'create';
  }
  return 'create';
}

Future<Map<String, dynamic>> handle({
  required String body,
  required String userId,
  DateTime? now,
}) async {
  final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
  if (decoded is! Map) return {'error': 'Expected a JSON body.'};
  final payload = Map<String, dynamic>.from(decoded);
  final action = payload['action']?.toString() ?? 'create';
  final clock = now ?? DateTime.now().toUtc();
  switch (action) {
    case 'deleteAccount':
      return _deleteAccount(payload, userId, clock);
    case 'note':
    case 'confirm':
      return {'error': confirmClosed};
    case 'cancel':
      return _cancel(payload, userId);
    case 'advance':
      return _advance(payload, userId);
    case 'assignRider':
      return _assignRider(payload, userId);
    case 'updateLocation':
      return _updateLocation(payload, userId);
    case 'markDelivered':
      return _markDelivered(payload, userId);
    case 'submitReview':
      return _submitReview(payload, userId);
    case 'createRider':
      return _createRider(payload, userId);
    case 'listRiders':
      return _listRiders(userId);
    case 'ensureProfile':
      return _ensureProfile(userId);
    case 'updateName':
      return _updateName(payload, userId);
    case 'expire':
      if (userId.isEmpty) return {'error': 'Sign in before paying.'};
      return _expire(clock);
    case 'verify':
      return _verify(payload, userId);
    case 'checkout':
      return _checkout(payload, userId);
    case 'markRefunded':
      return _markRefunded(payload, userId);
    case 'create':
      return _create(payload, userId);
    default:
      return {'error': _genericError};
  }
}

Future<Map<String, dynamic>> _deleteAccount(
  Map<String, dynamic> payload,
  String userId,
  DateTime now,
) async {
  if (userId.isEmpty) return {'error': 'Sign in first.'};
  final users = Users(_client());
  final user = await users.get(userId: userId);
  if (user.labels.contains('owner')) {
    return {'error': 'The store owner account cannot be deleted here.'};
  }
  if (user.labels.contains('rider')) {
    return {'error': 'A rider account stays signed in here.'};
  }
  if (user.email.isNotEmpty) {
    final password = '${payload['password'] ?? ''}';
    if (!await _passwordMatches(email: user.email, password: password, userId: userId)) {
      return {'error': 'Enter your password to delete the account.'};
    }
  } else {
    final sessions = await users.listSessions(userId: userId);
    final fresh = sessions.sessions.any((session) => sessionIsFresh(session.$createdAt, now));
    if (!fresh) return {'error': 'Enter a fresh login code, then delete the account.'};
  }

  final tables = _tables();
  var paidUpi = false;
  await _eachPage(tables, _orders, [Query.equal('userId', userId)], (row) async {
    if (blocksAccountDelete(
      paymentMethod: '${row.data['paymentMethod'] ?? ''}',
      paymentStatus: '${row.data['paymentStatus'] ?? ''}',
    )) {
      paidUpi = true;
    }
  });
  if (paidUpi) return {'error': accountHasPaidOrders};
  final orderIds = <String>[];
  await _eachPage(tables, _orders, [Query.equal('userId', userId)], (row) async {
    orderIds.add(row.$id);
    await _eachPage(tables, _orderItems, [Query.equal('orderId', row.$id)], (item) async {
      await tables.deleteRow(databaseId: _database, tableId: _orderItems, rowId: item.$id);
    });
    await _eachPage(tables, _locations, [Query.equal('orderId', row.$id)], (pin) async {
      await tables.deleteRow(databaseId: _database, tableId: _locations, rowId: pin.$id);
    });
    await tables.deleteRow(databaseId: _database, tableId: _orders, rowId: row.$id);
  });
  await _eachPage(tables, _reviews, [Query.equal('userId', userId)], (row) async {
    await tables.deleteRow(databaseId: _database, tableId: _reviews, rowId: row.$id);
  });
  for (final orderId in orderIds) {
    await _eachPage(tables, _reviews, [Query.equal('orderId', orderId)], (row) async {
      await tables.deleteRow(databaseId: _database, tableId: _reviews, rowId: row.$id);
    });
  }
  await _eachPage(tables, _addresses, [Query.equal('userId', userId)], (row) async {
    await tables.deleteRow(databaseId: _database, tableId: _addresses, rowId: row.$id);
  });
  try {
    await tables.deleteRow(databaseId: _database, tableId: _profiles, rowId: userId);
  } on AppwriteException catch (error) {
    if (error.code != 404) rethrow;
  }
  await users.delete(userId: userId);
  return {'ok': true};
}

Future<void> _eachPage(
  TablesDB tables,
  String tableId,
  List<String> filters,
  Future<void> Function(models.Row row) onRow,
) async {
  while (true) {
    final page = await tables.listRows(
      databaseId: _database,
      tableId: tableId,
      queries: [...filters, Query.limit(deletePageSize)],
    );
    if (page.rows.isEmpty) return;
    for (final row in page.rows) {
      await onRow(row);
    }
    if (!morePages(page.rows.length)) return;
  }
}

Future<Map<String, dynamic>> _create(Map<String, dynamic> payload, String userId) async {
  if (userId.isEmpty) return {'error': 'Sign in before paying.'};
  final key = '${payload['idempotencyKey'] ?? ''}';
  if (!validIdempotencyKey(key)) return {'error': 'Could not start checkout.'};
  final method = '${payload['method'] ?? 'upi'}';
  if (method != 'cod' && method != 'upi') return {'error': 'Choose cash or UPI.'};
  final address = payload['address'];
  final lines = payload['lines'];
  if (address is! Map || lines is! List) return {'error': cartEmpty};
  final quantities = <int>[];
  for (final raw in lines) {
    if (raw is! Map) return {'error': cartQty};
    quantities.add(_int(raw['qty']));
  }
  final shape = cartShapeError(lineCount: lines.length, quantities: quantities);
  if (shape != null) return {'error': shape};

  final tables = _tables();
  final existing = await _maybeRow(tables, _orders, key);
  if (existing != null) {
    if (existing.data['userId']?.toString() != userId) {
      return {'error': 'Could not start checkout.'};
    }
    if (method == 'upi') return _sessionFor(tables, existing);
    return {
      'orderId': existing.$id,
      'amountRupees': _int(existing.data['total']),
      'currency': 'INR',
    };
  }

  final store = await tables.getRow(databaseId: _database, tableId: _store, rowId: _storeRow);
  final storeCity = '${store.data['city'] ?? ''}'.trim();
  final areaError = deliveryAreaError(
    city: '${address['city'] ?? ''}',
    pincode: '${address['pincode'] ?? ''}',
    storeCity: storeCity,
    storePincode: '${store.data['pincode'] ?? ''}',
  );
  if (areaError != null) return {'error': areaError};
  if (method == 'upi') {
    final keys = razorpayKeys(Platform.environment);
    if (!keys.ready) return {'error': onlinePayNotSetUp};
  }

  var subtotal = 0;
  final drafts = <Map<String, dynamic>>[];
  for (final raw in lines) {
    final line = Map<String, dynamic>.from(raw as Map);
    final qty = _int(line['qty']);
    final product = await tables.getRow(
      databaseId: _database,
      tableId: _products,
      rowId: '${line['productId']}',
    );
    final variant = await tables.getRow(
      databaseId: _database,
      tableId: _variants,
      rowId: '${line['variantId']}',
    );
    if (variant.data['productId']?.toString() != product.$id) {
      return {'error': 'An item in the cart is no longer available.'};
    }
    if (product.data['isAvailable'] != true || variant.data['isAvailable'] != true) {
      return {'error': '${product.data['name'] ?? 'An item'} is sold out.'};
    }
    final unit = _int(variant.data['price']);
    subtotal += unit * qty;
    drafts.add({
      'productId': product.$id,
      'name': '${product.data['name'] ?? ''}',
      'variantLabel': '${variant.data['label'] ?? ''}',
      'unitPrice': unit,
      'qty': qty,
    });
  }
  var customerPhone = '';
  try {
    final buyer = await Users(_client()).get(userId: userId);
    customerPhone = buyer.phone;
  } on AppwriteException {
    customerPhone = '';
  }
  final fee = pricedDeliveryFee(
    subtotal: subtotal,
    fee: _int(store.data['deliveryFee']),
    freeAbove: _int(store.data['freeDeliveryAbove']),
  );
  final total = subtotal + fee;
  final permissions = _orderRead(userId);
  final created = await tables.createRow(
    databaseId: _database,
    tableId: _orders,
    rowId: key,
    data: {
      'userId': userId,
      'addressSnapshot': _snapshot(address),
      'status': method == 'upi' ? 'payment_pending' : 'placed',
      'subtotal': subtotal,
      'deliveryFee': fee,
      'total': total,
      'paymentMethod': method,
      'paymentStatus': 'pending',
      'gatewayOrderId': '',
      'gatewayPaymentId': '',
      'upiTxnRef': '',
      'riderId': '',
      'riderName': '',
      'customerPhone': customerPhone,
      'destLatitude': '${address['latitude'] ?? ''}',
      'destLongitude': '${address['longitude'] ?? ''}',
      'placedAt': DateTime.now().toUtc().toIso8601String(),
    },
    permissions: permissions,
  );
  try {
    for (final draft in drafts) {
      await tables.createRow(
        databaseId: _database,
        tableId: _orderItems,
        rowId: ID.unique(),
        data: {...draft, 'orderId': created.$id},
        permissions: permissions,
      );
    }
  } catch (_) {
    await _deleteOrderTree(tables, created.$id);
    return {'error': _genericError};
  }
  if (method == 'upi') {
    final session = await _attachRazorpay(tables, created.$id, total);
    if (session['error'] != null) {
      await _deleteOrderTree(tables, created.$id);
      return session;
    }
    await _event(
      orderId: created.$id,
      actorId: userId,
      action: 'created',
      amount: total,
      reference: '${session['razorpayOrderId'] ?? ''}',
    );
    return session;
  }
  await _event(
    orderId: created.$id,
    actorId: userId,
    action: 'created',
    amount: total,
    reference: '',
  );
  return {'orderId': created.$id, 'amountRupees': total, 'currency': 'INR'};
}

Future<Map<String, dynamic>> _checkout(
  Map<String, dynamic> payload,
  String userId,
) async {
  if (userId.isEmpty) return {'error': 'Sign in before paying.'};
  final orderId = '${payload['orderId'] ?? ''}';
  if (!validIdempotencyKey(orderId)) return {'error': 'Order not found.'};
  final tables = _tables();
  final order = await tables.getRow(
    databaseId: _database,
    tableId: _orders,
    rowId: orderId,
  );
  if (order.data['userId']?.toString() != userId) {
    return {'error': 'This order belongs to someone else.'};
  }
  return _sessionFor(tables, order);
}

Future<Map<String, dynamic>> _sessionFor(TablesDB tables, models.Row order) async {
  final status = '${order.data['status'] ?? ''}';
  final paymentStatus = '${order.data['paymentStatus'] ?? ''}';
  final total = _int(order.data['total']);
  if (paymentStatus == 'paid' && status != 'payment_pending') {
    return {'orderId': order.$id, 'alreadyPaid': true, 'amountRupees': total};
  }
  if (status != 'payment_pending' || order.data['paymentMethod']?.toString() != 'upi') {
    return {'error': confirmNotWaiting};
  }
  return _attachRazorpay(
    tables,
    order.$id,
    total,
    existingGateway: '${order.data['gatewayOrderId'] ?? ''}',
  );
}

Future<Map<String, dynamic>> _attachRazorpay(
  TablesDB tables,
  String orderId,
  int total, {
  String existingGateway = '',
}) async {
  final keys = razorpayKeys(Platform.environment);
  if (!keys.ready) return {'error': onlinePayNotSetUp};
  if (total < 1) return {'error': 'The bill must be at least ₹1.'};
  final held = await _claimGateway(
    tables,
    orderId,
    existingGateway.trim(),
    amountRupees: total,
  );
  if (held.error != null) return {'error': held.error};
  return {
    'orderId': orderId,
    'keyId': keys.keyId,
    'razorpayOrderId': held.id,
    'amountRupees': total,
    'currency': 'INR',
  };
}

/// One caller owns the empty gateway slot. A second caller reuses that id.
Future<({String? id, String? error})> _claimGateway(
  TablesDB tables,
  String orderId,
  String existing, {
  required int amountRupees,
  int depth = 0,
}) async {
  if (depth > 3) return (id: null, error: paymentStarting);
  final now = DateTime.now().toUtc();
  final slot = classifyGateway(existing, now);
  if (slot == GatewaySlot.ready) return (id: existing, error: null);
  if (slot == GatewaySlot.freshClaim || slot == GatewaySlot.unknown) {
    return (id: null, error: paymentStarting);
  }
  final from = slot == GatewaySlot.empty ? '' : existing;
  final claim = gatewayClaimAt(now);
  final won = await _swapGateway(tables, orderId, from, claim);
  if (!won) {
    final again = await tables.getRow(
      databaseId: _database,
      tableId: _orders,
      rowId: orderId,
    );
    final current = '${again.data['gatewayOrderId'] ?? ''}'.trim();
    if (current == existing) return (id: null, error: paymentStarting);
    return _claimGateway(
      tables,
      orderId,
      current,
      amountRupees: amountRupees,
      depth: depth + 1,
    );
  }
  final createdId = await _createRazorpayOrder(
    amountRupees: amountRupees,
    orderId: orderId,
  );
  if (createdId == null) {
    await _swapGateway(tables, orderId, claim, '');
    return (id: null, error: 'Could not start the payment.');
  }
  final wrote = await _swapGateway(tables, orderId, claim, createdId);
  if (wrote) return (id: createdId, error: null);
  final again = await tables.getRow(
    databaseId: _database,
    tableId: _orders,
    rowId: orderId,
  );
  final current = '${again.data['gatewayOrderId'] ?? ''}'.trim();
  if (isRazorpayOrderId(current)) return (id: current, error: null);
  return (id: null, error: paymentStarting);
}

Future<bool> _swapGateway(
  TablesDB tables,
  String orderId,
  String from,
  String to,
) async {
  try {
    final page = await tables.updateRows(
      databaseId: _database,
      tableId: _orders,
      data: {'gatewayOrderId': to},
      queries: [
        Query.equal(r'$id', orderId),
        Query.equal('gatewayOrderId', from),
      ],
    );
    return page.rows.isNotEmpty;
  } on AppwriteException {
    return false;
  }
}

Future<String?> _createRazorpayOrder({
  required int amountRupees,
  required String orderId,
}) async {
  final keys = razorpayKeys(Platform.environment);
  final api = RazorpayApi(keyId: keys.keyId, keySecret: keys.keySecret);
  try {
    return await api.createOrder(
      amountPaise: amountRupees * 100,
      receipt: orderId,
      bloomOrderId: orderId,
    );
  } on RazorpayException {
    return null;
  } finally {
    api.close();
  }
}

Future<Map<String, dynamic>> _verify(
  Map<String, dynamic> payload,
  String userId,
) async {
  if (userId.isEmpty) return {'error': 'Sign in before paying.'};
  final orderId = '${payload['orderId'] ?? ''}';
  final razorpayOrderId = '${payload['razorpayOrderId'] ?? ''}'.trim();
  final paymentId = '${payload['razorpayPaymentId'] ?? ''}'.trim();
  final signature = '${payload['signature'] ?? ''}';
  final keys = razorpayKeys(Platform.environment);
  if (!keys.ready) return {'error': onlinePayNotSetUp};
  final signatureError = checkoutSignatureError(
    secret: keys.keySecret,
    orderId: razorpayOrderId,
    paymentId: paymentId,
    signature: signature,
  );
  if (signatureError != null) return {'error': signatureError};
  final tables = _tables();
  final order = await tables.getRow(
    databaseId: _database,
    tableId: _orders,
    rowId: orderId,
  );
  if (order.data['userId']?.toString() != userId) {
    return {'error': 'This order belongs to someone else.'};
  }
  if ('${order.data['gatewayOrderId'] ?? ''}' != razorpayOrderId) {
    return {'error': paymentOrderMismatch};
  }
  final payment = await _fetchRazorpayPayment(paymentId);
  if (payment == null) return {'error': paymentNotConfirmed};
  return _applyCapture(order: order, payment: payment, actorId: userId);
}

Future<Map<String, dynamic>> _webhook(String raw, String signature) async {
  final keys = razorpayKeys(Platform.environment);
  if (keys.webhookSecret.isEmpty) return {'error': 'Webhook is not set up.'};
  if (!razorpayWebhookMatches(
    secret: keys.webhookSecret,
    rawBody: raw,
    signature: signature,
  )) {
    return {'error': paymentNotChecked};
  }
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return {'error': paymentNotChecked};
  }
  final event = razorpayEventName(decoded);
  if (event == null) return {'error': paymentNotChecked};
  if (event == 'refund.processed') return _applyRefundNotice(decoded);
  if (event != 'payment.captured') return {'ok': true, 'ignored': true};
  final notice = capturedPaymentNotice(decoded);
  if (notice == null || !isRazorpayPaymentId(notice.paymentId)) {
    return {'error': paymentNotChecked};
  }
  final payment = await _fetchRazorpayPayment(notice.paymentId);
  if (payment == null) return {'error': paymentNotConfirmed};
  final order = await _orderForPayment(payment, notice.bloomOrderId);
  if (order == null) return {'ok': true, 'ignored': true};
  return _applyCapture(order: order, payment: payment, actorId: 'razorpay');
}

Future<Map<String, dynamic>?> _fetchRazorpayPayment(String paymentId) async {
  final keys = razorpayKeys(Platform.environment);
  if (!keys.ready || !isRazorpayPaymentId(paymentId)) return null;
  final api = RazorpayApi(keyId: keys.keyId, keySecret: keys.keySecret);
  try {
    return await api.fetchPayment(paymentId);
  } on RazorpayException {
    return null;
  } finally {
    api.close();
  }
}

Future<models.Row?> _orderForPayment(
  Map<String, dynamic> payment,
  String noticeOrderId,
) async {
  final notes = payment['notes'];
  final fromNotes = notes is Map ? '${notes['bloomOrderId'] ?? ''}'.trim() : '';
  final bloomOrderId = validIdempotencyKey(fromNotes)
      ? fromNotes
      : (validIdempotencyKey(noticeOrderId) ? noticeOrderId : '');
  final tables = _tables();
  if (bloomOrderId.isNotEmpty) {
    return _maybeRow(tables, _orders, bloomOrderId);
  }
  final razorpayOrderId = '${payment['order_id'] ?? ''}'.trim();
  if (!isRazorpayOrderId(razorpayOrderId)) return null;
  try {
    final page = await tables.listRows(
      databaseId: _database,
      tableId: _orders,
      queries: [Query.equal('gatewayOrderId', razorpayOrderId), Query.limit(1)],
    );
    if (page.rows.isEmpty) return null;
    return page.rows.first;
  } on AppwriteException {
    return null;
  }
}

Future<Map<String, dynamic>> _applyCapture({
  required models.Row order,
  required Map<String, dynamic> payment,
  required String actorId,
}) async {
  final notes = payment['notes'];
  final bloomOrderId = notes is Map ? '${notes['bloomOrderId'] ?? ''}'.trim() : '';
  if (bloomOrderId.isNotEmpty && bloomOrderId != order.$id) {
    return {'error': paymentOrderMismatch};
  }
  final paymentId = '${payment['id'] ?? ''}'.trim();
  if (!isRazorpayPaymentId(paymentId)) return {'error': paymentNotChecked};
  final accept = captureAcceptError(
    status: '${payment['status'] ?? ''}'.trim(),
    amountPaise: readPaise(payment['amount']),
    expectedRupees: _int(order.data['total']),
    razorpayOrderId: '${payment['order_id'] ?? ''}'.trim(),
    expectedOrderId: '${order.data['gatewayOrderId'] ?? ''}'.trim(),
  );
  if (accept != null) return {'error': accept};
  final decision = captureDecision(
    orderStatus: '${order.data['status'] ?? ''}',
    paymentStatus: '${order.data['paymentStatus'] ?? ''}',
  );
  final tables = _tables();
  if (decision == CaptureDecision.alreadyPaid) {
    return {'ok': true, 'orderId': order.$id, 'alreadyPaid': true};
  }
  if (decision == CaptureDecision.lateAfterCancel) {
    final recorded = await _writeIfStatus(tables, order.$id, 'cancelled', {
      'gatewayPaymentId': paymentId,
      'paymentStatus': 'refund_pending',
    });
    if (recorded != null && '${order.data['paymentStatus'] ?? ''}' != 'refund_pending') {
      return {'error': recorded};
    }
    await _event(
      orderId: order.$id,
      actorId: actorId,
      action: 'captured_after_cancel',
      amount: _int(order.data['total']),
      reference: paymentId,
    );
    final refunded = await _sendRefund(
      tables: tables,
      orderId: order.$id,
      paymentId: paymentId,
      amountRupees: _int(order.data['total']),
      actorId: actorId,
    );
    return {'ok': true, 'orderId': order.$id, 'late': true, 'refunded': refunded};
  }
  if (decision != CaptureDecision.markPaid) {
    return {'ok': true, 'orderId': order.$id, 'ignored': true};
  }
  final changed = await _writeIfStatus(tables, order.$id, 'payment_pending', {
    'status': 'placed',
    'paymentStatus': 'paid',
    'gatewayPaymentId': paymentId,
  });
  if (changed != null) {
    final again = await tables.getRow(
      databaseId: _database,
      tableId: _orders,
      rowId: order.$id,
    );
    if (again.data['paymentStatus']?.toString() == 'paid') {
      return {'ok': true, 'orderId': order.$id, 'alreadyPaid': true};
    }
    return {'error': changed};
  }
  await _event(
    orderId: order.$id,
    actorId: actorId,
    action: 'captured',
    amount: _int(order.data['total']),
    reference: paymentId,
  );
  return {'ok': true, 'orderId': order.$id};
}

Future<Map<String, dynamic>> _cancel(Map<String, dynamic> payload, String userId) async {
  final orderId = '${payload['orderId'] ?? ''}';
  final tables = _tables();
  final order = await tables.getRow(databaseId: _database, tableId: _orders, rowId: orderId);
  final owner = await _isOwner(userId);
  final customer = order.data['userId']?.toString() == userId;
  if (!owner && !customer) return {'error': 'This order belongs to someone else.'};
  final status = '${order.data['status'] ?? ''}';
  final error = cancelError(actor: owner ? 'owner' : 'customer', status: status);
  if (error != null) return {'error': error};
  final nextPayment = paymentStatusAfterCancel(
    status: status,
    paymentMethod: '${order.data['paymentMethod'] ?? ''}',
    paymentStatus: '${order.data['paymentStatus'] ?? ''}',
  );
  final changed = await _writeIfStatus(tables, orderId, status, {
    'status': 'cancelled',
    'paymentStatus': nextPayment,
  });
  if (changed != null) return {'error': changed};
  await _event(
    orderId: orderId,
    actorId: userId,
    action: 'cancelled',
    amount: _int(order.data['total']),
    reference: nextPayment,
  );
  if (nextPayment == 'refund_pending') {
    final paymentId = '${order.data['gatewayPaymentId'] ?? ''}'.trim();
    await _sendRefund(
      tables: tables,
      orderId: orderId,
      paymentId: paymentId,
      amountRupees: _int(order.data['total']),
      actorId: userId,
    );
  }
  return {'ok': true, 'orderId': orderId};
}

Future<Map<String, dynamic>> _advance(Map<String, dynamic> payload, String userId) async {
  if (!await _isOwner(userId)) return {'error': 'Only the store can update an order.'};
  final orderId = '${payload['orderId'] ?? ''}';
  final to = '${payload['status'] ?? ''}';
  final tables = _tables();
  final order = await tables.getRow(databaseId: _database, tableId: _orders, rowId: orderId);
  final from = '${order.data['status'] ?? ''}';
  final error = advanceError(from: from, to: to);
  if (error != null) return {'error': error};
  final data = <String, dynamic>{'status': to};
  final collected = paymentStatusOnDeliver(
    paymentMethod: '${order.data['paymentMethod'] ?? ''}',
    paymentStatus: '${order.data['paymentStatus'] ?? ''}',
  );
  if (to == 'delivered' && collected != null) data['paymentStatus'] = collected;
  final changed = await _writeIfStatus(tables, orderId, from, data);
  if (changed != null) return {'error': changed};
  await _event(
    orderId: orderId,
    actorId: userId,
    action: to,
    amount: _int(order.data['total']),
    reference: '',
  );
  return {'ok': true, 'orderId': orderId};
}

Future<Map<String, dynamic>> _assignRider(Map<String, dynamic> payload, String userId) async {
  if (!await _isOwner(userId)) return {'error': 'Only the store can assign a rider.'};
  final orderId = '${payload['orderId'] ?? ''}';
  final riderId = '${payload['riderId'] ?? ''}';
  if (!validIdempotencyKey(riderId)) return {'error': 'Choose a rider.'};
  final tables = _tables();
  final users = Users(_client());
  final rider = await users.get(userId: riderId);
  if (!rider.labels.contains('rider')) return {'error': 'Choose a rider.'};
  final order = await tables.getRow(databaseId: _database, tableId: _orders, rowId: orderId);
  final status = '${order.data['status'] ?? ''}';
  final error = assignError(status);
  if (error != null) return {'error': error};
  final customerId = '${order.data['userId'] ?? ''}';
  final changed = await _writeIfStatus(
    tables,
    orderId,
    status,
    {
      'riderId': rider.$id,
      'riderName': rider.name,
      'status': 'out_for_delivery',
    },
    permissions: [
      ..._orderRead(customerId),
      Permission.read(Role.user(rider.$id)),
    ],
  );
  if (changed != null) return {'error': changed};
  await _grantRiderItems(
    tables: tables,
    orderId: orderId,
    customerId: customerId,
    riderId: rider.$id,
  );
  final locationPermissions = [
    Permission.read(Role.user(customerId)),
    Permission.read(Role.user(rider.$id)),
    Permission.read(Role.label('owner')),
  ];
  final pin = await _maybeRow(tables, _locations, orderId);
  if (pin == null) {
    await tables.createRow(
      databaseId: _database,
      tableId: _locations,
      rowId: orderId,
      data: {'orderId': orderId, 'latitude': '', 'longitude': '', 'updatedAt': ''},
      permissions: locationPermissions,
    );
  } else {
    await tables.updateRow(
      databaseId: _database,
      tableId: _locations,
      rowId: orderId,
      data: {'orderId': orderId},
      permissions: locationPermissions,
    );
  }
  await _event(
    orderId: orderId,
    actorId: userId,
    action: 'assigned',
    amount: _int(order.data['total']),
    reference: rider.$id,
  );
  return {'ok': true, 'orderId': orderId};
}

Future<void> _grantRiderItems({
  required TablesDB tables,
  required String orderId,
  required String customerId,
  required String riderId,
}) async {
  final page = await tables.listRows(
    databaseId: _database,
    tableId: _orderItems,
    queries: [Query.equal('orderId', orderId), Query.limit(100)],
  );
  final permissions = [
    Permission.read(Role.user(customerId)),
    Permission.read(Role.label('owner')),
    Permission.update(Role.label('owner')),
    Permission.read(Role.user(riderId)),
  ];
  for (final item in page.rows) {
    await tables.updateRow(
      databaseId: _database,
      tableId: _orderItems,
      rowId: item.$id,
      data: {'orderId': orderId},
      permissions: permissions,
    );
  }
}

Future<Map<String, dynamic>> _updateLocation(Map<String, dynamic> payload, String userId) async {
  if (!await _hasLabel(userId, 'rider')) return {'error': notYours};
  final orderId = '${payload['orderId'] ?? ''}';
  final latitude = _double(payload['latitude']);
  final longitude = _double(payload['longitude']);
  if (latitude == null ||
      longitude == null ||
      !validCoord(latitude, latitude: true) ||
      !validCoord(longitude, latitude: false)) {
    return {'error': 'Location is not available.'};
  }
  final tables = _tables();
  final order = await tables.getRow(databaseId: _database, tableId: _orders, rowId: orderId);
  if (order.data['riderId']?.toString() != userId ||
      order.data['status']?.toString() != 'out_for_delivery') {
    return {'error': notYours};
  }
  final data = {
    'orderId': orderId,
    'latitude': latitude.toString(),
    'longitude': longitude.toString(),
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };
  final permissions = [
    Permission.read(Role.user('${order.data['userId'] ?? ''}')),
    Permission.read(Role.user(userId)),
    Permission.read(Role.label('owner')),
  ];
  final pin = await _maybeRow(tables, _locations, orderId);
  if (pin == null) {
    await tables.createRow(
      databaseId: _database,
      tableId: _locations,
      rowId: orderId,
      data: data,
      permissions: permissions,
    );
  } else {
    await tables.updateRow(
      databaseId: _database,
      tableId: _locations,
      rowId: orderId,
      data: data,
      permissions: permissions,
    );
  }
  return {'ok': true, 'orderId': orderId};
}

Future<Map<String, dynamic>> _markDelivered(Map<String, dynamic> payload, String userId) async {
  final orderId = '${payload['orderId'] ?? ''}';
  final tables = _tables();
  final order = await tables.getRow(databaseId: _database, tableId: _orders, rowId: orderId);
  final owner = await _isOwner(userId);
  final rider = await _hasLabel(userId, 'rider');
  final error = deliverError(
    isOwner: owner,
    isRider: rider,
    riderMatches: order.data['riderId']?.toString() == userId,
    status: '${order.data['status'] ?? ''}',
  );
  if (error != null) return {'error': error};
  final data = <String, dynamic>{'status': 'delivered'};
  final collected = paymentStatusOnDeliver(
    paymentMethod: '${order.data['paymentMethod'] ?? ''}',
    paymentStatus: '${order.data['paymentStatus'] ?? ''}',
  );
  if (collected != null) data['paymentStatus'] = collected;
  final changed = await _writeIfStatus(tables, orderId, 'out_for_delivery', data);
  if (changed != null) return {'error': changed};
  await _event(
    orderId: orderId,
    actorId: userId,
    action: 'delivered',
    amount: _int(order.data['total']),
    reference: collected ?? '',
  );
  return {'ok': true, 'orderId': orderId};
}

Future<Map<String, dynamic>> _submitReview(Map<String, dynamic> payload, String userId) async {
  if (userId.isEmpty) return {'error': 'Sign in first.'};
  if (await _isOwner(userId) || await _hasLabel(userId, 'rider')) {
    return {'error': 'Only the customer can review this order.'};
  }
  final orderId = '${payload['orderId'] ?? ''}';
  final tables = _tables();
  final order = await tables.getRow(databaseId: _database, tableId: _orders, rowId: orderId);
  final existing = await _maybeRow(tables, _reviews, orderId);
  final gate = reviewCreateError(
    isCustomer: true,
    ownsOrder: order.data['userId']?.toString() == userId,
    status: '${order.data['status'] ?? ''}',
    alreadyReviewed: existing != null,
  );
  if (gate != null) return {'error': gate};
  final scores = ['freshness', 'rightItems', 'packing', 'onTime', 'polite', 'careful'];
  final data = <String, dynamic>{
    'orderId': orderId,
    'userId': userId,
    'riderId': '${order.data['riderId'] ?? ''}',
    'note': '${payload['note'] ?? ''}'.trim(),
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };
  for (final key in scores) {
    final score = _int(payload[key]);
    if (score < 1 || score > 5) return {'error': 'Choose 1 to 5 stars for each part.'};
    data[key] = score;
  }
  if ('${data['note']}'.length > 280) return {'error': 'Keep the note under 280 characters.'};
  final riderId = '${order.data['riderId'] ?? ''}';
  try {
    await tables.createRow(
      databaseId: _database,
      tableId: _reviews,
      rowId: orderId,
      data: data,
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.read(Role.label('owner')),
        if (riderId.isNotEmpty) Permission.read(Role.user(riderId)),
      ],
    );
  } on AppwriteException catch (error) {
    if (error.code == 409) return {'error': 'This order already has a review.'};
    rethrow;
  }
  return {'ok': true, 'orderId': orderId};
}

Future<Map<String, dynamic>> _createRider(Map<String, dynamic> payload, String userId) async {
  if (!await _isOwner(userId)) return {'error': 'Only the store can add a rider.'};
  final name = '${payload['name'] ?? ''}'.trim();
  final email = '${payload['email'] ?? ''}'.trim().toLowerCase();
  if (name.isEmpty) return {'error': 'Enter the rider’s name.'};
  if (!email.contains('@') || email.length < 5) return {'error': 'Enter the rider’s email.'};
  final users = Users(_client());
  try {
    final created = await users.create(
      userId: ID.unique(),
      email: email,
      password: _randomPassword(),
      name: name,
    );
    await users.updateLabels(userId: created.$id, labels: ['rider']);
    try {
      await _tables().createRow(
        databaseId: _database,
        tableId: _profiles,
        rowId: created.$id,
        data: {
          'userId': created.$id,
          'name': name,
          'role': 'rider',
          'phone': '',
          'email': email,
        },
        permissions: [
          Permission.read(Role.user(created.$id)),
          Permission.read(Role.label('owner')),
        ],
      );
    } on AppwriteException {
      await users.delete(userId: created.$id);
      rethrow;
    }
    final mailed = await _sendRecoveryCode(email);
    return {'ok': true, 'userId': created.$id, 'recovery': mailed};
  } on AppwriteException catch (error) {
    return {'error': error.message ?? 'Could not add the rider.'};
  }
}

Future<Map<String, dynamic>> _listRiders(String userId) async {
  if (!await _isOwner(userId)) return {'error': 'Only the store can see riders.'};
  final list = await Users(_client()).list(
    queries: [Query.contains('labels', 'rider'), Query.limit(100)],
  );
  return {
    'ok': true,
    'riders': [
      for (final rider in list.users)
        {'id': rider.$id, 'name': rider.name, 'email': rider.email},
    ],
  };
}

Future<Map<String, dynamic>> _ensureProfile(String userId) async {
  if (userId.isEmpty) return {'error': 'Sign in first.'};
  final users = Users(_client());
  final user = await users.get(userId: userId);
  if (user.labels.contains('owner') || user.labels.contains('rider')) return {'ok': true};
  final tables = _tables();
  final existing = await _maybeRow(tables, _profiles, userId);
  if (existing != null) return {'ok': true};
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
  return {'ok': true};
}

Future<Map<String, dynamic>> _updateName(Map<String, dynamic> payload, String userId) async {
  final name = '${payload['name'] ?? ''}'.trim();
  if (userId.isEmpty) return {'error': 'Sign in first.'};
  if (name.isEmpty) return {'error': 'Add your name.'};
  await _ensureProfile(userId);
  final existing = await _maybeRow(_tables(), _profiles, userId);
  if (existing == null) return {'ok': true};
  await _tables().updateRow(
    databaseId: _database,
    tableId: _profiles,
    rowId: userId,
    data: {'name': name},
  );
  return {'ok': true};
}

Future<Map<String, dynamic>> _expire([DateTime? now]) async {
  final clock = now ?? DateTime.now().toUtc();
  final tables = _tables();
  var cancelled = 0;
  while (true) {
    final page = await tables.listRows(
      databaseId: _database,
      tableId: _orders,
      queries: [
        Query.equal('status', 'payment_pending'),
        Query.orderAsc('placedAt'),
        Query.limit(25),
      ],
    );
    if (page.rows.isEmpty) break;
    var changed = 0;
    for (final row in page.rows) {
      final placed = DateTime.tryParse('${row.data['placedAt'] ?? ''}')?.toUtc();
      if (placed == null) continue;
      if (!upiIsStale(
        status: 'payment_pending',
        method: '${row.data['paymentMethod'] ?? ''}',
        placedAt: placed,
        now: clock,
      )) {
        continue;
      }
      final error = await _writeIfStatus(tables, row.$id, 'payment_pending', {
        'status': 'cancelled',
        'paymentStatus': 'failed',
      });
      if (error != null) continue;
      changed += 1;
      cancelled += 1;
      await _event(
        orderId: row.$id,
        actorId: 'schedule',
        action: 'expired',
        amount: _int(row.data['total']),
        reference: '',
      );
    }
    if (changed == 0) break;
  }
  return {'ok': true, 'cancelled': cancelled};
}

Future<Map<String, dynamic>> _markRefunded(Map<String, dynamic> payload, String userId) async {
  if (!await _isOwner(userId)) return {'error': 'Only the store can mark a refund.'};
  final orderId = '${payload['orderId'] ?? ''}';
  final tables = _tables();
  final order = await tables.getRow(databaseId: _database, tableId: _orders, rowId: orderId);
  if (order.data['paymentStatus']?.toString() != 'refund_pending') {
    return {'error': 'This order is not waiting for a refund.'};
  }
  final sent = await _sendRefund(
    tables: tables,
    orderId: orderId,
    paymentId: '${order.data['gatewayPaymentId'] ?? ''}'.trim(),
    amountRupees: _int(order.data['total']),
    actorId: userId,
  );
  if (!sent) return {'error': refundFailed};
  final again = await tables.getRow(databaseId: _database, tableId: _orders, rowId: orderId);
  if (again.data['paymentStatus']?.toString() != 'refunded') {
    return {'error': 'Razorpay is still sending the refund.'};
  }
  return {'ok': true, 'orderId': orderId};
}

Future<Map<String, dynamic>> _applyRefundNotice(Object? decoded) async {
  final notice = refundProcessedNotice(decoded);
  if (notice == null || notice.status != 'processed') {
    return {'ok': true, 'ignored': true};
  }
  if (!isRazorpayPaymentId(notice.paymentId)) return {'error': paymentNotChecked};
  final tables = _tables();
  models.Row? order;
  if (validIdempotencyKey(notice.bloomOrderId)) {
    order = await _maybeRow(tables, _orders, notice.bloomOrderId);
  }
  order ??= await _orderByPayment(tables, notice.paymentId);
  if (order == null) return {'ok': true, 'ignored': true};
  if ('${order.data['gatewayPaymentId'] ?? ''}'.trim() != notice.paymentId) {
    return {'ok': true, 'ignored': true};
  }
  final moved = await _setPaymentStatus(
    tables,
    order.$id,
    '${order.data['paymentStatus'] ?? ''}',
    'refunded',
    refundId: notice.refundId,
  );
  if (moved) {
    await _event(
      orderId: order.$id,
      actorId: 'razorpay',
      action: 'refunded',
      amount: _int(order.data['total']),
      reference: notice.refundId,
    );
  }
  return {'ok': true, 'orderId': order.$id};
}

Future<models.Row?> _orderByPayment(TablesDB tables, String paymentId) async {
  try {
    final page = await tables.listRows(
      databaseId: _database,
      tableId: _orders,
      queries: [Query.equal('gatewayPaymentId', paymentId), Query.limit(1)],
    );
    if (page.rows.isEmpty) return null;
    return page.rows.first;
  } on AppwriteException {
    return null;
  }
}

/// Asks Razorpay to return a captured payment. `true` when Razorpay accepted it.
Future<bool> _sendRefund({
  required TablesDB tables,
  required String orderId,
  required String paymentId,
  required int amountRupees,
  required String actorId,
}) async {
  if (!isRazorpayPaymentId(paymentId) || amountRupees < 1) return false;
  final keys = razorpayKeys(Platform.environment);
  if (!keys.ready) return false;
  final api = RazorpayApi(keyId: keys.keyId, keySecret: keys.keySecret);
  try {
    Map<String, dynamic> body;
    try {
      body = await api.refundPayment(
        paymentId: paymentId,
        amountPaise: amountRupees * 100,
        bloomOrderId: orderId,
      );
    } on RazorpayException {
      final payment = await api.fetchPayment(paymentId);
      if ('${payment['refund_status'] ?? ''}' != 'full') return false;
      body = {'status': 'processed', 'id': '${payment['id'] ?? ''}'};
    }
    final progress = refundProgress('${body['status'] ?? ''}');
    if (progress == null) return false;
    final refundId = '${body['id'] ?? ''}'.trim();
    if (progress == 'processed') {
      await _setPaymentStatus(
        tables,
        orderId,
        'refund_pending',
        'refunded',
        refundId: refundId,
      );
      await _event(
        orderId: orderId,
        actorId: actorId,
        action: 'refunded',
        amount: amountRupees,
        reference: refundId,
      );
    }
    return true;
  } on RazorpayException {
    return false;
  } finally {
    api.close();
  }
}

Future<bool> _setPaymentStatus(
  TablesDB tables,
  String orderId,
  String from,
  String to, {
  String refundId = '',
}) async {
  if (from == to) return true;
  final data = <String, dynamic>{'paymentStatus': to};
  if (refundId.isNotEmpty) {
    data['upiTxnRef'] = refundId.length > 40 ? refundId.substring(0, 40) : refundId;
  }
  try {
    final page = await tables.updateRows(
      databaseId: _database,
      tableId: _orders,
      data: data,
      queries: [
        Query.equal(r'$id', orderId),
        Query.equal('paymentStatus', from),
      ],
    );
    return page.rows.isNotEmpty;
  } on AppwriteException {
    return false;
  }
}

Future<String?> _writeIfStatus(
  TablesDB tables,
  String orderId,
  String expected,
  Map<String, dynamic> data, {
  List<String>? permissions,
}) async {
  final wanted = data['status']?.toString() ?? expected;
  try {
    final page = await tables.updateRows(
      databaseId: _database,
      tableId: _orders,
      data: data,
      queries: [
        Query.equal(r'$id', orderId),
        Query.equal('status', expected),
      ],
    );
    if (page.rows.isEmpty) return statusChanged;
  } on AppwriteException {
    return statusChanged;
  }
  if (permissions == null) return null;
  await tables.updateRow(
    databaseId: _database,
    tableId: _orders,
    rowId: orderId,
    data: {'status': wanted},
    permissions: permissions,
  );
  return null;
}

Future<void> _deleteOrderTree(TablesDB tables, String orderId) async {
  try {
    final items = await tables.listRows(
      databaseId: _database,
      tableId: _orderItems,
      queries: [Query.equal('orderId', orderId), Query.limit(deletePageSize)],
    );
    for (final item in items.rows) {
      await tables.deleteRow(databaseId: _database, tableId: _orderItems, rowId: item.$id);
    }
    await tables.deleteRow(databaseId: _database, tableId: _orders, rowId: orderId);
  } on AppwriteException {
    // The create already failed. Leaving a row is worse, but a second failure
    // should not hide the original checkout error.
  }
}

Future<void> _event({
  required String orderId,
  required String actorId,
  required String action,
  required int amount,
  required String reference,
}) async {
  try {
    await _tables().createRow(
      databaseId: _database,
      tableId: _events,
      rowId: ID.unique(),
      data: {
        'orderId': orderId,
        'actorId': actorId,
        'action': action,
        'amount': amount,
        'reference': reference.length > 64 ? reference.substring(0, 64) : reference,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
      permissions: const [],
    );
  } on AppwriteException {
    // The order write already succeeded. A missing audit table should not
    // fail checkout.
  }
}

Future<models.Row?> _maybeRow(TablesDB tables, String tableId, String rowId) async {
  try {
    return await tables.getRow(databaseId: _database, tableId: tableId, rowId: rowId);
  } on AppwriteException catch (error) {
    if (error.code == 404) return null;
    rethrow;
  }
}

Future<bool> _isOwner(String userId) => _hasLabel(userId, 'owner');

Future<bool> _hasLabel(String userId, String label) async {
  if (userId.isEmpty) return false;
  try {
    final user = await Users(_client()).get(userId: userId);
    return user.labels.any((item) => item == label);
  } on AppwriteException {
    return false;
  }
}

List<String> _orderRead(String userId) => [
  Permission.read(Role.user(userId)),
  Permission.read(Role.label('owner')),
  Permission.update(Role.label('owner')),
];

Future<bool> _passwordMatches({
  required String email,
  required String password,
  required String userId,
}) async {
  if (password.length < 8) return false;
  final endpoint = _env('APPWRITE_FUNCTION_API_ENDPOINT');
  final project = _env('APPWRITE_FUNCTION_PROJECT_ID');
  if (endpoint.isEmpty || project.isEmpty) return false;
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('$endpoint/account/sessions/email'));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set('X-Appwrite-Project', project);
    request.add(utf8.encode(jsonEncode({'email': email, 'password': password})));
    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) return false;
    final decoded = jsonDecode(body);
    if (decoded is Map && '${decoded[r'$id'] ?? ''}'.isNotEmpty) {
      try {
        await Users(_client()).deleteSession(userId: userId, sessionId: '${decoded[r'$id']}');
      } on AppwriteException {
        // The password matched. A leftover proof session is removed on delete.
      }
    }
    return true;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

Future<bool> _sendRecoveryCode(String email) async {
  final endpoint = _env('APPWRITE_FUNCTION_API_ENDPOINT');
  final project = _env('APPWRITE_FUNCTION_PROJECT_ID');
  if (endpoint.isEmpty || project.isEmpty) return false;
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('$endpoint/account/recovery/otp'));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set('X-Appwrite-Project', project);
    request.add(utf8.encode(jsonEncode({'email': email})));
    final response = await request.close().timeout(const Duration(seconds: 8));
    await response.drain<void>();
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

String _randomPassword() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  final random = Random.secure();
  return List.generate(24, (_) => alphabet[random.nextInt(alphabet.length)]).join();
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

TablesDB _tables() => TablesDB(_client());

String _snapshot(Map address) {
  final label = '${address['label'] ?? 'Home'}';
  final line = '${address['line'] ?? ''}';
  final area = '${address['area'] ?? ''}';
  final city = '${address['city'] ?? ''}';
  final pincode = '${address['pincode'] ?? ''}';
  final text = '$label · $line, $area, $city $pincode';
  return text.length <= 300 ? text : text.substring(0, 300);
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
