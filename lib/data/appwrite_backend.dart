import 'dart:async';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';

import '../core/bill.dart';
import '../core/config.dart';
import 'backend.dart';
import 'ids.dart';
import 'models.dart';

class AppwriteBackend extends BloomlyBackend {
  AppwriteBackend(this.config) {
    _client = Client().setEndpoint(config.endpoint).setProject(config.projectId);
    _tables = TablesDB(_client);
    _account = Account(_client);
    _storage = Storage(_client);
    _realtime = Realtime(_client);
    unawaited(_load());
  }

  final AppConfig config;
  late final Client _client;
  late final TablesDB _tables;
  late final Account _account;
  late final Storage _storage;
  late final Realtime _realtime;
  RealtimeSubscription? _subscription;

  @override
  bool ready = false;

  @override
  String? loadError;

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

  List<Address> _cachedAddresses = [];
  final Map<String, Uint8List> _images = {};
  final Map<String, StreamController<OrderRecord?>> _watchers = {};

  Future<void> _load() async {
    try {
      await _loadSession();
      await _refreshAddresses();
      await _reloadCatalog();
      await _reloadOrders();
      await _listen();
      loadError = null;
    } on AppwriteException catch (error) {
      loadError = error.message ?? 'Could not reach Bloomly.';
    } catch (_) {
      loadError = 'Could not reach Bloomly.';
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> _listen() async {
    _subscription = _realtime.subscribe([
      Channel.tablesdb(Ids.database).table(Ids.orders).row().toString(),
    ]);
    _subscription!.stream.listen((_) {
      unawaited(_reloadOrders());
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
    if (storeDocs.isNotEmpty) store = _storeFrom(storeDocs.first);
    final categoryDocs = await _all(Ids.categories);
    categories = categoryDocs.map(_categoryFrom).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    final productDocs = await _all(Ids.products);
    final variantDocs = await _all(Ids.variants);
    products = [
      for (final doc in productDocs) _productFrom(doc, variantDocs),
    ]..sort((a, b) => a.sort.compareTo(b.sort));
  }

  Future<void> _reloadOrders() async {
    final orderDocs = await _all(Ids.orders);
    final itemDocs = await _all(Ids.orderItems);
    orders = [
      for (final doc in orderDocs) _orderFrom(doc, itemDocs),
    ]..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    for (final order in orders) {
      _watchers[order.id]?.add(order);
    }
    notifyListeners();
  }

  Future<void> _loadSession() async {
    try {
      final user = await _account.get();
      currentUser = Profile(
        id: user.$id,
        name: user.name.isEmpty ? user.email : user.name,
        email: user.email,
        role: user.labels.contains('owner') ? 'owner' : 'customer',
      );
    } on AppwriteException {
      currentUser = null;
    }
  }

  @override
  Uint8List? imageBytesFor(String productId) => _images[productId];

  @override
  List<Address> addressesFor(String userId) {
    return _cachedAddresses.where((address) => address.userId == userId).toList();
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

  @override
  Future<String?> signIn(String email, String password) async {
    try {
      await _account.createEmailPasswordSession(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _loadSession();
      await _refreshAddresses();
      await _reloadOrders();
      notifyListeners();
      return null;
    } on AppwriteException catch (error) {
      return error.message ?? 'Could not sign in.';
    }
  }

  @override
  Future<String?> signUp(String name, String email, String password) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email.trim().toLowerCase(),
        password: password,
        name: name.trim(),
      );
      await _account.createEmailPasswordSession(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _tables.createRow(
        databaseId: Ids.database,
        tableId: Ids.profiles,
        rowId: user.$id,
        data: {'userId': user.$id, 'name': name.trim(), 'role': 'customer'},
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.read(Role.label('owner')),
        ],
      );
      await _loadSession();
      notifyListeners();
      return null;
    } on AppwriteException catch (error) {
      return error.message ?? 'Could not create the account.';
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (_) {}
    currentUser = null;
    _cachedAddresses = [];
    notifyListeners();
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
        permissions: _own(user.id),
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
  }) async {
    if (lines.isEmpty) throw BloomlyException('Your cart is empty.');
    if (address.city.trim().toLowerCase() != store.city.trim().toLowerCase()) {
      throw BloomlyException('Bloomly delivers in ${store.city} only.');
    }
    final drafts = <OrderItem>[];
    var subtotal = 0;
    for (final line in lines) {
      final product = productById(line.productId);
      final variant = variantOf(line.productId, line.variantId);
      if (product == null || variant == null || !product.forSale) {
        throw BloomlyException(
          '${product?.name ?? 'An item'} is sold out. Remove it to continue.',
        );
      }
      subtotal += variant.price * line.qty;
      drafts.add(
        OrderItem(
          id: '',
          orderId: '',
          productId: product.id,
          name: product.name,
          variantLabel: variant.label,
          unitPrice: variant.price,
          qty: line.qty,
        ),
      );
    }
    final fee = deliveryFeeFor(
      subtotal,
      fee: store.deliveryFee,
      freeAbove: store.freeDeliveryAbove,
    );
    final createdOrder = await _tables.createRow(
      databaseId: Ids.database,
      tableId: Ids.orders,
      rowId: ID.unique(),
      data: {
        'userId': userId,
        'addressSnapshot': address.snapshot,
        'status': OrderStatus.placed,
        'subtotal': subtotal,
        'deliveryFee': fee,
        'total': subtotal + fee,
        'paymentMethod': 'cod',
        'placedAt': DateTime.now().toIso8601String(),
      },
      permissions: _own(userId),
    );
    final createdItems = <OrderItem>[];
    for (final draft in drafts) {
      final createdItem = await _tables.createRow(
        databaseId: Ids.database,
        tableId: Ids.orderItems,
        rowId: ID.unique(),
        data: draft.toMap()..['orderId'] = createdOrder.$id,
        permissions: _own(userId),
      );
      createdItems.add(_itemFrom(createdItem));
    }
    final order = _orderFrom(createdOrder, const []).copyWith(items: createdItems);
    orders = [order, ...orders.where((existing) => existing.id != order.id)];
    notifyListeners();
    _watchers[order.id]?.add(order);
    return order;
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.orders,
      rowId: orderId,
      data: {'status': status},
    );
    await _reloadOrders();
  }

  @override
  Future<void> updateStore(StoreSettings next) async {
    await _tables.updateRow(
      databaseId: Ids.database,
      tableId: Ids.store,
      rowId: Ids.storeRow,
      data: next.toMap(),
    );
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
      final known = variant.id.isNotEmpty &&
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

  List<String> _own(String userId) => [
    Permission.read(Role.user(userId)),
    Permission.update(Role.user(userId)),
    Permission.read(Role.label('owner')),
    Permission.update(Role.label('owner')),
  ];

  @override
  void dispose() {
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
        if (_text(variant.data, 'productId', '') == doc.$id) _variantFrom(variant),
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
    isDefault: _bool(data, 'isDefault'),
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
    paymentMethod: _text(data, 'paymentMethod', 'cod'),
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
