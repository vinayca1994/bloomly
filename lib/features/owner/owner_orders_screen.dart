import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../orders/review_panel.dart';

class OwnerOrdersScreen extends ConsumerStatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen> {
  var _tab = 'new';
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final orders = [
      ...backend.orders.where(
        (order) =>
            OrderStatus.visibleToStore(order.status) ||
            (order.paymentMethod == PaymentMethod.upi && order.awaitingPayment),
      ),
    ]..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    final tokens = context.bloom;
    final tabs = <(String, String, bool Function(OrderRecord))>[
      ('awaiting', 'Awaiting payment', (order) => order.awaitingPayment),
      ('new', 'New', (order) => order.status == OrderStatus.placed),
      ('packing', 'Packing', (order) => order.status == OrderStatus.packing),
      ('out', 'Out', (order) => order.status == OrderStatus.outForDelivery),
      (
        'done',
        'Done',
        (order) =>
            order.status == OrderStatus.delivered ||
            order.status == OrderStatus.cancelled,
      ),
    ];
    final needle = _query.text.trim().toLowerCase();
    final visible = orders.where((order) {
      final tab = tabs.firstWhere((item) => item.$1 == _tab);
      if (!tab.$3(order)) return false;
      if (needle.isEmpty) return true;
      final blob = '${order.id} ${order.addressSnapshot} ${order.items.map((item) => item.name).join(' ')}'
          .toLowerCase();
      return blob.contains(needle);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search orders',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final tab in tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '${tab.$2} · ${orders.where(tab.$3).length}',
                    ),
                    selected: _tab == tab.$1,
                    onSelected: (_) => setState(() => _tab = tab.$1),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    'No orders in this tab',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _OwnerOrderCard(order: visible[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _OwnerOrderCard extends ConsumerWidget {
  const _OwnerOrderCard({required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final tokens = context.bloom;
    final actions = _actions(context, ref);
    final primary = actions.isEmpty ? null : actions.first;
    final overflow = actions.length < 2 ? const <(String, VoidCallback)>[] : actions.sublist(1);
    return DecoratedBox(
      decoration: BloomlyDecor.card(tokens),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(status: order.status, label: statusLabel(order.status)),
                const Spacer(),
                Text(
                  formatWhen(order.placedAt),
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.addressSnapshot.split(',').first} · ${money(order.total)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} items · ${paymentLabel(order)}',
              style: TextStyle(color: tokens.textSecondary),
            ),
            if (order.riderName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Rider · ${order.riderName}'),
            ],
            if (order.gatewayPaymentId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'UPI reference ${order.gatewayPaymentId}',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ],
            if (backend.reviewFor(order.id) != null) ReviewPanel(order: order),
            if (primary != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      onPressed: primary.$2,
                      child: Text(primary.$1),
                    ),
                  ),
                  if (overflow.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<int>(
                      tooltip: 'More actions',
                      itemBuilder: (context) => [
                        for (var i = 0; i < overflow.length; i++)
                          PopupMenuItem(value: i, child: Text(overflow[i].$1)),
                      ],
                      onSelected: (index) => overflow[index].$2(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<(String, VoidCallback)> _actions(BuildContext context, WidgetRef ref) {
    final backend = ref.read(backendProvider);
    final next = OrderStatus.next(order.status);
    final actions = <(String, VoidCallback)>[];
    if (order.paymentMethod == PaymentMethod.upi && order.awaitingPayment) {
      actions.add((
        'Confirm UPI received',
        () => _run(context, backend.confirmUpiPayment(order.id)),
      ));
    } else if (order.status == OrderStatus.packing) {
      actions.add((
        'Assign rider',
        () => _sendWithRider(context, ref, order),
      ));
    } else if (next != null) {
      actions.add((
        nextStatusAction(order.status),
        () => _run(context, backend.updateOrderStatus(order.id, next)),
      ));
    }
    if (order.status == OrderStatus.outForDelivery) {
      actions.add(('Change rider', () => _sendWithRider(context, ref, order)));
    }
    if (order.paymentStatus == PaymentStatus.refundPending) {
      actions.add(('Refund sent', () => _run(context, backend.markRefunded(order.id))));
    }
    if (OrderStatus.canCancel(order.status)) {
      actions.add(('Cancel', () => _run(context, backend.cancelOrder(order.id))));
    }
    return actions;
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
          const ListTile(title: Text('Assign a rider')),
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
