import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/cart_controller.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../core/bloom_icons.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final user = backend.currentUser;
    final orders = user == null
        ? <OrderRecord>[]
        : backend.orders.where((order) => order.userId == user.id).toList()
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    final open = orders.where(_isOpen).toList();
    final past = orders.where((order) => !_isOpen(order)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: user == null
          ? _Empty(
              icon: BloomIcons.receipt,
              title: 'Sign in to see orders',
              body: 'Your placed orders stay with your account.',
              action: 'Sign in',
              onPressed: () => context.push('/login?next=/orders'),
            )
          : orders.isEmpty
          ? const _Empty(
              icon: BloomIcons.basket,
              title: 'No orders yet',
              body:
                  'Vegetables, fruit, and flowers you order will show up here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                for (final order in open) ...[
                  _OpenOrder(
                    order: order,
                    eta: backend.store.etaLabel,
                    onOpen: () => context.push('/orders/${order.id}'),
                    onReorder: () => _reorder(context, ref, order),
                  ),
                  const SizedBox(height: 16),
                ],
                if (past.isNotEmpty) ...[
                  if (open.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Past orders',
                        style: BloomlyType.uiText(
                          12,
                          weight: FontWeight.w700,
                          color: context.bloom.textSecondary,
                        ),
                      ),
                    ),
                  for (final order in past) ...[
                    _PastOrder(
                      order: order,
                      onOpen: () => context.push('/orders/${order.id}'),
                      onReorder: () => _reorder(context, ref, order),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
    );
  }

  void _reorder(BuildContext context, WidgetRef ref, OrderRecord order) {
    final backend = ref.read(backendProvider);
    final cart = ref.read(cartProvider.notifier);
    for (final item in order.items) {
      final product = backend.productById(item.productId);
      if (product == null || !product.forSale) continue;
      final variant = product.variants
          .where((entry) => entry.label == item.variantLabel)
          .firstOrNull;
      if (variant == null) continue;
      cart.setQty(product.id, variant.id, item.qty);
    }
    context.go('/cart');
  }
}

bool _isOpen(OrderRecord order) {
  return order.status != OrderStatus.delivered &&
      order.status != OrderStatus.cancelled;
}

class _OpenOrder extends StatelessWidget {
  const _OpenOrder({
    required this.order,
    required this.eta,
    required this.onOpen,
    required this.onReorder,
  });

  final OrderRecord order;
  final String eta;
  final VoidCallback onOpen;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final headline = order.awaitingPayment ? 'Awaiting payment' : eta;
    return DecoratedBox(
      decoration: BloomlyDecor.card(tokens),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  status: order.paymentStatus == PaymentStatus.submitted
                      ? OrderStatus.paymentPending
                      : order.status,
                  label: customerStatusLabel(order),
                ),
                const SizedBox(height: 8),
                Text(
                  headline,
                  style: BloomlyType.display(28, color: tokens.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  order.items
                      .map((item) => '${item.name} × ${item.qty}')
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BloomlyType.uiText(14, color: tokens.text),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      money(order.total),
                      style: BloomlyType.uiText(
                        16,
                        weight: FontWeight.w800,
                        color: tokens.text,
                      ),
                    ),
                    const Spacer(),
                    TextButton(onPressed: onReorder, child: const Text('Reorder')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PastOrder extends StatelessWidget {
  const _PastOrder({
    required this.order,
    required this.onOpen,
    required this.onReorder,
  });

  final OrderRecord order;
  final VoidCallback onOpen;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerStatusLabel(order),
                      style: BloomlyType.uiText(
                        13,
                        weight: FontWeight.w800,
                        color: tokens.text,
                      ),
                    ),
                    Text(
                      formatWhen(order.placedAt),
                      style: BloomlyType.uiText(
                        12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    Text(
                      order.items.map((item) => item.name).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BloomlyType.uiText(13, color: tokens.text),
                    ),
                  ],
                ),
              ),
              Text(
                money(order.total),
                style: BloomlyType.uiText(
                  13,
                  weight: FontWeight.w800,
                  color: tokens.text,
                ),
              ),
              TextButton(onPressed: onReorder, child: const Text('Reorder')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.bloom.washVeg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.bloom.link),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BloomlyType.display(26),
            ),
            SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.bloom.textSecondary, height: 1.4),
            ),
            if (action != null) ...[
              SizedBox(height: 18),
              FilledButton(
                onPressed: onPressed,
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
