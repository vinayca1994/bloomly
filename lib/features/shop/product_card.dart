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

/// Height of a product card in a rail or a two-column grid.
const productCardExtent = 200.0;

class ProductCard extends ConsumerWidget {
  const ProductCard({required this.product, this.compact = false, super.key});

  final Product product;

  /// Kept so existing rails can ask for the dense card. The layout is the same.
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
    final unit = multiple ? '${product.variants.length} options' : lead.label;

    return Semantics(
      button: true,
      label: soldOut
          ? '${product.name}, sold out'
          : '${product.name}, $priceLabel',
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(BloomTokens.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: soldOut ? null : () => _add(context, ref),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColoredBox(
                color: tokens.sunken,
                child: SizedBox(
                  height: 100,
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
                          left: 6,
                          top: 6,
                          child: _Badge(
                            label: 'Sold out',
                            background: tokens.inverse,
                            foreground: tokens.textInverse,
                          ),
                        )
                      else if (off > 0)
                        Positioned(
                          left: 6,
                          top: 6,
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
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BloomlyType.uiText(
                        13,
                        weight: FontWeight.w600,
                        color: soldOut ? tokens.textSecondary : tokens.text,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BloomlyType.uiText(
                        11,
                        color: tokens.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          money(lead.price),
                          style: BloomlyType.uiText(
                            14,
                            weight: FontWeight.w800,
                            color: tokens.text,
                            height: 1.1,
                          ),
                        ),
                        if (off > 0) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              money(lead.mrp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BloomlyType.uiText(
                                11,
                                color: tokens.textSecondary,
                                height: 1.1,
                              ).copyWith(decoration: TextDecoration.lineThrough),
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
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, int qty) {
    final multiple = product.variants.length > 1;
    final Widget control;
    if (qty <= 0) {
      control = _AddButton(
        options: multiple ? product.variants.length : 0,
        onTap: () => _add(context, ref),
      );
    } else if (multiple) {
      control = QtyStepper(
        qty: qty,
        fitted: true,
        onMinus: () => ref.read(cartProvider.notifier).removeOne(product.id),
        onPlus: () => showVariantSheet(context, product),
      );
    } else {
      final variant = product.variants.first;
      control = QtyStepper(
        qty: qty,
        fitted: true,
        onMinus: () => ref
            .read(cartProvider.notifier)
            .setQty(product.id, variant.id, qty - 1),
        onPlus: () =>
            ref.read(cartProvider.notifier).addOne(product.id, variant.id),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: SizedBox(key: ValueKey(qty <= 0), width: 72, child: control),
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
        persist: false,
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
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: BloomlyType.uiText(
          10,
          weight: FontWeight.w800,
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.options});

  final VoidCallback onTap;
  final int options;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final label = options > 1 ? '$options options' : 'ADD';
    return Semantics(
      button: true,
      label: options > 1 ? '$options options' : 'Add to cart',
      child: Material(
        color: tokens.surface,
        elevation: 1,
        shadowColor: tokens.text.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.primary, width: 1),
            ),
            child: Text(
              label,
              style: BloomlyType.uiText(
                options > 1 ? 10 : 12,
                weight: FontWeight.w800,
                color: tokens.primary,
                height: 1,
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
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('We will note that $name is sold out.')),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 28,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderStrong),
            ),
            child: Text(
              'Notify',
              style: BloomlyType.uiText(
                11,
                weight: FontWeight.w800,
                color: tokens.link,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
