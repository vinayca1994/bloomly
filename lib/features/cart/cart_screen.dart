import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/cart_controller.dart';
import '../../data/catalog_seed.dart';
import '../../data/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final backend = ref.watch(backendProvider);
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
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: summary.lines.isEmpty
          ? const Center(
              key: Key('cart-empty'),
              child: Text(
                'Your cart is empty',
                style: TextStyle(color: BloomlyColors.muted, fontSize: 16),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final line in summary.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                                  emoji: emojiFor(line.product, backend.categories),
                                  kind: kindFor(line.product, backend.categories),
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
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    line.soldOut
                                        ? 'Sold out'
                                        : line.variant.label,
                                    style: TextStyle(
                                      color: line.soldOut
                                          ? BloomlyColors.danger
                                          : BloomlyColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    line.soldOut ? '' : money(line.lineTotal),
                                    key: Key('line-total-${line.variant.id}'),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            QtyStepper(
                              qty: line.line.qty,
                              minusKey: Key('minus-${line.variant.id}'),
                              plusKey: Key('plus-${line.variant.id}'),
                              onMinus: () => ref.read(cartProvider.notifier).setQty(
                                line.product.id,
                                line.variant.id,
                                line.line.qty - 1,
                              ),
                              onPlus: () => ref.read(cartProvider.notifier).addOne(
                                line.product.id,
                                line.variant.id,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _Bill(summary: summary),
              ],
            ),
      bottomNavigationBar: summary.lines.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: summary.hasSoldOut || summary.count == 0
                    ? null
                    : () => context.push('/checkout'),
                child: Text('Checkout · ${money(summary.total)}'),
              ),
            ),
    );
  }
}

class _Bill extends StatelessWidget {
  const _Bill({required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final feeLabel = summary.subtotal > 0 && summary.deliveryFee == 0
        ? 'Free'
        : money(summary.deliveryFee);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Item total', money(summary.subtotal)),
            const SizedBox(height: 8),
            _row('Delivery fee', feeLabel, key: const Key('delivery-fee')),
            const Divider(height: 24),
            _row('To pay', money(summary.total), key: const Key('to-pay'), strong: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Key? key, bool strong = false}) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      fontSize: strong ? 16 : 14,
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
