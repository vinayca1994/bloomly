import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  StreamSubscription<OrderRecord?>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(backendProvider).watchOrder(widget.orderId).listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final order = backend.orderById(widget.orderId);
    final user = backend.currentUser;
    final allowed = order != null &&
        user != null &&
        (user.isOwner || order.userId == user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: !allowed
          ? const Center(child: Text('This order is not available.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(money(order.total), style: BloomlyType.display(36)),
                const SizedBox(height: 4),
                Text(
                  formatWhen(order.placedAt),
                  style: const TextStyle(color: BloomlyColors.muted),
                ),
                const SizedBox(height: 6),
                Text(order.addressSnapshot),
                const SizedBox(height: 20),
                if (order.status == OrderStatus.cancelled)
                  const _Cancelled()
                else if (order.awaitingPayment)
                  Text(
                    order.paymentStatus == PaymentStatus.submitted
                        ? 'UPI sent. The store confirms it in their app before packing.'
                        : 'Pay with UPI, then tap I have paid.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                else
                  _Steps(status: order.status),
                const SizedBox(height: 20),
                Text('Items', style: BloomlyType.display(22)),
                const SizedBox(height: 8),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.name} · ${item.variantLabel}'),
                        ),
                        Text('× ${item.qty}'),
                        const SizedBox(width: 12),
                        Text(
                          money(item.lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 28),
                Row(
                  children: [
                    Text(paymentLabel(order)),
                    const Spacer(),
                    Text(
                      money(order.total),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Cancelled extends StatelessWidget {
  const _Cancelled();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Cancelled',
        style: TextStyle(
          color: BloomlyColors.danger,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final index = OrderStatus.flow.indexOf(status);
    const captions = [
      'We got your order',
      'The store is packing your items',
      'On the way to you',
      'Enjoy the freshness',
    ];
    return Column(
      children: [
        for (var i = 0; i < OrderStatus.flow.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index
                          ? BloomlyColors.green
                          : i < index
                          ? BloomlyColors.ink
                          : BloomlyColors.paper,
                      border: Border.all(
                        color: i <= index ? BloomlyColors.ink : BloomlyColors.line,
                        width: 2,
                      ),
                    ),
                  ),
                  if (i != OrderStatus.flow.length - 1)
                    Container(
                      width: 2,
                      height: 36,
                      color: BloomlyColors.ink.withValues(alpha: i < index ? 1 : 0.25),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel(OrderStatus.flow[i]),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: i <= index ? BloomlyColors.ink : BloomlyColors.muted,
                        ),
                      ),
                      Text(
                        captions[i],
                        style: const TextStyle(color: BloomlyColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
