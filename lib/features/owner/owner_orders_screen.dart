import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class OwnerOrdersScreen extends ConsumerWidget {
  const OwnerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final orders = [...backend.orders]..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders yet', style: TextStyle(color: BloomlyColors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        final next = OrderStatus.next(order.status);
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusLabel(order.status),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(money(order.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formatWhen(order.placedAt), style: const TextStyle(color: BloomlyColors.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(order.addressSnapshot),
                const SizedBox(height: 6),
                Text(order.items.map((item) => '${item.name} × ${item.qty}').join(', ')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (next != null)
                      FilledButton(
                        onPressed: () => backend.updateOrderStatus(order.id, next),
                        child: Text(nextStatusAction(order.status)),
                      ),
                    if (OrderStatus.canCancel(order.status))
                      OutlinedButton(
                        onPressed: () => backend.updateOrderStatus(order.id, OrderStatus.cancelled),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
