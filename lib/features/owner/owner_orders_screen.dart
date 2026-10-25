import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../orders/review_panel.dart';
import 'order_actions.dart';

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
    bool matches(OrderRecord order) {
      if (needle.isEmpty) return true;
      final blob = '${order.id} ${order.addressSnapshot} ${order.items.map((item) => item.name).join(' ')}'
          .toLowerCase();
      return blob.contains(needle);
    }

    final searched = orders.where(matches).toList();
    final desk = MediaQuery.sizeOf(context).width >= 1280;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(desk ? 32 : 16, desk ? 24 : 8, desk ? 32 : 16, 0),
          child: desk
              ? Row(
                  children: [
                    Text('Orders', style: BloomlyType.display(28, color: tokens.text)),
                    const Spacer(),
                    SizedBox(width: 280, child: _searchField()),
                  ],
                )
              : _searchField(),
        ),
        if (!desk)
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
          child: desk
              ? _OrdersBoard(orders: searched, columns: tabs.where((tab) => tab.$1 != 'done').toList())
              : _phoneList(searched, tabs, tokens),
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _query,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        hintText: 'Search orders',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  Widget _phoneList(
    List<OrderRecord> searched,
    List<(String, String, bool Function(OrderRecord))> tabs,
    BloomTokens tokens,
  ) {
    final tab = tabs.firstWhere((item) => item.$1 == _tab);
    final visible = searched.where(tab.$3).toList();
    if (visible.isEmpty) {
      return Center(
        child: Text(
          'No orders in this tab',
          style: TextStyle(color: tokens.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _OwnerOrderCard(order: visible[index]),
    );
  }
}

class _OrdersBoard extends StatelessWidget {
  const _OrdersBoard({required this.orders, required this.columns});

  final List<OrderRecord> orders;
  final List<(String, String, bool Function(OrderRecord))> columns;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final column in columns) ...[
            Expanded(child: _BoardColumn(title: column.$2, orders: orders.where(column.$3).toList())),
            if (column != columns.last) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({required this.title, required this.orders});

  final String title;
  final List<OrderRecord> orders;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final status = switch (title) {
      'Awaiting payment' => OrderStatus.paymentPending,
      'New' => OrderStatus.placed,
      'Packing' => OrderStatus.packing,
      _ => OrderStatus.outForDelivery,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(status: status, label: '$title · ${orders.length}'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: orders.isEmpty
              ? Text('None', style: TextStyle(color: tokens.textSecondary))
              : ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _BoardCard(order: orders[index]),
                ),
        ),
      ],
    );
  }
}

class _BoardCard extends ConsumerWidget {
  const _BoardCard({required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.bloom;
    final actions = orderActions(context, ref, order);
    final primary = actions.isEmpty ? null : actions.first;
    return DecoratedBox(
      decoration: BloomlyDecor.card(tokens),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(money(order.total), style: TextStyle(color: tokens.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${orderCustomer(order)} · ${order.items.length} items',
              style: TextStyle(color: tokens.textSecondary),
            ),
            if (primary != null) ...[
              const SizedBox(height: 10),
              _ActionButton(label: primary.$1, onPressed: primary.$2, filled: order.awaitingPayment),
            ],
          ],
        ),
      ),
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
    final actions = orderActions(context, ref, order);
    final primary = actions.isEmpty ? null : actions.first;
    final overflow = actions.length < 2 ? const <OrderAction>[] : actions.sublist(1);
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
                    child: _ActionButton(
                      label: primary.$1,
                      onPressed: primary.$2,
                      filled: order.awaitingPayment,
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
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed, required this.filled});

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(minimumSize: const Size.fromHeight(40));
    if (filled) {
      return FilledButton(style: style, onPressed: onPressed, child: Text(label));
    }
    return FilledButton.tonal(style: style, onPressed: onPressed, child: Text(label));
  }
}
