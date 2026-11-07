import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloom_icons.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/cart_controller.dart';
import '../../data/catalog_seed.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final backend = ref.watch(backendProvider);
    final detected = ref.watch(placeProvider).place;
    final user = backend.currentUser;
    final addresses = user == null
        ? const <Address>[]
        : backend.addressesFor(user.id);
    final address =
        addresses.where((item) => item.isDefault).firstOrNull ??
        addresses.firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(BloomIcons.arrowLeft),
        ),
      ),
      body: summary.lines.isEmpty
          ? const BloomEmpty(
              key: Key('cart-empty'),
              icon: BloomIcons.basket,
              title: 'Your cart is empty',
              body:
                  'Add vegetables, fruit, or flowers and they will wait here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _DeliverTo(
                  eta: backend.store.etaLabel,
                  address: address,
                  fallback: detected == null || detected.city.isEmpty
                      ? '${backend.store.city} · Set your address'
                      : (detected.area.isEmpty
                            ? detected.city
                            : '${detected.area}, ${detected.city}'),
                  onTap: () {
                    if (user == null) {
                      context.push(
                        '/login?next=${Uri.encodeComponent('/account/addresses')}',
                      );
                    } else {
                      context.push('/account/addresses');
                    }
                  },
                ),
                const SizedBox(height: 12),
                for (final line in summary.lines)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DecoratedBox(
                      decoration: BloomlyDecor.card(
                        context.bloom,
                        color: line.soldOut ? context.bloom.cancelledBg : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: ProductImage(
                                  emoji: emojiFor(
                                    line.product,
                                    backend.categories,
                                  ),
                                  kind: kindFor(
                                    line.product,
                                    backend.categories,
                                  ),
                                  url: line.product.imageUrl,
                                  bytes: backend.imageBytesFor(line.product.id),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.product.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    line.soldOut
                                        ? 'Sold out'
                                        : line.variant.label,
                                    style: TextStyle(
                                      color: line.soldOut
                                          ? context.bloom.danger
                                          : context.bloom.textSecondary,
                                      fontSize: 12,
                                      fontWeight: line.soldOut
                                          ? FontWeight.w800
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    line.soldOut ? '' : money(line.lineTotal),
                                    key: Key('line-total-${line.variant.id}'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (line.soldOut)
                              TextButton(
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .setQty(
                                      line.product.id,
                                      line.variant.id,
                                      0,
                                    ),
                                child: const Text('Remove'),
                              )
                            else
                              QtyStepper(
                                qty: line.line.qty,
                                minusKey: Key('minus-${line.variant.id}'),
                                plusKey: Key('plus-${line.variant.id}'),
                                onMinus: () => ref
                                    .read(cartProvider.notifier)
                                    .setQty(
                                      line.product.id,
                                      line.variant.id,
                                      line.line.qty - 1,
                                    ),
                                onPlus: () => ref
                                    .read(cartProvider.notifier)
                                    .addOne(line.product.id, line.variant.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _Bill(
                  summary: summary,
                  freeAbove: backend.store.freeDeliveryAbove,
                ),
              ],
            ),
      bottomNavigationBar: summary.lines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: summary.hasSoldOut || summary.count == 0
                      ? null
                      : () => context.push('/checkout'),
                  child: Text('Proceed · ${money(summary.total)}'),
                ),
              ),
            ),
    );
  }
}

class _DeliverTo extends StatelessWidget {
  const _DeliverTo({
    required this.eta,
    required this.fallback,
    required this.onTap,
    this.address,
  });

  final String eta;
  final String fallback;
  final VoidCallback onTap;
  final Address? address;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eta,
                      style: BloomlyType.display(22, color: tokens.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address?.label ?? 'Deliver to',
                      style: BloomlyType.uiText(
                        14,
                        weight: FontWeight.w800,
                        color: tokens.text,
                      ),
                    ),
                    Text(
                      address?.snapshot ?? fallback,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BloomlyType.uiText(
                        13,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(BloomIcons.caretRight, color: tokens.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bill extends StatelessWidget {
  const _Bill({required this.summary, required this.freeAbove});

  final CartSummary summary;
  final int freeAbove;

  @override
  Widget build(BuildContext context) {
    final feeLabel = summary.subtotal > 0 && summary.deliveryFee == 0
        ? 'Free'
        : money(summary.deliveryFee);
    final saved = summary.lines.fold<int>(0, (sum, line) {
      if (line.soldOut) return sum;
      final gap = line.variant.mrp - line.variant.price;
      return sum + (gap > 0 ? gap * line.line.qty : 0);
    });
    final tokens = context.bloom;
    return DecoratedBox(
      decoration: BloomlyDecor.card(tokens),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (summary.subtotal > 0 && freeAbove > 0) ...[
              FreeDeliveryBar(subtotal: summary.subtotal, freeAbove: freeAbove),
              const SizedBox(height: 12),
            ],
            _row(context, 'Item total', money(summary.subtotal)),
            const SizedBox(height: 8),
            _row(
              context,
              'Delivery fee',
              feeLabel,
              key: const Key('delivery-fee'),
            ),
            if (saved > 0) ...[
              const SizedBox(height: 8),
              _row(context, 'You save', money(saved), emphasis: tokens.success),
            ],
            Divider(height: 24, color: tokens.border),
            _row(
              context,
              'To pay',
              money(summary.total),
              key: Key('to-pay'),
              strong: true,
              emphasis: tokens.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Key? key,
    bool strong = false,
    Color? emphasis,
  }) {
    final tokens = context.bloom;
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      fontSize: strong ? 16 : 14,
      color: emphasis ?? (strong ? tokens.text : tokens.textSecondary),
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, key: key, style: style),
      ],
    );
  }
}
