import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../orders/review_panel.dart';

class OwnerOrdersScreen extends ConsumerWidget {
  const OwnerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final orders = [
      ...backend.orders.where(
        (order) =>
            OrderStatus.visibleToStore(order.status) ||
            (order.paymentMethod == PaymentMethod.upi && order.awaitingPayment),
      ),
    ]..sort((a, b) => b.placedAt.compareTo(a.placedAt));
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
                const SizedBox(height: 4),
                Text(paymentLabel(order), style: const TextStyle(color: BloomlyColors.muted)),
                if (order.riderName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Rider · ${order.riderName}'),
                ],
                if (backend.reviewFor(order.id) != null) ...[
                  const SizedBox(height: 8),
                  ReviewPanel(order: order),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (order.gatewayPaymentId.isNotEmpty)
                      Text(
                        'UPI reference ${order.gatewayPaymentId} · ${money(order.total)}',
                        style: const TextStyle(color: BloomlyColors.muted),
                      ),
                    if (order.paymentMethod == PaymentMethod.upi && order.awaitingPayment)
                      FilledButton(
                        onPressed: () => _run(context, backend.confirmUpiPayment(order.id)),
                        child: Text('Payment received · ${money(order.total)}'),
                      ),
                    if (next == OrderStatus.outForDelivery)
                      FilledButton(
                        onPressed: () => _sendWithRider(context, ref, order),
                        child: Text(order.riderId.isEmpty ? 'Out for delivery' : 'Change rider'),
                      )
                    else if (next != null)
                      FilledButton(
                        onPressed: () => _run(context, backend.updateOrderStatus(order.id, next)),
                        child: Text(nextStatusAction(order.status)),
                      ),
                    if (order.status == OrderStatus.outForDelivery)
                      OutlinedButton(
                        onPressed: () => _sendWithRider(context, ref, order),
                        child: const Text('Change rider'),
                      ),
                    if (order.paymentStatus == PaymentStatus.refundPending)
                      OutlinedButton(
                        onPressed: () => _run(context, backend.markRefunded(order.id)),
                        child: const Text('Refund sent'),
                      ),
                    if (OrderStatus.canCancel(order.status))
                      OutlinedButton(
                        onPressed: () => _run(context, backend.cancelOrder(order.id)),
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

Future<void> _run(BuildContext context, Future<String?> action) async {
  final error = await action;
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

Future<void> _sendWithRider(BuildContext context, WidgetRef ref, OrderRecord order) async {
  final backend = ref.read(backendProvider);
  final riders = backend.riders;
  if (riders.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add a rider before sending the order out.')),
    );
    context.go('/owner/riders');
    return;
  }
  final picked = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Choose a rider')),
          for (final rider in riders)
            ListTile(
              title: Text(rider.name),
              subtitle: Text(rider.email.isEmpty ? 'Rider' : rider.email),
              onTap: () => Navigator.pop(context, rider.id),
            ),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  final error = await backend.assignRider(orderId: order.id, riderId: picked);
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}
