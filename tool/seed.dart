import 'dart:io';

import 'package:bloomly/data/catalog_seed.dart';
import 'package:bloomly/data/ids.dart';
import 'package:bloomly/data/models.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart';
import 'package:dart_appwrite/models.dart' as models;

/// Creates the Bloom database, bucket, owner, and catalog.
///
/// Required environment:
/// APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, APPWRITE_API_KEY
///
/// Optional:
/// APPWRITE_OWNER_EMAIL (default owner@bloomly.app)
/// APPWRITE_OWNER_PASSWORD (required, at least 12 characters)
Future<void> main() async {
  final fileEnv = _dotEnv();
  String env(String key) => Platform.environment[key] ?? fileEnv[key] ?? '';
  final endpoint = env('APPWRITE_ENDPOINT');
  final projectId = env('APPWRITE_PROJECT_ID');
  final apiKey = env('APPWRITE_API_KEY');
  final ownerPassword = env('APPWRITE_OWNER_PASSWORD');
  if (endpoint.isEmpty || projectId.isEmpty || apiKey.isEmpty) {
    stderr.writeln(
      'Set APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, and APPWRITE_API_KEY.',
    );
    exitCode = 64;
    return;
  }
  if (ownerPassword.length < 12) {
    stderr.writeln('Set APPWRITE_OWNER_PASSWORD to at least 12 characters.');
    exitCode = 64;
    return;
  }

  final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey);
  final tables = TablesDB(client);
  final storage = Storage(client);
  final users = Users(client);

  await _ignore(() => tables.create(databaseId: Ids.database, name: 'Bloom'));
  await _table(tables, Ids.store, 'Store', [
    _varchar('city', 80),
    _varchar('pincode', 6, required: false, fallback: '563130'),
    _varchar('etaLabel', 40),
    _intCol('deliveryFee'),
    _intCol('freeDeliveryAbove'),
    _varchar('upiId', 80, required: false),
    _varchar('upiName', 80, required: false, fallback: 'Bloom'),
    _varchar('storePhone', 20, required: false, fallback: ''),
    _varchar('promotions', 8000, required: false, fallback: ''),
  ], guestRead: true);
  await _table(tables, Ids.categories, 'Categories', [
    _varchar('name', 80),
    _varchar('slug', 80),
    _varchar('kind', 20),
    _varchar('parentSlug', 80, required: false),
    _intCol('sort'),
    _varchar('emoji', 8),
  ], guestRead: true);
  await _table(tables, Ids.products, 'Products', [
    _varchar('name', 120),
    _varchar('categorySlug', 80),
    _varchar('description', 500),
    _varchar('imageUrl', 2000, required: false),
    _boolCol('isAvailable'),
    _varchar('region', 16, required: false),
    _intCol('sort'),
  ], guestRead: true);
  await _table(tables, Ids.variants, 'Variants', [
    _varchar('productId', 36),
    _varchar('label', 40),
    _intCol('price'),
    _intCol('mrp'),
    _boolCol('isAvailable'),
  ], guestRead: true);
  await _table(
    tables,
    Ids.addresses,
    'Addresses',
    [
      _varchar('userId', 36),
      _varchar('label', 40),
      _varchar('line', 160),
      _varchar('area', 80),
      _varchar('city', 80),
      _varchar('pincode', 12),
      _varchar('landmark', 120, required: false, fallback: ''),
      _boolCol('isDefault'),
      _varchar('latitude', 32, required: false, fallback: ''),
      _varchar('longitude', 32, required: false, fallback: ''),
    ],
    rowSecurity: true,
    permissions: _addressGrants(),
  );
  await _table(
    tables,
    Ids.orders,
    'Orders',
    [
      _varchar('userId', 36),
      _varchar('addressSnapshot', 300),
      _varchar('status', 32),
      _intCol('subtotal'),
      _intCol('deliveryFee'),
      _intCol('total'),
      _varchar('paymentMethod', 16),
      _varchar('paymentStatus', 16, required: false, fallback: 'pending'),
      _varchar('gatewayOrderId', 64, required: false, fallback: ''),
      _varchar('gatewayPaymentId', 64, required: false, fallback: ''),
      _varchar('placedAt', 40),
      _varchar('riderId', 36, required: false, fallback: ''),
      _varchar('riderName', 80, required: false, fallback: ''),
      _varchar('customerPhone', 20, required: false, fallback: ''),
      _varchar('destLatitude', 32, required: false, fallback: ''),
      _varchar('destLongitude', 32, required: false, fallback: ''),
      _varchar('upiTxnRef', 40, required: false, fallback: ''),
    ],
    rowSecurity: true,
    permissions: _orderGrants(),
  );
  await _table(
    tables,
    Ids.orderItems,
    'Order items',
    [
      _varchar('orderId', 36),
      _varchar('productId', 36),
      _varchar('name', 120),
      _varchar('variantLabel', 40),
      _intCol('unitPrice'),
      _intCol('qty'),
    ],
    rowSecurity: true,
    permissions: _itemGrants(),
  );
  await _table(
    tables,
    Ids.riderLocations,
    'Rider locations',
    [
      _varchar('orderId', 36),
      _varchar('latitude', 32, required: false, fallback: ''),
      _varchar('longitude', 32, required: false, fallback: ''),
      _varchar('updatedAt', 40, required: false, fallback: ''),
    ],
    rowSecurity: true,
    permissions: _locationGrants(),
  );
  await _table(
    tables,
    Ids.reviews,
    'Reviews',
    [
      _varchar('orderId', 36),
      _varchar('userId', 36),
      _varchar('riderId', 36, required: false, fallback: ''),
      _score('freshness'),
      _score('rightItems'),
      _score('packing'),
      _score('onTime'),
      _score('polite'),
      _score('careful'),
      _varchar('note', 280, required: false, fallback: ''),
      _varchar('createdAt', 40),
    ],
    rowSecurity: true,
    permissions: _reviewGrants(),
  );
  await _table(
    tables,
    Ids.profiles,
    'Profiles',
    [
      _varchar('userId', 36),
      _varchar('name', 80),
      _varchar('role', 20),
      _varchar('phone', 20, required: false, fallback: ''),
      _varchar('email', 120, required: false, fallback: ''),
    ],
    rowSecurity: true,
    permissions: _profileGrants(),
  );
  // No client permissions. phone-login stores WhatsApp code hashes here.
  await _table(tables, Ids.otpChallenges, 'OTP challenges', [
    _varchar('phone', 20),
    _varchar('codeHash', 64),
    _varchar('expiresAt', 20),
    _varchar('sentAt', 20),
    _intCol('attempts'),
    _varchar('attemptStamp', 20, required: false, fallback: ''),
  ], permissions: const []);
  await _table(tables, Ids.otpLimits, 'OTP send limits', [
    _varchar('phone', 20),
    _varchar('windowStart', 20),
    _intCol('sendCount'),
  ], permissions: const []);
  await _table(tables, Ids.paymentEvents, 'Payment events', [
    _varchar('orderId', 36),
    _varchar('actorId', 36),
    _varchar('action', 32),
    _intCol('amount'),
    _varchar('reference', 64, required: false, fallback: ''),
    _varchar('createdAt', 40),
  ], permissions: const []);
  await _ignore(
    () => storage.createBucket(
      bucketId: Ids.bucket,
      name: 'Product images',
      permissions: [
        Permission.read(Role.any()),
        Permission.create(Role.label('owner')),
        Permission.update(Role.label('owner')),
        Permission.delete(Role.label('owner')),
      ],
    ),
  );

  await _syncPermissions(tables);
  await _varcharColumn(tables, Ids.orders, 'upiTxnRef', 40);
  await _varcharColumn(tables, Ids.otpChallenges, 'attemptStamp', 20);
  await _indexes(tables);
  await _lockCustomerWrites(tables);

  final email = env('APPWRITE_OWNER_EMAIL').isEmpty
      ? 'owner@bloomly.app'
      : env('APPWRITE_OWNER_EMAIL');
  final password = ownerPassword;
  var ownerId = Ids.ownerUser;
  try {
    final created = await users.create(
      userId: Ids.ownerUser,
      email: email,
      password: password,
      name: 'Asha Rao',
    );
    ownerId = created.$id;
  } on AppwriteException catch (error) {
    if (error.code != 409) rethrow;
    final list = await users.list(queries: [Query.equal('email', email)]);
    ownerId = list.users.first.$id;
  }
  await users.updateLabels(userId: ownerId, labels: ['owner']);

  await _varcharColumn(tables, Ids.store, 'promotions', 8000);
  await _varcharColumn(tables, Ids.store, 'pincode', 6, fallback: '563130');
  await _row(tables, Ids.store, Ids.storeRow, seedStore.toMap());
  await _fillStorePin(tables);
  for (final category in seedCategories) {
    await _repairCategory(tables, category);
  }
  for (final product in seedProducts) {
    await _row(tables, Ids.products, product.id, product.toMap());
    for (final variant in product.variants) {
      await _row(tables, Ids.variants, variant.id, variant.toMap());
    }
  }
  await _row(
    tables,
    Ids.profiles,
    ownerId,
    {'userId': ownerId, 'name': 'Asha Rao', 'role': 'owner', 'phone': ''},
    permissions: [
      Permission.read(Role.user(ownerId)),
      Permission.read(Role.label('owner')),
    ],
  );

  await _varcharColumn(tables, Ids.addresses, 'latitude', 32);
  await _varcharColumn(tables, Ids.addresses, 'longitude', 32);
  await _varcharColumn(tables, Ids.addresses, 'landmark', 120);
  await _varcharColumn(
    tables,
    Ids.orders,
    'paymentStatus',
    16,
    fallback: 'pending',
  );
  await _varcharColumn(tables, Ids.orders, 'gatewayOrderId', 64);
  await _varcharColumn(tables, Ids.orders, 'gatewayPaymentId', 64);
  await _varcharColumn(tables, Ids.orders, 'riderId', 36);
  await _varcharColumn(tables, Ids.orders, 'riderName', 80);
  await _varcharColumn(tables, Ids.orders, 'customerPhone', 20);
  await _varcharColumn(tables, Ids.orders, 'destLatitude', 32);
  await _varcharColumn(tables, Ids.orders, 'destLongitude', 32);
  await _varcharColumn(tables, Ids.profiles, 'email', 120);
  await _varcharColumn(tables, Ids.profiles, 'phone', 20);
  await _varcharColumn(tables, Ids.store, 'upiId', 80);
  await _varcharColumn(tables, Ids.store, 'upiName', 80, fallback: 'Bloom');
  await _varcharColumn(tables, Ids.store, 'storePhone', 20);

  stdout.writeln('Bloom is seeded. Owner: $email');
}

Map<String, Object> _varchar(
  String key,
  int size, {
  bool required = true,
  String? fallback,
}) => {
  'key': key,
  'type': 'varchar',
  'size': size,
  'required': required,
  'default': ?fallback,
};

Future<void> _varcharColumn(
  TablesDB tables,
  String tableId,
  String key,
  int size, {
  String fallback = '',
}) {
  return _ignore(
    () => tables.createVarcharColumn(
      databaseId: Ids.database,
      tableId: tableId,
      key: key,
      size: size,
      xrequired: false,
      xdefault: fallback,
    ),
  );
}

Map<String, Object> _intCol(String key) => {
  'key': key,
  'type': 'integer',
  'required': true,
  'min': 0,
  'max': 10000000,
};

Map<String, Object> _score(String key) => {
  'key': key,
  'type': 'integer',
  'required': true,
  'min': 1,
  'max': 5,
};

Map<String, Object> _boolCol(String key) => {
  'key': key,
  'type': 'boolean',
  'required': true,
};

Future<void> _table(
  TablesDB tables,
  String id,
  String name,
  List<Map<String, Object>> columns, {
  bool guestRead = false,
  bool rowSecurity = false,
  List<String>? permissions,
}) {
  return _ignore(
    () => tables.createTable(
      databaseId: Ids.database,
      tableId: id,
      name: name,
      rowSecurity: rowSecurity,
      columns: columns,
      permissions:
          permissions ??
          [
            if (guestRead) Permission.read(Role.any()),
            Permission.create(Role.label('owner')),
            Permission.read(Role.label('owner')),
            Permission.update(Role.label('owner')),
            Permission.delete(Role.label('owner')),
          ],
    ),
  );
}

Future<void> _fillStorePin(TablesDB tables) async {
  try {
    final row = await tables.getRow(
      databaseId: Ids.database,
      tableId: Ids.store,
      rowId: Ids.storeRow,
    );
    final pin = '${row.data['pincode'] ?? ''}'.trim();
    if (pin.isNotEmpty) return;
    await tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.store,
      rowId: Ids.storeRow,
      data: {'pincode': '563130'},
    );
  } on AppwriteException catch (error) {
    if (error.code == 404) return;
    rethrow;
  }
}

Future<void> _repairCategory(TablesDB tables, ShopCategory category) async {
  final data = {
    'name': category.name,
    'slug': category.slug,
    'kind': category.kind,
    'parentSlug': category.parentSlug ?? '',
    'sort': category.sort,
    'emoji': category.emoji,
  };
  try {
    await tables.createRow(
      databaseId: Ids.database,
      tableId: Ids.categories,
      rowId: category.id,
      data: data,
    );
  } on AppwriteException catch (error) {
    if (error.code == 403) return;
    if (error.code != 409) rethrow;
    await tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.categories,
      rowId: category.id,
      data: data,
    );
  }
}

Future<void> _row(
  TablesDB tables,
  String tableId,
  String rowId,
  Map<String, dynamic> data, {
  List<String>? permissions,
}) {
  return _ignore(
    () => tables.createRow(
      databaseId: Ids.database,
      tableId: tableId,
      rowId: rowId,
      data: data,
      permissions: permissions,
    ),
  );
}

Map<String, String> _dotEnv() {
  final file = File('.env');
  if (!file.existsSync()) return const {};
  final values = <String, String>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final index = line.indexOf('=');
    if (index <= 0) continue;
    values[line.substring(0, index).trim()] = line.substring(index + 1).trim();
  }
  return values;
}

Future<void> _syncPermissions(TablesDB tables) async {
  await tables.updateTable(
    databaseId: Ids.database,
    tableId: Ids.addresses,
    name: 'Addresses',
    rowSecurity: true,
    permissions: _addressGrants(),
  );
  await tables.updateTable(
    databaseId: Ids.database,
    tableId: Ids.orders,
    name: 'Orders',
    rowSecurity: true,
    permissions: _orderGrants(),
  );
  await tables.updateTable(
    databaseId: Ids.database,
    tableId: Ids.orderItems,
    name: 'Order items',
    rowSecurity: true,
    permissions: _itemGrants(),
  );
  await tables.updateTable(
    databaseId: Ids.database,
    tableId: Ids.riderLocations,
    name: 'Rider locations',
    rowSecurity: true,
    permissions: _locationGrants(),
  );
  await tables.updateTable(
    databaseId: Ids.database,
    tableId: Ids.reviews,
    name: 'Reviews',
    rowSecurity: true,
    permissions: _reviewGrants(),
  );
  await tables.updateTable(
    databaseId: Ids.database,
    tableId: Ids.profiles,
    name: 'Profiles',
    rowSecurity: true,
    permissions: _profileGrants(),
  );
}

List<String> _addressGrants() => [
  Permission.create(Role.users()),
  Permission.read(Role.label('owner')),
  Permission.update(Role.label('owner')),
  Permission.delete(Role.label('owner')),
];

List<String> _orderGrants() => [
  Permission.read(Role.label('owner')),
  Permission.update(Role.label('owner')),
  Permission.delete(Role.label('owner')),
];

List<String> _itemGrants() => [
  Permission.read(Role.label('owner')),
  Permission.update(Role.label('owner')),
];

List<String> _locationGrants() => [Permission.read(Role.label('owner'))];

List<String> _reviewGrants() => [Permission.read(Role.label('owner'))];

List<String> _profileGrants() => [Permission.read(Role.label('owner'))];

Future<void> _indexes(TablesDB tables) async {
  await _index(tables, Ids.orders, 'orders_user', ['userId']);
  await _index(tables, Ids.orders, 'orders_status', ['status']);
  await _index(tables, Ids.orders, 'orders_placed', ['placedAt']);
  await _index(tables, Ids.orderItems, 'items_order', ['orderId']);
  await _index(tables, Ids.addresses, 'addresses_user', ['userId']);
  await _index(tables, Ids.reviews, 'reviews_order', ['orderId']);
  await _index(tables, Ids.reviews, 'reviews_user', ['userId']);
  await _index(tables, Ids.riderLocations, 'locations_order', ['orderId']);
  await _index(tables, Ids.profiles, 'profiles_user', ['userId']);
}

Future<void> _index(TablesDB tables, String tableId, String key, List<String> columns) {
  return _ignore(
    () => tables.createIndex(
      databaseId: Ids.database,
      tableId: tableId,
      key: key,
      type: TablesDBIndexType.key,
      columns: columns,
    ),
  );
}

/// Strips customer update from orders that were created before the server
/// owned money and status. Table grants are not enough: Appwrite also honors
/// the row grant.
Future<void> _lockCustomerWrites(TablesDB tables) async {
  final orders = await _allRows(tables, Ids.orders);
  final customerOf = <String, String>{};
  final riderOf = <String, String>{};
  for (final row in orders) {
    final userId = '${row.data['userId'] ?? ''}';
    final riderId = '${row.data['riderId'] ?? ''}';
    if (userId.isEmpty) continue;
    customerOf[row.$id] = userId;
    if (riderId.isNotEmpty) riderOf[row.$id] = riderId;
    await tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.orders,
      rowId: row.$id,
      data: {'userId': userId},
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.read(Role.label('owner')),
        Permission.update(Role.label('owner')),
        if (riderId.isNotEmpty) Permission.read(Role.user(riderId)),
      ],
    );
  }
  for (final row in await _allRows(tables, Ids.orderItems)) {
    final orderId = '${row.data['orderId'] ?? ''}';
    final userId = customerOf[orderId] ?? '';
    if (userId.isEmpty) continue;
    await tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.orderItems,
      rowId: row.$id,
      data: {'orderId': orderId},
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.read(Role.label('owner')),
        Permission.update(Role.label('owner')),
      ],
    );
  }
  for (final row in await _allRows(tables, Ids.addresses)) {
    final userId = '${row.data['userId'] ?? ''}';
    if (userId.isEmpty) continue;
    await tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.addresses,
      rowId: row.$id,
      data: {'userId': userId},
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
        Permission.read(Role.label('owner')),
        Permission.update(Role.label('owner')),
        Permission.delete(Role.label('owner')),
      ],
    );
  }
  for (final row in await _allRows(tables, Ids.riderLocations)) {
    final orderId = '${row.data['orderId'] ?? row.$id}';
    final userId = customerOf[orderId] ?? '';
    final riderId = riderOf[orderId] ?? '';
    if (userId.isEmpty) continue;
    await tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.riderLocations,
      rowId: row.$id,
      data: {'orderId': orderId},
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.read(Role.label('owner')),
        if (riderId.isNotEmpty) Permission.read(Role.user(riderId)),
      ],
    );
  }
  for (final row in await _allRows(tables, Ids.reviews)) {
    final orderId = '${row.data['orderId'] ?? ''}';
    final userId = '${row.data['userId'] ?? ''}';
    final riderId = '${row.data['riderId'] ?? ''}';
    if (userId.isEmpty) continue;
    await tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.reviews,
      rowId: row.$id,
      data: {'orderId': orderId.isEmpty ? row.$id : orderId},
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.read(Role.label('owner')),
        if (riderId.isNotEmpty) Permission.read(Role.user(riderId)),
      ],
    );
  }
}

Future<List<models.Row>> _allRows(TablesDB tables, String tableId) async {
  final collected = <models.Row>[];
  var offset = 0;
  while (true) {
    final page = await tables.listRows(
      databaseId: Ids.database,
      tableId: tableId,
      queries: [Query.limit(100), Query.offset(offset)],
    );
    collected.addAll(page.rows);
    if (page.rows.length < 100) return collected;
    offset += 100;
  }
}

Future<void> _ignore(Future<Object?> Function() action) async {
  try {
    await action();
  } on AppwriteException catch (error) {
    // 409 already exists; 403 on free plans when create is blocked but resource is there.
    if (error.code == 409 || error.code == 403) return;
    rethrow;
  }
}
