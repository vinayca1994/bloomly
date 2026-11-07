import 'package:flutter/foundation.dart';

import 'auth_result.dart';
import 'models.dart';
import 'online_payment.dart';

abstract class BloomlyBackend extends ChangeNotifier {
  bool get ready;
  String? get loadError;

  /// Reloads catalog/session after a failed startup (or pull-to-refresh style retry).
  Future<void> reload();

  /// Set when the latest order reload failed. The previous list stays.
  String? get ordersError => null;

  /// Reloads orders without taking the shop back to the splash.
  Future<void> refreshOrders() async {}

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

  /// Debug one-tap sign-in for customer, owner, or rider.
  Future<String?> signInDemo(String role) async => 'Demo sign-in is off.';

  Future<String?> signIn(String email, String password);
  Future<String?> signUp(String name, String email, String password);
  Future<PhoneLoginStart> startPhoneLogin(
    String phone, {
    required OtpChannel channel,
  });
  Future<String?> verifyPhoneOtp({
    required String userId,
    required String code,
    required OtpChannel channel,
  });
  Future<PhoneLoginStart> startEmailLogin(String email);
  Future<String?> verifyEmailOtp({
    required String userId,
    required String code,
  });
  Future<String?> updateDisplayName(String name);
  Future<RecoveryStart> sendPasswordReset(String email);
  Future<String?> completePasswordReset({
    required String userId,
    required String code,
    required String password,
  });
  Future<String?> signOut();
  Future<String?> deleteAccount({String? password});

  /// Called when the app returns to the foreground. Live shops resubscribe.
  Future<void> onForeground() async {}

  Future<void> saveAddress(Address address);
  Future<void> deleteAddress(String id);

  Future<OrderRecord> placeOrder({
    required String userId,
    required Address address,
    required List<CartLine> lines,
    String? idempotencyKey,
  });

  Future<OnlinePayment> startOnlinePayment({
    required String userId,
    required Address address,
    required List<CartLine> lines,
    String? idempotencyKey,
  });

  /// Opens the same unpaid UPI order again. Does not create a second bill.
  Future<OnlinePayment> resumeOnlinePayment(String orderId);

  /// Marks the order paid after Razorpay returns a signed capture.
  Future<String?> verifyOnlinePayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String signature,
  });

  /// Customer says the UPI app accepted the payment. This does not mark it paid.
  Future<String?> noteUpiPayment({
    required String orderId,
    required String reference,
  });

  /// Store confirms the money arrived in the UPI app.
  Future<String?> confirmUpiPayment(String orderId);

  /// Confirms the in-memory demo checkout. Live shops reject this.
  Future<String?> completeTestPayment(String orderId);

  Future<String?> updateOrderStatus(String orderId, String status);

  /// Owner records that a cancelled UPI payment was refunded.
  Future<String?> markRefunded(String orderId);

  List<Profile> get riders;

  RiderLocation? locationFor(String orderId);

  DeliveryReview? reviewFor(String orderId);

  /// Owner adds an email login with the `rider` role.
  Future<String?> createRider({
    required String name,
    required String email,
    required String password,
  });

  /// Owner sends the order out for delivery with this rider.
  Future<String?> assignRider({
    required String orderId,
    required String riderId,
  });

  /// Assigned rider publishes the current pin. This does not change the bill.
  Future<String?> updateRiderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  });

  /// Assigned rider, or the owner, marks an out-for-delivery order delivered.
  Future<String?> markDelivered(String orderId);

  /// Customer reviews a delivered order once.
  Future<String?> submitReview({
    required String orderId,
    required int freshness,
    required int rightItems,
    required int packing,
    required int onTime,
    required int polite,
    required int careful,
    String note = '',
  });

  /// Customer or owner cancels when [OrderStatus.customerCanCancel] / owner rules allow.
  Future<String?> cancelOrder(String orderId);

  /// Cancels stale UPI orders still awaiting payment past [OrderRecord.upiPaymentTimeout].
  Future<void> expireStaleUpiOrders();

  Future<void> updateStore(StoreSettings next);

  /// Stores a promo loop, Lottie file, or poster. Demo shops return null.
  Future<String?> uploadPromoMedia({
    required Uint8List bytes,
    required String filename,
  });
  Future<void> setProductAvailable(String productId, bool available);
  Future<void> setVariantPrice(String productId, String variantId, int price);
  Future<void> upsertProduct(Product product, {Uint8List? imageBytes});
}
