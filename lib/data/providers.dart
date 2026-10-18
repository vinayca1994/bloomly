import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/bill.dart';
import '../core/config.dart';
import 'appwrite_backend.dart';
import 'backend.dart';
import 'cart_controller.dart';
import 'memory_backend.dart';
import 'models.dart';

final backendProvider = ChangeNotifierProvider<BloomlyBackend>((ref) {
  final config = AppConfig.fromEnvironment();
  if (config.hasAppwrite) return AppwriteBackend(config);
  return MemoryBackend.seeded();
});

class ResolvedLine {
  const ResolvedLine({
    required this.line,
    required this.product,
    required this.variant,
    required this.soldOut,
  });

  final CartLine line;
  final Product product;
  final Variant variant;
  final bool soldOut;

  int get lineTotal => soldOut ? 0 : variant.price * line.qty;
}

class CartSummary {
  const CartSummary({
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.count,
    required this.hasSoldOut,
  });

  final List<ResolvedLine> lines;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final int count;
  final bool hasSoldOut;

  static const empty = CartSummary(
    lines: [],
    subtotal: 0,
    deliveryFee: 0,
    total: 0,
    count: 0,
    hasSoldOut: false,
  );
}

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final lines = ref.watch(cartProvider);
  final backend = ref.watch(backendProvider);
  final store = backend.store;
  final resolved = <ResolvedLine>[];
  var subtotal = 0;
  var count = 0;
  var soldOut = false;
  for (final line in lines) {
    final product = backend.productById(line.productId);
    final variant = backend.variantOf(line.productId, line.variantId);
    if (product == null || variant == null) continue;
    final unavailable = !product.forSale || !variant.isAvailable;
    if (unavailable) soldOut = true;
    resolved.add(
      ResolvedLine(
        line: line,
        product: product,
        variant: variant,
        soldOut: unavailable,
      ),
    );
    if (!unavailable) {
      subtotal += variant.price * line.qty;
      count += line.qty;
    }
  }
  final fee = deliveryFeeFor(
    subtotal,
    fee: store.deliveryFee,
    freeAbove: store.freeDeliveryAbove,
  );
  return CartSummary(
    lines: resolved,
    subtotal: subtotal,
    deliveryFee: fee,
    total: subtotal + fee,
    count: count,
    hasSoldOut: soldOut,
  );
});
