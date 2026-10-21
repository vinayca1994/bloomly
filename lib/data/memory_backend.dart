import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../core/phone.dart';
import '../core/upi.dart';
import 'auth_result.dart';
import 'backend.dart';
import 'catalog_seed.dart';
import 'models.dart';
import 'online_payment.dart';
import 'pricing.dart';

class _Account {
  _Account({required this.password, required this.profile});

  String password;
  Profile profile;
}

class MemoryBackend extends BloomlyBackend {
  MemoryBackend.seeded({String upiId = '', String upiName = 'Bloomly'}) {
    store = seedStore.copyWith(upiId: upiId.trim(), upiName: upiName.trim().isEmpty ? 'Bloomly' : upiName.trim());
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
  static const demoOtp = _demoOtp;
  static const _ownerEmail = 'owner@bloomly.app';
  static const _customerEmail = 'customer@bloomly.app';
  static const _demoPassword = 'bloomly123';
  static const _demoOtp = '123456';

  @override
  bool get demoShortcuts => true;

  @override
  bool get usesTestCheckout => store.upiId.trim().isEmpty;

  @override
  bool ready = true;

  @override
  String? loadError;

  @override
  Future<void> reload() async {
    loadError = null;
    await expireStaleUpiOrders();
    notifyListeners();
  }

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
  String? _pendingUserId;
  String? _pendingPhone;
  bool _pendingIsNew = false;
  String? _resetUserId;
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
  Future<PhoneLoginStart> startPhoneLogin(String phone) async {
    final normalized = PhoneNumber.normalizeIndia(phone);
    if (normalized == null) {
      return const PhoneLoginStart.failure('Enter a valid 10-digit mobile number.');
    }
    final existing = _accounts.values
        .where((account) => account.profile.phone == normalized)
        .firstOrNull;
    if (existing != null) {
      _pendingUserId = existing.profile.id;
      _pendingIsNew = false;
    } else {
      _pendingUserId = _nextId('user');
      _pendingIsNew = true;
    }
    _pendingPhone = normalized;
    return PhoneLoginStart(userId: _pendingUserId, isNew: _pendingIsNew);
  }

  @override
  Future<String?> verifyPhoneOtp({required String userId, required String code}) async {
    if (code.trim() != _demoOtp) return 'That code is wrong.';
    if (userId != _pendingUserId || _pendingPhone == null) {
      return 'Request a new code.';
    }
    if (_pendingIsNew) {
      final profile = Profile(
        id: userId,
        name: '',
        email: '',
        phone: _pendingPhone!,
        role: 'customer',
      );
      _accounts['phone:$normalizedKey(_pendingPhone!)'] = _Account(
        password: '',
        profile: profile,
      );
      currentUser = profile;
    } else {
      currentUser = _accountById(userId)?.profile;
    }
    _pendingPhone = null;
    notifyListeners();
    return currentUser == null ? 'Request a new code.' : null;
  }

  @override
  Future<String?> updateDisplayName(String name) async {
    final user = currentUser;
    final trimmed = name.trim();
    if (user == null) return 'Sign in first.';
    if (trimmed.isEmpty) return 'Add your name.';
    final account = _accountById(user.id);
    if (account == null) return 'Sign in first.';
    account.profile = Profile(
      id: user.id,
      name: trimmed,
      email: user.email,
      phone: user.phone,
      role: user.role,
    );
    currentUser = account.profile;
    notifyListeners();
    return null;
  }

  @override
  Future<RecoveryStart> sendPasswordReset(String email) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password.isEmpty) {
      return const RecoveryStart.failure('No password account uses that email.');
    }
    _resetUserId = account.profile.id;
    return RecoveryStart(userId: account.profile.id);
  }

  @override
  Future<String?> completePasswordReset({
    required String userId,
    required String code,
    required String password,
  }) async {
    if (code.trim() != _demoOtp) return 'That code is wrong.';
    if (password.length < 8) return 'Use at least 8 characters.';
    final account = _accountById(userId);
    if (account == null || account.profile.id != _resetUserId) {
      return 'Request a new code.';
    }
    account.password = password;
    _resetUserId = null;
    return null;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    notifyListeners();
  }

  @override
  Future<String?> deleteAccount() async {
    final user = currentUser;
    if (user == null) return 'Sign in first.';
    if (user.isOwner) return 'The store owner account stays signed in here.';
    _accounts.removeWhere((_, account) => account.profile.id == user.id);
    _addresses = _addresses.where((address) => address.userId != user.id).toList();
    orders = orders.where((order) => order.userId != user.id).toList();
    currentUser = null;
    notifyListeners();
    return null;
  }

  _Account? _accountById(String id) {
    for (final account in _accounts.values) {
      if (account.profile.id == id) return account;
    }
    return null;
  }

  String normalizedKey(String phone) => phone;

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
    final orderId = _nextId('ord');
    final price = priceLines(
      backend: this,
      orderId: orderId,
      address: address,
      lines: lines,
      nextItemId: () => _nextId('item'),
    );
    final order = OrderRecord(
      id: orderId,
      userId: userId,
      addressSnapshot: address.snapshot,
      status: OrderStatus.placed,
      subtotal: price.subtotal,
      deliveryFee: price.deliveryFee,
      total: price.total,
      paymentMethod: PaymentMethod.cod,
      paymentStatus: PaymentStatus.pending,
      placedAt: DateTime.now(),
      items: price.items,
    );
    orders = [order, ...orders];
    notifyListeners();
    _emit(order);
    return order;
  }

  @override
  Future<OnlinePayment> startOnlinePayment({
    required String userId,
    required Address address,
    required List<CartLine> lines,
  }) async {
    final orderId = _nextId('ord');
    final price = priceLines(
      backend: this,
      orderId: orderId,
      address: address,
      lines: lines,
      nextItemId: () => _nextId('item'),
    );
    final order = OrderRecord(
      id: orderId,
      userId: userId,
      addressSnapshot: address.snapshot,
      status: OrderStatus.paymentPending,
      subtotal: price.subtotal,
      deliveryFee: price.deliveryFee,
      total: price.total,
      paymentMethod: PaymentMethod.upi,
      paymentStatus: PaymentStatus.pending,
      gatewayOrderId: store.upiId.trim(),
      placedAt: DateTime.now(),
      items: price.items,
    );
    orders = [order, ...orders];
    notifyListeners();
    _emit(order);
    return OnlinePayment(
      order: order,
      upiId: store.upiId.trim(),
      upiName: store.upiName.trim().isEmpty ? 'Bloomly' : store.upiName.trim(),
      amountRupees: price.total,
    );
  }

  @override
  Future<String?> noteUpiPayment({
    required String orderId,
    required String reference,
  }) async {
    final order = orderById(orderId);
    if (order == null) return 'Order not found.';
    if (store.upiId.trim().isEmpty) return 'Add the store UPI ID first.';
    final user = currentUser;
    if (user == null || (user.id != order.userId && !user.isOwner)) {
      return 'This order belongs to someone else.';
    }
    if (!order.awaitingPayment || order.paymentMethod != PaymentMethod.upi) {
      return 'This order is not awaiting a UPI payment.';
    }
    final cleaned = normalizeUpiReference(reference);
    if (cleaned == null) return 'Enter the UPI reference as letters and numbers only.';
    _replaceOrder(
      order.copyWith(
        paymentStatus: PaymentStatus.submitted,
        gatewayPaymentId: cleaned,
      ),
    );
    return null;
  }

  @override
  Future<String?> confirmUpiPayment(String orderId) async {
    final order = orderById(orderId);
    if (order == null) return 'Order not found.';
    if (currentUser?.isOwner != true) return 'Only the store can confirm a UPI payment.';
    if (order.paymentMethod != PaymentMethod.upi) return 'This order was not paid by UPI.';
    if (order.paymentStatus == PaymentStatus.paid && order.status == OrderStatus.placed) {
      return null;
    }
    if (!order.awaitingPayment) return 'This order is not awaiting a UPI payment.';
    _replaceOrder(
      order.copyWith(
        status: OrderStatus.placed,
        paymentStatus: PaymentStatus.paid,
      ),
    );
    return null;
  }

  @override
  Future<String?> completeTestPayment(String orderId) async {
    if (store.upiId.trim().isNotEmpty) {
      return 'This shop collects UPI in the customer’s app.';
    }
    final order = orderById(orderId);
    if (order == null) return 'Order not found.';
    if (!order.awaitingPayment) return 'This order is not awaiting payment.';
    _replaceOrder(
      order.copyWith(
        status: OrderStatus.placed,
        paymentStatus: PaymentStatus.paid,
        gatewayPaymentId: 'demo',
      ),
    );
    return null;
  }

  void _replaceOrder(OrderRecord updated) {
    orders = [
      for (final order in orders)
        if (order.id == updated.id) updated else order,
    ];
    _emit(updated);
    notifyListeners();
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
  Future<String?> cancelOrder(String orderId) async {
    final user = currentUser;
    final order = orderById(orderId);
    if (user == null || order == null) return 'Order not found.';
    final asOwner = user.isOwner;
    final asCustomer = user.id == order.userId;
    if (!asOwner && !asCustomer) return 'This order belongs to someone else.';
    if (asOwner && !OrderStatus.canCancel(order.status)) {
      return 'This order can no longer be cancelled.';
    }
    if (!asOwner && !OrderStatus.customerCanCancel(order.status)) {
      return 'You can cancel only before the store starts packing.';
    }
    _replaceOrder(
      order.copyWith(
        status: OrderStatus.cancelled,
        paymentStatus: order.awaitingPayment ? PaymentStatus.failed : order.paymentStatus,
      ),
    );
    return null;
  }

  @override
  Future<void> expireStaleUpiOrders() async {
    final stale = orders.where((order) => order.upiTimedOut).toList();
    for (final order in stale) {
      _replaceOrder(
        order.copyWith(
          status: OrderStatus.cancelled,
          paymentStatus: PaymentStatus.failed,
        ),
      );
    }
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
