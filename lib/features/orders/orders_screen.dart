import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
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
          ? Center(
              child: FilledButton(
                onPressed: () => context.push('/login?next=/orders'),
                child: const Text('Sign in to see orders'),
              ),
            )
          : orders.isEmpty
          ? const Center(
              child: Text(
                'No orders yet',
                style: TextStyle(color: BloomlyColors.muted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/orders/${order.id}'),
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
                              Text(
                                money(order.total),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatWhen(order.placedAt),
                            style: const TextStyle(
                              color: BloomlyColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.items
                                .map((item) => '${item.name} × ${item.qty}')
                                .join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
