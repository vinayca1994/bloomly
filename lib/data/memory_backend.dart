import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../core/bill.dart';
import 'backend.dart';
import 'catalog_seed.dart';
import 'models.dart';

class _Account {
  _Account({required this.password, required this.profile});

  final String password;
  Profile profile;
}

class MemoryBackend extends BloomlyBackend {
  MemoryBackend.seeded() {
    store = seedStore;
    categories = List<ShopCategory>.of(seedCategories);
    products = seedProducts
        .map(
          (product) => product.copyWith(
            variants: product.variants.map((variant) => variant.copyWith()).toList(),
          ),
        )
        .toList();
    _accounts = {
      _ownerEmail: _Account(
        password: _demoPassword,
        profile: const Profile(
          id: 'owner',
          name: 'Asha Rao',
          email: _ownerEmail,
          role: 'owner',
        ),
      ),
      _customerEmail: _Account(
        password: _demoPassword,
        profile: const Profile(
          id: 'customer-demo',
          name: 'Meera Nair',
          email: _customerEmail,
          role: 'customer',
        ),
      ),
    };
    _addresses = [
      const Address(
        id: 'addr-demo',
        userId: 'customer-demo',
        label: 'Home',
        line: '42, 4th Cross',
        area: 'Koramangala',
        city: 'Bengaluru',
        pincode: '560034',
        isDefault: true,
      ),
    ];
  }

  static const ownerEmail = _ownerEmail;
  static const customerEmail = _customerEmail;
  static const demoPassword = _demoPassword;
  static const _ownerEmail = 'owner@bloomly.app';
  static const _customerEmail = 'customer@bloomly.app';
  static const _demoPassword = 'bloomly123';

  @override
  bool ready = true;

  @override
  String? loadError;

  @override
  late StoreSettings store;

  @override
  late List<ShopCategory> categories;

  @override
  late List<Product> products;

  @override
  Profile? currentUser;

  @override
  List<OrderRecord> orders = [];

  late Map<String, _Account> _accounts;
  List<Address> _addresses = [];
  final Map<String, Uint8List> _images = {};
  final Map<String, StreamController<OrderRecord?>> _watchers = {};
  int _seq = 0;

  String _nextId(String prefix) {
    _seq += 1;
    return '$prefix$_seq';
  }

  @override
  Uint8List? imageBytesFor(String productId) => _images[productId];

  @override
  List<Address> addressesFor(String userId) {
    return _addresses.where((address) => address.userId == userId).toList();
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

  void _emit(OrderRecord order) {
    final controller = _watchers[order.id];
    if (controller != null && !controller.isClosed) {
      controller.add(order);
    }
  }

  @override
  Future<String?> signIn(String email, String password) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      return 'That email and password do not match.';
    }
    currentUser = account.profile;
    notifyListeners();
    return null;
  }

  @override
  Future<String?> signUp(String name, String email, String password) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      return 'An account with this email already exists.';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    final profile = Profile(
      id: _nextId('user'),
      name: name.trim(),
      email: key,
      role: 'customer',
    );
    _accounts[key] = _Account(password: password, profile: profile);
    currentUser = profile;
    notifyListeners();
    return null;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    notifyListeners();
  }

  @override
  Future<void> saveAddress(Address address) async {
    if (address.isDefault) {
      _addresses = [
        for (final existing in _addresses)
          if (existing.userId == address.userId)
            existing.copyWith(isDefault: false)
          else
            existing,
      ];
    }
    final index = _addresses.indexWhere((item) => item.id == address.id);
    if (index == -1) {
      _addresses = [..._addresses, address];
    } else {
      _addresses = [
        for (final existing in _addresses)
          if (existing.id == address.id) address else existing,
      ];
    }
    notifyListeners();
  }

  @override
  Future<void> deleteAddress(String id) async {
    _addresses = _addresses.where((address) => address.id != id).toList();
    notifyListeners();
  }

  @override
  Future<OrderRecord> placeOrder({
    required String userId,
    required Address address,
    required List<CartLine> lines,
  }) async {
    if (lines.isEmpty) {
      throw BloomlyException('Your cart is empty.');
    }
    if (address.city.trim().toLowerCase() != store.city.trim().toLowerCase()) {
      throw BloomlyException('Bloomly delivers in ${store.city} only.');
    }
    final items = <OrderItem>[];
    var subtotal = 0;
    final orderId = _nextId('ord');
    for (final line in lines) {
      final product = productById(line.productId);
      final variant = variantOf(line.productId, line.variantId);
      if (product == null || variant == null || !product.forSale) {
        throw BloomlyException(
          '${product?.name ?? 'An item'} is sold out. Remove it to continue.',
        );
      }
      subtotal += variant.price * line.qty;
      items.add(
        OrderItem(
          id: _nextId('item'),
          orderId: orderId,
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
    final order = OrderRecord(
      id: orderId,
      userId: userId,
      addressSnapshot: address.snapshot,
      status: OrderStatus.placed,
      subtotal: subtotal,
      deliveryFee: fee,
      total: subtotal + fee,
      paymentMethod: 'cod',
      placedAt: DateTime.now(),
      items: items,
    );
    orders = [order, ...orders];
    notifyListeners();
    _emit(order);
    return order;
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    OrderRecord? updated;
    orders = [
      for (final order in orders)
        if (order.id == orderId)
          (updated = order.copyWith(status: status))
        else
          order,
    ];
    if (updated != null) _emit(updated);
    notifyListeners();
  }

  @override
  Future<void> updateStore(StoreSettings next) async {
    store = next;
    notifyListeners();
  }

  @override
  Future<void> setProductAvailable(String productId, bool available) async {
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
    final id = product.id.isEmpty ? _nextId('p') : product.id;
    final variants = [
      for (var i = 0; i < product.variants.length; i++)
        product.variants[i].id.isEmpty
            ? Variant(
                id: '$id-v$i',
                productId: id,
                label: product.variants[i].label,
                price: product.variants[i].price,
                mrp: product.variants[i].mrp,
                isAvailable: product.variants[i].isAvailable,
              )
            : product.variants[i].copyWith(),
    ];
    final next = Product(
      id: id,
      name: product.name,
      categorySlug: product.categorySlug,
      description: product.description,
      imageUrl: product.imageUrl,
      isAvailable: product.isAvailable,
      region: product.region,
      sort: product.sort == 0 ? products.length + 1 : product.sort,
      variants: variants,
    );
    final exists = products.any((item) => item.id == id);
    products = exists
        ? [for (final item in products) item.id == id ? next : item]
        : [...products, next];
    if (imageBytes != null) _images[id] = imageBytes;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _watchers.values) {
      controller.close();
    }
    super.dispose();
  }
}
