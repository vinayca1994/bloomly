import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/cart_controller.dart';
import '../../data/catalog_seed.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'variant_sheet.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({required this.product, this.compact = false, super.key});

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final cart = ref.watch(cartProvider.notifier);
    final lead = product.lead;
    final qty = cart.qtyOfProduct(product.id);
    final off = percentOff(lead.price, lead.mrp);
    final multiple = product.variants.length > 1;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _add(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 108 : 124,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(
                      emoji: emojiFor(product, backend.categories),
                      kind: kindFor(product, backend.categories),
                      url: product.imageUrl,
                      bytes: backend.imageBytesFor(product.id),
                    ),
                  ),
                  if (off > 0)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: BloomlyColors.marigold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$off% off',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(right: 8, bottom: 8, child: _action(context, ref, qty)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: BloomlyColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    multiple ? '${lead.label} +' : lead.label,
                    style: const TextStyle(color: BloomlyColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        money(lead.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: BloomlyColors.ink,
                        ),
                      ),
                      if (off > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          money(lead.mrp),
                          style: const TextStyle(
                            color: BloomlyColors.muted,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, int qty) {
    if (qty <= 0 || product.variants.length > 1) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _add(context, ref),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 32,
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BloomlyColors.green),
            ),
            alignment: Alignment.center,
            child: Text(
              qty > 0 ? '$qty' : 'ADD',
              style: const TextStyle(
                color: BloomlyColors.greenDark,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }
    final variant = product.variants.first;
    return QtyStepper(
      qty: qty,
      onMinus: () => ref.read(cartProvider.notifier).setQty(
        product.id,
        variant.id,
        qty - 1,
      ),
      onPlus: () => ref.read(cartProvider.notifier).addOne(product.id, variant.id),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    if (product.variants.length > 1) {
      showVariantSheet(context, product);
      return;
    }
    ref.read(cartProvider.notifier).addOne(product.id, product.variants.first.id);
  }
}
