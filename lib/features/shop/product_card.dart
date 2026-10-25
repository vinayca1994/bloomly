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
    ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final lead = product.lead;
    final qty = cart.qtyOfProduct(product.id);
    final off = percentOff(lead.price, lead.mrp);
    final multiple = product.variants.length > 1;
    final soldOut = !product.forSale || !lead.isAvailable;
    final tokens = context.bloom;
    final priceLabel = off > 0
        ? '${money(lead.price)}, was ${money(lead.mrp)}'
        : money(lead.price);

    return Semantics(
      button: true,
      label: soldOut
          ? '${product.name}, sold out'
          : '${product.name}, $priceLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(BloomTokens.radiusMd),
          onTap: soldOut ? null : () => _add(context, ref),
          child: Opacity(
            opacity: soldOut ? 0.72 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(BloomTokens.radiusMd),
                  child: SizedBox(
                    height: compact ? 112 : 128,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: soldOut ? 0.45 : 1,
                            child: ProductImage(
                              emoji: emojiFor(product, backend.categories),
                              kind: kindFor(product, backend.categories),
                              url: product.imageUrl,
                              bytes: backend.imageBytesFor(product.id),
                            ),
                          ),
                        ),
                        if (soldOut)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: _Badge(
                              label: 'Sold out',
                              background: tokens.inverse,
                              foreground: tokens.textInverse,
                            ),
                          )
                        else if (off > 0)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: _Badge(
                              label: '$off% off',
                              background: tokens.discountBg,
                              foreground: tokens.discountFg,
                            ),
                          ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: soldOut
                              ? const SizedBox.shrink()
                              : _action(context, ref, qty),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BloomlyType.uiText(
                          13,
                          weight: FontWeight.w800,
                          color: soldOut ? tokens.textSecondary : tokens.text,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        money(lead.price),
                        style: BloomlyType.uiText(
                          16,
                          weight: FontWeight.w800,
                          color: tokens.text,
                        ),
                      ),
                      if (off > 0)
                        Text(
                          money(lead.mrp),
                          style: BloomlyType.uiText(
                            12,
                            color: tokens.textSecondary,
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                      Text(
                        multiple ? '${lead.label} +' : lead.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BloomlyType.uiText(12, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, int qty) {
    if (qty <= 0) return _AddButton(onTap: () => _add(context, ref));
    final multiple = product.variants.length > 1;
    if (multiple) {
      return QtyStepper(
        qty: qty,
        onMinus: () => ref.read(cartProvider.notifier).removeOne(product.id),
        onPlus: () => showVariantSheet(context, product),
      );
    }
    final variant = product.variants.first;
    return QtyStepper(
      qty: qty,
      onMinus: () => ref
          .read(cartProvider.notifier)
          .setQty(product.id, variant.id, qty - 1),
      onPlus: () =>
          ref.read(cartProvider.notifier).addOne(product.id, variant.id),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    final before = ref.read(cartProvider.notifier).qtyOfProduct(product.id);
    if (product.variants.length > 1) {
      showVariantSheet(context, product);
      return;
    }
    ref
        .read(cartProvider.notifier)
        .addOne(product.id, product.variants.first.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${product.name} added'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final cart = ref.read(cartProvider.notifier);
            final now = cart.qtyOfProduct(product.id);
            if (now > before) cart.removeOne(product.id);
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: BloomlyType.uiText(11, weight: FontWeight.w800, color: foreground),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Semantics(
      button: true,
      label: 'Add to cart',
      child: Material(
        color: tokens.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 36,
            constraints: const BoxConstraints(minWidth: 76, minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tokens.borderFocus, width: 1.5),
              boxShadow: tokens.cardShadow,
            ),
            child: Text(
              'ADD',
              style: BloomlyType.uiText(
                13,
                weight: FontWeight.w800,
                color: tokens.link,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
