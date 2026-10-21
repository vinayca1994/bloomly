import 'dart:io';

import 'package:bloomly/data/catalog_seed.dart';
import 'package:bloomly/data/ids.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// Creates the Bloomly database, bucket, owner, and catalog.
///
/// Required environment:
/// APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, APPWRITE_API_KEY
///
/// Optional:
/// APPWRITE_OWNER_EMAIL (default owner@bloomly.app)
/// APPWRITE_OWNER_PASSWORD (default bloomly123)
Future<void> main() async {
  final fileEnv = _dotEnv();
  String env(String key) => Platform.environment[key] ?? fileEnv[key] ?? '';
  final endpoint = env('APPWRITE_ENDPOINT');
  final projectId = env('APPWRITE_PROJECT_ID');
  final apiKey = env('APPWRITE_API_KEY');
  if (endpoint.isEmpty || projectId.isEmpty || apiKey.isEmpty) {
    stderr.writeln(
      'Set APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, and APPWRITE_API_KEY.',
    );
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

  await _ignore(() => tables.create(databaseId: Ids.database, name: 'Bloomly'));
  await _table(
    tables,
    Ids.store,
    'Store',
    [
      _varchar('city', 80),
      _varchar('etaLabel', 40),
      _intCol('deliveryFee'),
      _intCol('freeDeliveryAbove'),
      _varchar('upiId', 80, required: false),
      _varchar('upiName', 80, required: false, fallback: 'Bloomly'),
      _varchar('storePhone', 20, required: false, fallback: ''),
    ],
    guestRead: true,
  );
  await _table(
    tables,
    Ids.categories,
    'Categories',
    [
      _varchar('name', 80),
      _varchar('slug', 80),
      _varchar('kind', 20),
      _varchar('parentSlug', 80, required: false),
      _intCol('sort'),
      _varchar('emoji', 8),
    ],
    guestRead: true,
  );
  await _table(
    tables,
    Ids.products,
    'Products',
    [
      _varchar('name', 120),
      _varchar('categorySlug', 80),
      _varchar('description', 500),
      _varchar('imageUrl', 2000, required: false),
      _boolCol('isAvailable'),
      _varchar('region', 16, required: false),
      _intCol('sort'),
    ],
    guestRead: true,
  );
  await _table(
    tables,
    Ids.variants,
    'Variants',
    [
      _varchar('productId', 36),
      _varchar('label', 40),
      _intCol('price'),
      _intCol('mrp'),
      _boolCol('isAvailable'),
    ],
    guestRead: true,
  );
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
    permissions: [
      Permission.create(Role.users()),
      Permission.read(Role.label('owner')),
      Permission.update(Role.label('owner')),
      Permission.delete(Role.label('owner')),
    ],
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
    ],
    rowSecurity: true,
    permissions: [
      Permission.create(Role.users()),
      Permission.read(Role.label('owner')),
      Permission.update(Role.label('owner')),
      Permission.delete(Role.label('owner')),
    ],
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
    permissions: [
      Permission.create(Role.users()),
      Permission.read(Role.label('owner')),
      Permission.update(Role.label('owner')),
    ],
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
    ],
    rowSecurity: true,
    permissions: [
      Permission.create(Role.users()),
      Permission.read(Role.label('owner')),
    ],
  );
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

  final email = env('APPWRITE_OWNER_EMAIL').isEmpty ? 'owner@bloomly.app' : env('APPWRITE_OWNER_EMAIL');
  final password = env('APPWRITE_OWNER_PASSWORD').isEmpty ? 'bloomly123' : env('APPWRITE_OWNER_PASSWORD');
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

  await _row(
    tables,
    Ids.store,
    Ids.storeRow,
    seedStore.toMap(),
  );
  for (final category in seedCategories) {
    await _row(tables, Ids.categories, category.id, {
      'name': category.name,
      'slug': category.slug,
      'kind': category.kind,
      'parentSlug': category.parentSlug ?? '',
      'sort': category.sort,
      'emoji': category.emoji,
    });
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
  await _varcharColumn(tables, Ids.orders, 'paymentStatus', 16, fallback: 'pending');
  await _varcharColumn(tables, Ids.orders, 'gatewayOrderId', 64);
  await _varcharColumn(tables, Ids.orders, 'gatewayPaymentId', 64);
  await _varcharColumn(tables, Ids.profiles, 'phone', 20);
  await _varcharColumn(tables, Ids.store, 'upiId', 80);
  await _varcharColumn(tables, Ids.store, 'upiName', 80, fallback: 'Bloomly');
  await _varcharColumn(tables, Ids.store, 'storePhone', 20);

  stdout.writeln('Bloomly is seeded. Owner: $email');
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
      permissions: permissions ??
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

Future<void> _ignore(Future<Object?> Function() action) async {
  try {
    await action();
  } on AppwriteException catch (error) {
    // 409 already exists; 403 on free plans when create is blocked but resource is there.
    if (error.code == 409 || error.code == 403) return;
    rethrow;
  }
}
