import '../core/bill.dart';
import 'backend.dart';
import 'models.dart';

class CartPrice {
  const CartPrice({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.items,
  });

  final int subtotal;
  final int deliveryFee;
  final int total;
  final List<OrderItem> items;
}

/// Prices a cart from the catalog. Line objects do not carry a client price.
CartPrice priceLines({
  required BloomlyBackend backend,
  required String orderId,
  required Address address,
  required List<CartLine> lines,
  required String Function() nextItemId,
}) {
  if (lines.isEmpty) throw BloomlyException('Your cart is empty.');
  if (address.city.trim().toLowerCase() != backend.store.city.trim().toLowerCase()) {
    throw BloomlyException('Bloomly delivers in ${backend.store.city} only.');
  }
  final items = <OrderItem>[];
  var subtotal = 0;
  for (final line in lines) {
    if (line.qty < 1) throw BloomlyException('Check the quantities in your cart.');
    final product = backend.productById(line.productId);
    final variant = backend.variantOf(line.productId, line.variantId);
    if (product == null || variant == null || !product.forSale || !variant.isAvailable) {
      throw BloomlyException(
        '${product?.name ?? 'An item'} is sold out. Remove it to continue.',
      );
    }
    subtotal += variant.price * line.qty;
    items.add(
      OrderItem(
        id: nextItemId(),
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
    fee: backend.store.deliveryFee,
    freeAbove: backend.store.freeDeliveryAbove,
  );
  return CartPrice(
    subtotal: subtotal,
    deliveryFee: fee,
    total: subtotal + fee,
    items: items,
  );
}
