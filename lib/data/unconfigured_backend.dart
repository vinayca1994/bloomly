import 'package:flutter/foundation.dart';

import 'auth_result.dart';
import 'backend.dart';
import 'models.dart';
import 'online_payment.dart';

/// Release builds refuse the in-memory shop when Appwrite is not configured.
class UnconfiguredBackend extends BloomlyBackend {
  @override
  bool ready = true;

  @override
  String? loadError = 'This release is missing the Bloom shop configuration.';

  @override
  StoreSettings store = StoreSettings.fallback;

  @override
  List<ShopCategory> categories = const [];

  @override
  List<Product> products = const [];

  @override
  Profile? currentUser;

  @override
  List<OrderRecord> orders = const [];

  @override
  Future<void> reload() async {}

  @override
  Uint8List? imageBytesFor(String productId) => null;

  @override
  List<Address> addressesFor(String userId) => const [];

  @override
  OrderRecord? orderById(String id) => null;

  @override
  Stream<OrderRecord?> watchOrder(String id) => const Stream.empty();

  @override
  Future<String?> signIn(String email, String password) async => loadError;

  @override
  Future<String?> signUp(String name, String email, String password) async =>
      loadError;

  @override
  Future<PhoneLoginStart> startPhoneLogin(
    String phone, {
    required OtpChannel channel,
  }) async {
    return PhoneLoginStart.failure(loadError!);
  }

  @override
  Future<String?> verifyPhoneOtp({
    required String userId,
    required String code,
    required OtpChannel channel,
  }) async => loadError;

  @override
  Future<PhoneLoginStart> startEmailLogin(String email) async {
    return PhoneLoginStart.failure(loadError!);
  }

  @override
  Future<String?> verifyEmailOtp({
    required String userId,
    required String code,
  }) async => loadError;

  @override
  Future<String?> updateDisplayName(String name) async => loadError;

  @override
  Future<RecoveryStart> sendPasswordReset(String email) async =>
      RecoveryStart.failure(loadError!);

  @override
  Future<String?> completePasswordReset({
    required String userId,
    required String code,
    required String password,
  }) async => loadError;

  @override
  Future<String?> signOut() async => null;

  @override
  Future<String?> deleteAccount({String? password}) async => loadError;

  @override
  Future<void> saveAddress(Address address) async {}

  @override
  Future<void> deleteAddress(String id) async {}

  @override
  Future<OrderRecord> placeOrder({
    required String userId,
    required Address address,
    required List<CartLine> lines,
    String? idempotencyKey,
  }) {
    throw BloomlyException(loadError!);
  }

  @override
  Future<OnlinePayment> startOnlinePayment({
    required String userId,
    required Address address,
    required List<CartLine> lines,
    String? idempotencyKey,
  }) {
    throw BloomlyException(loadError!);
  }

  @override
  Future<OnlinePayment> resumeOnlinePayment(String orderId) {
    throw BloomlyException(loadError!);
  }

  @override
  Future<String?> verifyOnlinePayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String signature,
  }) async => loadError;

  @override
  Future<String?> noteUpiPayment({
    required String orderId,
    required String reference,
  }) async => loadError;

  @override
  Future<String?> confirmUpiPayment(String orderId) async => loadError;

  @override
  Future<String?> completeTestPayment(String orderId) async => loadError;

  @override
  Future<String?> updateOrderStatus(String orderId, String status) async =>
      loadError;

  @override
  Future<String?> markRefunded(String orderId) async => loadError;

  @override
  List<Profile> get riders => const [];

  @override
  RiderLocation? locationFor(String orderId) => null;

  @override
  DeliveryReview? reviewFor(String orderId) => null;

  @override
  Future<String?> createRider({
    required String name,
    required String email,
    required String password,
  }) async => loadError;

  @override
  Future<String?> assignRider({
    required String orderId,
    required String riderId,
  }) async => loadError;

  @override
  Future<String?> updateRiderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async => loadError;

  @override
  Future<String?> markDelivered(String orderId) async => loadError;

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
  }) async => loadError;

  @override
  Future<String?> cancelOrder(String orderId) async => loadError;

  @override
  Future<void> expireStaleUpiOrders() async {}

  @override
  Future<void> updateStore(StoreSettings next) async {}

  @override
  Future<String?> uploadPromoMedia({
    required Uint8List bytes,
    required String filename,
  }) async => null;

  @override
  Future<void> setProductAvailable(String productId, bool available) async {}

  @override
  Future<void> setVariantPrice(
    String productId,
    String variantId,
    int price,
  ) async {}

  @override
  Future<void> upsertProduct(Product product, {Uint8List? imageBytes}) async {}
}
