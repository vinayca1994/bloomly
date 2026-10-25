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
            opacity: 1,
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
                            opacity: soldOut ? 0.4 : 1,
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
                          right: 4,
                          bottom: 4,
                          child: soldOut
                              ? _NotifyButton(name: product.name)
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
                        money(lead.price),
                        style: BloomlyType.uiText(
                          16,
                          weight: FontWeight.w800,
                          color: tokens.text,
                        ),
                      ),
                      if (off > 0)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                money(lead.mrp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BloomlyType.uiText(
                                  12,
                                  color: tokens.textSecondary,
                                ).copyWith(decoration: TextDecoration.lineThrough),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              color: tokens.discountBg,
                              child: Text(
                                '$off%',
                                style: BloomlyType.uiText(
                                  11,
                                  weight: FontWeight.w800,
                                  color: tokens.discountFg,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      Text(
                        multiple ? '${product.variants.length} options' : lead.label,
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
    final multiple = product.variants.length > 1;
    final width = compact ? 72.0 : 88.0;
    final Widget control;
    if (qty <= 0) {
      control = _AddButton(
        compact: compact,
        options: multiple ? product.variants.length : 0,
        onTap: () => _add(context, ref),
      );
    } else if (multiple) {
      control = QtyStepper(
        qty: qty,
        onMinus: () => ref.read(cartProvider.notifier).removeOne(product.id),
        onPlus: () => showVariantSheet(context, product),
      );
    } else {
      final variant = product.variants.first;
      control = QtyStepper(
        qty: qty,
        onMinus: () => ref
            .read(cartProvider.notifier)
            .setQty(product.id, variant.id, qty - 1),
        onPlus: () =>
            ref.read(cartProvider.notifier).addOne(product.id, variant.id),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: SizedBox(key: ValueKey(qty <= 0), width: width, child: control),
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
  const _AddButton({
    required this.onTap,
    required this.compact,
    required this.options,
  });

  final VoidCallback onTap;
  final bool compact;
  final int options;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final label = options > 1 ? '$options options' : 'ADD';
    return Semantics(
      button: true,
      label: options > 1 ? '$options options' : 'Add to cart',
      child: SizedBox(
        height: 44,
        child: Center(
          child: Material(
            color: tokens.surface,
            elevation: 0,
            shadowColor: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: compact ? 32 : 36,
                constraints: BoxConstraints(minWidth: compact ? 64 : 76),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.primary, width: 1.5),
                  boxShadow: tokens.cardShadow,
                ),
                child: Text(
                  label,
                  style: BloomlyType.uiText(
                    options > 1 ? 11 : 13,
                    weight: FontWeight.w800,
                    color: tokens.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotifyButton extends StatelessWidget {
  const _NotifyButton({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Semantics(
      button: true,
      label: 'Notify me',
      child: SizedBox(
        height: 44,
        child: Center(
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('We will note that $name is sold out.')),
              );
            },
            child: Text(
              'Notify me',
              style: BloomlyType.uiText(
                11,
                weight: FontWeight.w800,
                color: tokens.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
