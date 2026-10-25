import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final now = DateTime.now();
    final live = backend.orders.where((order) {
      final visible =
          OrderStatus.visibleToStore(order.status) ||
          (order.paymentMethod == PaymentMethod.upi && order.awaitingPayment);
      return visible &&
          order.status != OrderStatus.delivered &&
          order.status != OrderStatus.cancelled;
    }).toList()..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    final awaiting = live.where((order) => order.awaitingPayment).length;
    final revenue = backend.orders
        .where((order) => order.countsAsRevenue(now))
        .fold<int>(0, (sum, order) => sum + order.total);
    final todayCount = backend.orders.where((order) {
      final placed = order.placedAt.toLocal();
      final day = now.toLocal();
      return placed.year == day.year &&
          placed.month == day.month &&
          placed.day == day.day &&
          order.status != OrderStatus.paymentPending;
    }).length;
    final low = backend.products.where((product) => !product.forSale).take(6).toList();
    final tokens = context.bloom;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Today', style: BloomlyType.display(28, color: tokens.text)),
            ),
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.etaBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                backend.store.etaLabel,
                style: BloomlyType.uiText(12, weight: FontWeight.w800, color: tokens.etaFg),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat(context, 'Orders today', '$todayCount', tokens.success),
            _stat(context, 'Sales', money(revenue), tokens.success),
            _stat(context, 'Awaiting', '$awaiting', tokens.warning),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'LIVE ORDERS',
              style: BloomlyType.uiText(
                11,
                weight: FontWeight.w800,
                color: tokens.textSecondary,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: () => context.go('/owner/orders'), child: const Text('See all')),
          ],
        ),
        if (live.isEmpty)
          Text('No open orders', style: TextStyle(color: tokens.textSecondary))
        else
          for (final order in live.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BloomlyDecor.card(tokens),
                child: ListTile(
                  title: Text(
                    '${order.addressSnapshot.split(',').first} · ${money(order.total)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${order.items.length} items · ${paymentLabel(order)}',
                  ),
                  trailing: StatusPill(
                    status: order.awaitingPayment ? OrderStatus.paymentPending : order.status,
                    label: statusLabel(
                      order.awaitingPayment ? OrderStatus.paymentPending : order.status,
                    ),
                  ),
                  onTap: () => context.go('/owner/orders'),
                ),
              ),
            ),
        const SizedBox(height: 12),
        Text(
          'LOW AVAILABILITY',
          style: BloomlyType.uiText(11, weight: FontWeight.w800, color: tokens.textSecondary),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BloomlyDecor.card(tokens),
          child: low.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Everything on the shelf is available.',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                )
              : Column(
                  children: [
                    for (final product in low)
                      ListTile(
                        title: Text(product.name),
                        trailing: Text(
                          'Sold out',
                          style: TextStyle(color: tokens.danger, fontWeight: FontWeight.w800),
                        ),
                        onTap: () => context.go('/owner/catalog/${product.id}'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.go('/owner/settings'),
          child: const Text('Store settings'),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color accent) {
    final tokens = context.bloom;
    return SizedBox(
      width: 180,
      child: DecoratedBox(
        decoration: BloomlyDecor.card(tokens),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: tokens.textSecondary)),
              const SizedBox(height: 6),
              Text(value, style: BloomlyType.display(22, color: tokens.text)),
              const SizedBox(height: 4),
              Text(label == 'Awaiting' ? 'UPI to confirm' : 'Today', style: TextStyle(color: accent, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
