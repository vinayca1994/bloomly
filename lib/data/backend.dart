import 'package:flutter/foundation.dart';

import 'models.dart';

abstract class BloomlyBackend extends ChangeNotifier {
  bool get ready;
  String? get loadError;

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

  Future<String?> signIn(String email, String password);
  Future<String?> signUp(String name, String email, String password);
  Future<void> signOut();

  Future<void> saveAddress(Address address);
  Future<void> deleteAddress(String id);

  Future<OrderRecord> placeOrder({
    required String userId,
    required Address address,
    required List<CartLine> lines,
  });

  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> updateStore(StoreSettings next);
  Future<void> setProductAvailable(String productId, bool available);
  Future<void> setVariantPrice(String productId, String variantId, int price);
  Future<void> upsertProduct(Product product, {Uint8List? imageBytes});
}
