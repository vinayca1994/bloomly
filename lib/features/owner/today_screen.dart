import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'order_actions.dart';

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
    final low = backend.products
        .where((product) => !product.forSale)
        .take(6)
        .toList();
    final tokens = context.bloom;
    final desk = MediaQuery.sizeOf(context).width >= 1280;

    return ListView(
      padding: EdgeInsets.all(desk ? 32 : 20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Today',
                style: BloomlyType.display(28, color: tokens.text),
              ),
            ),
            Text(
              backend.store.etaLabel,
              style: BloomlyType.uiText(
                14,
                weight: FontWeight.w600,
                color: tokens.textSecondary,
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
        if (!desk)
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
              TextButton(
                onPressed: () => context.go('/owner/orders'),
                child: const Text('See all'),
              ),
            ],
          ),
        if (desk)
          _LiveOrdersTable(orders: live)
        else if (live.isEmpty)
          Text('No open orders', style: TextStyle(color: tokens.textSecondary))
        else
          for (final order in live.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BloomlyDecor.card(tokens),
                child: ListTile(
                  title: Text(
                    '${orderCustomer(order)} · ${money(order.total)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${order.items.length} items · ${paymentLabel(order)}',
                  ),
                  trailing: StatusPill(
                    status: orderStatusKey(order),
                    label: statusLabel(orderStatusKey(order)),
                  ),
                  onTap: () => context.go('/owner/orders'),
                ),
              ),
            ),
        if (!desk) ...[
          const SizedBox(height: 12),
          Text(
            'LOW AVAILABILITY',
            style: BloomlyType.uiText(
              11,
              weight: FontWeight.w800,
              color: tokens.textSecondary,
            ),
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
                            style: TextStyle(
                              color: tokens.danger,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onTap: () =>
                              context.go('/owner/catalog/${product.id}'),
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
              Text(
                label == 'Awaiting' ? 'UPI to confirm' : 'Today',
                style: TextStyle(color: accent, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveOrdersTable extends ConsumerWidget {
  const _LiveOrdersTable({required this.orders});

  final List<OrderRecord> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.bloom;
    return DecoratedBox(
      decoration: BloomlyDecor.card(tokens, radius: BloomTokens.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Text(
                  'Live orders',
                  style: BloomlyType.display(20, color: tokens.text),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/owner/orders'),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1.6),
              5: FlexColumnWidth(1.8),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: tokens.border)),
                ),
                children: [
                  for (final label in [
                    'Order',
                    'Customer',
                    'Items',
                    'Total',
                    'Status',
                    '',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        label.toUpperCase(),
                        style: BloomlyType.uiText(
                          11,
                          weight: FontWeight.w800,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              if (orders.isEmpty)
                TableRow(
                  children: [
                    for (var i = 0; i < 6; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Text(
                          i == 0 ? 'No open orders' : '',
                          style: TextStyle(color: tokens.textSecondary),
                        ),
                      ),
                  ],
                ),
              for (final order in orders)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: tokens.border)),
                  ),
                  children: [
                    _cell(
                      Text(
                        '#${order.id}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _cell(Text(orderCustomer(order))),
                    _cell(Text('${order.items.length} items')),
                    _cell(
                      Text(
                        money(order.total),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _cell(
                      StatusPill(
                        status: orderStatusKey(order),
                        label: statusLabel(orderStatusKey(order)),
                      ),
                    ),
                    _cell(_rowAction(context, ref, order)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: child,
    );
  }

  Widget _rowAction(BuildContext context, WidgetRef ref, OrderRecord order) {
    final actions = orderActions(context, ref, order);
    if (actions.isEmpty) return const SizedBox.shrink();
    final primary = actions.first;
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final button = order.awaitingPayment
        ? FilledButton(
            style: style,
            onPressed: primary.$2,
            child: Text(primary.$1),
          )
        : FilledButton.tonal(
            style: style,
            onPressed: primary.$2,
            child: Text(primary.$1),
          );
    return Align(alignment: Alignment.centerLeft, child: button);
  }
}
