import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

const _database = 'bloomly';
const _store = 'store';
const _storeRow = 'main';
const _products = 'products';
const _variants = 'variants';
const _orders = 'orders';
const _orderItems = 'order_items';

final _upiId = RegExp(r'^[A-Za-z0-9.\-_]{2,256}@[A-Za-z][A-Za-z0-9.\-]{1,63}$');
final _reference = RegExp(r'^[A-Za-z0-9]{1,35}$');

/// Creates a UPI order, records the customer's reference, or lets the owner confirm it.
///
/// There is no bank webhook. BHIM UPI opens on the customer's phone, and the
/// store confirms the credit in their own UPI app.
Future<dynamic> main(dynamic context) async {
  try {
    final body = '${context.req.body ?? ''}';
    final result = await handle(
      body: body,
      userId: Platform.environment['APPWRITE_FUNCTION_USER_ID'] ?? '',
    );
    return context.res.json(result, result['error'] == null ? 200 : 400);
  } catch (error) {
    context.error('$error');
    return context.res.json({'error': '$error'}, 500);
  }
}

Future<Map<String, dynamic>> handle({
  required String body,
  required String userId,
}) async {
  final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
  if (decoded is! Map) return {'error': 'Expected a JSON body.'};
  final payload = Map<String, dynamic>.from(decoded);
  final action = payload['action']?.toString() ?? 'create';
  if (action == 'deleteAccount') return _deleteAccount(userId);
  if (action == 'note') return _note(payload, userId);
  if (action == 'confirm') return _confirm(payload, userId);
  return _create(payload, userId);
}

/// Free Appwrite plans allow two functions, so account deletion lives here.
Future<Map<String, dynamic>> _deleteAccount(String userId) async {
  if (userId.isEmpty) return {'error': 'Sign in first.'};
  final users = Users(_client());
  final user = await users.get(userId: userId);
  if (user.labels.contains('owner')) {
    return {'error': 'The store owner account cannot be deleted here.'};
  }
  final tables = _tables();
  final orders = await tables.listRows(
    databaseId: _database,
    tableId: _orders,
    queries: [Query.equal('userId', userId), Query.limit(100)],
  );
  for (final order in orders.rows) {
    final items = await tables.listRows(
      databaseId: _database,
      tableId: _orderItems,
      queries: [Query.equal('orderId', order.$id), Query.limit(100)],
    );
    for (final item in items.rows) {
      await tables.deleteRow(databaseId: _database, tableId: _orderItems, rowId: item.$id);
    }
    await tables.deleteRow(databaseId: _database, tableId: _orders, rowId: order.$id);
  }
  final addresses = await tables.listRows(
    databaseId: _database,
    tableId: 'addresses',
    queries: [Query.equal('userId', userId), Query.limit(100)],
  );
  for (final address in addresses.rows) {
    await tables.deleteRow(databaseId: _database, tableId: 'addresses', rowId: address.$id);
  }
  try {
    await tables.deleteRow(databaseId: _database, tableId: 'profiles', rowId: userId);
  } on AppwriteException {
    // Phone accounts may not have a profile row.
  }
  await users.delete(userId: userId);
  return {'ok': true};
}

Future<Map<String, dynamic>> _create(Map<String, dynamic> payload, String userId) async {
  if (userId.isEmpty) return {'error': 'Sign in before paying.'};
  final address = payload['address'];
  final lines = payload['lines'];
  if (address is! Map || lines is! List || lines.isEmpty) {
    return {'error': 'Add an address and at least one item.'};
  }
  final tables = _tables();
  final store = await tables.getRow(
    databaseId: _database,
    tableId: _store,
    rowId: _storeRow,
  );
  final storeCity = '${store.data['city'] ?? ''}'.trim().toLowerCase();
  final city = '${address['city'] ?? ''}'.trim();
  if (city.toLowerCase() != storeCity) {
    return {'error': 'Bloomly delivers in ${store.data['city']} only.'};
  }
  final upiId = _firstUpi(store.data['upiId'], Platform.environment['BLOOMLY_UPI_ID']);
  if (upiId.isEmpty) return {'error': 'Add the store UPI ID before taking UPI payments.'};
  final upiName = _firstName(store.data['upiName'], Platform.environment['BLOOMLY_UPI_NAME']);
  var subtotal = 0;
  final drafts = <Map<String, dynamic>>[];
  for (final raw in lines) {
    if (raw is! Map) return {'error': 'Check the cart.'};
    final line = Map<String, dynamic>.from(raw);
    final qty = _int(line['qty']);
    if (qty < 1) return {'error': 'Check the quantities in your cart.'};
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
  final feeAmount = _int(store.data['deliveryFee']);
  final freeAbove = _int(store.data['freeDeliveryAbove']);
  final fee = subtotal <= 0 || subtotal >= freeAbove ? 0 : feeAmount;
  final total = subtotal + fee;
  final permissions = [
    Permission.read(Role.user(userId)),
    Permission.update(Role.user(userId)),
    Permission.read(Role.label('owner')),
    Permission.update(Role.label('owner')),
  ];
  final created = await tables.createRow(
    databaseId: _database,
    tableId: _orders,
    rowId: ID.unique(),
    data: {
      'userId': userId,
      'addressSnapshot': _snapshot(address),
      'status': 'payment_pending',
      'subtotal': subtotal,
      'deliveryFee': fee,
      'total': total,
      'paymentMethod': 'upi',
      'paymentStatus': 'pending',
      'gatewayOrderId': upiId,
      'gatewayPaymentId': '',
      'placedAt': DateTime.now().toUtc().toIso8601String(),
    },
    permissions: permissions,
  );
  for (final draft in drafts) {
    await tables.createRow(
      databaseId: _database,
      tableId: _orderItems,
      rowId: ID.unique(),
      data: {...draft, 'orderId': created.$id},
      permissions: permissions,
    );
  }
  return {
    'orderId': created.$id,
    'upiId': upiId,
    'upiName': upiName,
    'amountRupees': total,
    'currency': 'INR',
  };
}

Future<Map<String, dynamic>> _note(Map<String, dynamic> payload, String userId) async {
  if (userId.isEmpty) return {'error': 'Sign in before paying.'};
  final orderId = '${payload['orderId'] ?? ''}';
  final reference = '${payload['reference'] ?? ''}'.trim();
  if (reference.isNotEmpty && !_reference.hasMatch(reference)) {
    return {'error': 'Enter the UPI reference as letters and numbers only.'};
  }
  final tables = _tables();
  final order = await tables.getRow(
    databaseId: _database,
    tableId: _orders,
    rowId: orderId,
  );
  if (order.data['userId']?.toString() != userId) {
    return {'error': 'This order belongs to someone else.'};
  }
  if (order.data['paymentMethod']?.toString() != 'upi' || order.data['status']?.toString() != 'payment_pending') {
    return {'error': 'This order is not awaiting a UPI payment.'};
  }
  await tables.updateRow(
    databaseId: _database,
    tableId: _orders,
    rowId: orderId,
    data: {
      'paymentStatus': 'submitted',
      'gatewayPaymentId': reference,
    },
  );
  return {'ok': true, 'orderId': orderId};
}

Future<Map<String, dynamic>> _confirm(Map<String, dynamic> payload, String userId) async {
  if (!await _isOwner(userId)) return {'error': 'Only the store can confirm a UPI payment.'};
  final orderId = '${payload['orderId'] ?? ''}';
  final tables = _tables();
  final order = await tables.getRow(
    databaseId: _database,
    tableId: _orders,
    rowId: orderId,
  );
  if (order.data['paymentMethod']?.toString() != 'upi') {
    return {'error': 'This order was not paid by UPI.'};
  }
  if (order.data['status']?.toString() == 'placed' && order.data['paymentStatus']?.toString() == 'paid') {
    return {'ok': true, 'orderId': orderId};
  }
  if (order.data['status']?.toString() != 'payment_pending') {
    return {'error': 'This order is not awaiting a UPI payment.'};
  }
  await tables.updateRow(
    databaseId: _database,
    tableId: _orders,
    rowId: orderId,
    data: {
      'status': 'placed',
      'paymentStatus': 'paid',
    },
  );
  return {'ok': true, 'orderId': orderId};
}

Future<bool> _isOwner(String userId) async {
  if (userId.isEmpty) return false;
  try {
    final user = await Users(_client()).get(userId: userId);
    return user.labels.any((label) => '$label' == 'owner');
  } on AppwriteException {
    return false;
  }
}

String _firstUpi(Object? stored, String? fromEnv) {
  final row = '${stored ?? ''}'.trim();
  if (_upiId.hasMatch(row)) return row;
  final env = (fromEnv ?? '').trim();
  if (_upiId.hasMatch(env)) return env;
  return '';
}

String _firstName(Object? stored, String? fromEnv) {
  final row = '${stored ?? ''}'.trim();
  if (row.isNotEmpty) return row;
  final env = (fromEnv ?? '').trim();
  return env.isEmpty ? 'Bloomly' : env;
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
  return '$label · $line, $area, $city $pincode';
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}
