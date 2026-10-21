import 'package:flutter/foundation.dart';

import 'auth_result.dart';
import 'models.dart';
import 'online_payment.dart';

abstract class BloomlyBackend extends ChangeNotifier {
  bool get ready;
  String? get loadError;

  /// Reloads catalog/session after a failed startup (or pull-to-refresh style retry).
  Future<void> reload();

  StoreSettings get store;
  List<ShopCategory> get categories;
  List<Product> get products;
  Profile? get currentUser;
  List<OrderRecord> get orders;

  Uint8List? imageBytesFor(String productId);

  Product? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Variant? variantOf(String productId, String variantId) {
    final product = productById(productId);
    if (product == null) return null;
    for (final variant in product.variants) {
      if (variant.id == variantId) return variant;
    }
    return null;
  }

  List<Address> addressesFor(String userId);
  OrderRecord? orderById(String id);
  Stream<OrderRecord?> watchOrder(String id);

  /// True for the in-memory shop, so debug builds can show the demo accounts.
  bool get demoShortcuts => false;

  /// True when no store UPI ID is set, so pay confirms in a demo dialog.
  bool get usesTestCheckout => false;

  Future<String?> signIn(String email, String password);
  Future<String?> signUp(String name, String email, String password);
  Future<PhoneLoginStart> startPhoneLogin(String phone);
  Future<String?> verifyPhoneOtp({required String userId, required String code});
  Future<String?> updateDisplayName(String name);
  Future<RecoveryStart> sendPasswordReset(String email);
  Future<String?> completePasswordReset({
    required String userId,
    required String code,
    required String password,
  });
  Future<void> signOut();
  Future<String?> deleteAccount();

  Future<void> saveAddress(Address address);
  Future<void> deleteAddress(String id);

  Future<OrderRecord> placeOrder({
    required String userId,
    required Address address,
    required List<CartLine> lines,
  });

  Future<OnlinePayment> startOnlinePayment({
    required String userId,
    required Address address,
    required List<CartLine> lines,
  });

  /// Customer says the UPI app accepted the payment. This does not mark it paid.
  Future<String?> noteUpiPayment({required String orderId, required String reference});

  /// Store confirms the money arrived in the UPI app.
  Future<String?> confirmUpiPayment(String orderId);

  /// Confirms the in-memory demo checkout. Live shops reject this.
  Future<String?> completeTestPayment(String orderId);

  Future<void> updateOrderStatus(String orderId, String status);

  /// Customer or owner cancels when [OrderStatus.customerCanCancel] / owner rules allow.
  Future<String?> cancelOrder(String orderId);

  /// Cancels stale UPI orders still awaiting payment past [OrderRecord.upiPaymentTimeout].
  Future<void> expireStaleUpiOrders();

  Future<void> updateStore(StoreSettings next);
  Future<void> setProductAvailable(String productId, bool available);
  Future<void> setVariantPrice(String productId, String variantId, int price);
  Future<void> upsertProduct(Product product, {Uint8List? imageBytes});
}
