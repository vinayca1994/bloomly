import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/cart_controller.dart';
import '../../data/models.dart';

void showVariantSheet(BuildContext context, Product product) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.bloom.raised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _VariantSheet(product: product),
  );
}

class _VariantSheet extends ConsumerWidget {
  const _VariantSheet({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart *state* so rows rebuild when qty changes.
    ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: BloomlyType.display(24)),
            const SizedBox(height: 4),
            Text(
              'Choose a size',
              style: TextStyle(color: context.bloom.textSecondary),
            ),
            SizedBox(height: 12),
            for (final variant in product.variants) ...[
              _row(context, cart, variant),
              Divider(height: 1, color: context.bloom.border),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, CartController cart, Variant variant) {
    final qty = cart.qtyOf(product.id, variant.id);
    final off = percentOff(variant.price, variant.mrp);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      money(variant.price),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (off > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        money(variant.mrp),
                        style: TextStyle(
                          color: context.bloom.textSecondary,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (qty == 0)
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(72, 36)),
              onPressed: () => cart.addOne(product.id, variant.id),
              child: const Text('ADD'),
            )
          else
            QtyStepper(
              qty: qty,
              onMinus: () => cart.setQty(product.id, variant.id, qty - 1),
              onPlus: () => cart.addOne(product.id, variant.id),
            ),
        ],
      ),
    );
  }
}
