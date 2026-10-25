import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/cart_controller.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final user = backend.currentUser;
    final orders = user == null
        ? <OrderRecord>[]
        : backend.orders.where((order) => order.userId == user.id).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: user == null
          ? _Empty(
              icon: Icons.receipt_long_outlined,
              title: 'Sign in to see orders',
              body: 'Your placed orders stay with your account.',
              action: 'Sign in',
              onPressed: () => context.push('/login?next=/orders'),
            )
          : orders.isEmpty
          ? const _Empty(
              icon: Icons.shopping_basket_outlined,
              title: 'No orders yet',
              body:
                  'Vegetables, fruit, and flowers you order will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: orders.length,
              separatorBuilder: (_, _) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return DecoratedBox(
                  decoration: BloomlyDecor.card(context.bloom),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/orders/${order.id}'),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusPill(
                                  status: order.paymentStatus == PaymentStatus.submitted
                                      ? OrderStatus.paymentPending
                                      : order.status,
                                  label: customerStatusLabel(order),
                                ),
                                const Spacer(),
                                Text(
                                  money(order.total),
                                  style: BloomlyType.display(26),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              formatWhen(order.placedAt),
                              style: TextStyle(
                                color: context.bloom.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.items
                                  .map((item) => '${item.name} × ${item.qty}')
                                  .join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.bloom.text,
                                height: 1.3,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _reorder(context, ref, order),
                                child: const Text('Reorder'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
