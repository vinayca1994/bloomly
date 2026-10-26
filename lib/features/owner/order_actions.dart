import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

typedef OrderAction = (String, VoidCallback);

/// One primary action, then overflow. Same rules on phone cards, the desktop
/// table, and the status board.
List<OrderAction> orderActions(BuildContext context, WidgetRef ref, OrderRecord order) {
  final backend = ref.read(backendProvider);
  final next = OrderStatus.next(order.status);
  final actions = <OrderAction>[];
  if (order.paymentMethod == PaymentMethod.upi && order.awaitingPayment) {
    actions.add((
      'Confirm UPI received',
      () => runOrderAction(context, backend.confirmUpiPayment(order.id)),
    ));
  } else if (order.status == OrderStatus.packing) {
    actions.add(('Assign rider', () => assignRider(context, ref, order)));
  } else if (next != null) {
    actions.add((
      nextStatusAction(order.status),
      () => runOrderAction(context, backend.updateOrderStatus(order.id, next)),
    ));
  }
  if (order.status == OrderStatus.outForDelivery) {
    actions.add(('Change rider', () => assignRider(context, ref, order)));
  }
  if (order.paymentStatus == PaymentStatus.refundPending) {
    actions.add(('Refund sent', () => runOrderAction(context, backend.markRefunded(order.id))));
  }
  if (OrderStatus.canCancel(order.status)) {
    actions.add(('Cancel', () => runOrderAction(context, backend.cancelOrder(order.id))));
  }
  return actions;
}

Future<void> runOrderAction(BuildContext context, Future<String?> action) async {
  final error = await action;
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

Future<void> assignRider(BuildContext context, WidgetRef ref, OrderRecord order) async {
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

String orderCustomer(OrderRecord order) {
  final line = order.addressSnapshot.split(',').first.trim();
  return line.isEmpty ? 'Customer' : line;
}

String orderStatusKey(OrderRecord order) =>
    order.awaitingPayment ? OrderStatus.paymentPending : order.status;
