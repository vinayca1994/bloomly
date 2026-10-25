import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../core/upi.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/online_payment.dart';
import '../../data/providers.dart';
import '../cart/upi_sheet.dart';
import 'delivery_map.dart';
import 'review_panel.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  StreamSubscription<OrderRecord?>? _subscription;
  String? _actionError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final backend = ref.read(backendProvider);
    unawaited(backend.expireStaleUpiOrders());
    _subscription = backend.watchOrder(widget.orderId).listen((_) {
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
    final isCustomer = user != null && order != null && user.id == order.userId && !user.isOwner;

    final tokens = context.bloom;
    final (heroBg, heroFg) = order == null
        ? (tokens.canvas, tokens.text)
        : tokens.status(
            order.awaitingPayment ? OrderStatus.paymentPending : order.status,
          );
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: Text(order == null ? 'Order' : 'Order ${order.id}'),
      ),
      body: !allowed
          ? const Center(child: Text('This order is not available.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    color: heroBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(
                        status: order.awaitingPayment
                            ? OrderStatus.paymentPending
                            : order.status,
                        label: order.awaitingPayment
                            ? 'Awaiting payment'
                            : statusLabel(order.status),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _heroTitle(order, backend.store.etaLabel),
                        style: BloomlyType.display(32, color: heroFg),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${money(order.total)} · ${formatWhen(order.placedAt)}',
                        style: BloomlyType.uiText(14, color: heroFg.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.place_outlined, color: heroFg, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.addressSnapshot,
                              style: BloomlyType.uiText(14, color: heroFg, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Panel(
                  child: order.status == OrderStatus.cancelled
                      ? _Cancelled(
                          upiFailed: order.paymentMethod == PaymentMethod.upi &&
                              order.paymentStatus == PaymentStatus.failed,
                        )
                      : order.awaitingPayment
                      ? _AwaitingUpi(
                          order: order,
                          busy: _busy,
                          onEnterUtr: isCustomer ? () => _enterUtr(order) : null,
                          onOpenPay: isCustomer ? () => _openPayAgain(order) : null,
                        )
                      : _Steps(status: order.status),
                ),
                if (order.status == OrderStatus.outForDelivery) ...[
                  const SizedBox(height: 14),
                  if (order.riderName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${order.riderName} is on the way',
                        style: TextStyle(
                          color: context.bloom.link,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  DeliveryMap(
                    rider: backend.locationFor(order.id),
                    destLatitude: order.destLatitude,
                    destLongitude: order.destLongitude,
                  ),
                ],
                ReviewPanel(order: order),
                if (_actionError != null) ...[
                  SizedBox(height: 12),
                  Text(_actionError!, style: TextStyle(color: context.bloom.danger)),
                ],
                if (isCustomer && OrderStatus.customerCanCancel(order.status)) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _cancel(order),
                    child: const Text('Cancel order'),
                  ),
                ],
                if (backend.store.storePhone.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _StoreContact(phone: backend.store.storePhone, orderId: order.id),
                ],
                const SizedBox(height: 14),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items', style: BloomlyType.display(22)),
                      const SizedBox(height: 8),
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.bloom.washVeg,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${item.qty}',
                                  style: TextStyle(
                                    color: context.bloom.link,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${item.name} · ${item.variantLabel}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                money(item.lineTotal),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.bloom.washFruit,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 18, color: context.bloom.star),
                            const SizedBox(width: 8),
                            Expanded(child: Text(paymentLabel(order))),
                            Text(
                              money(order.total),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      if (order.gatewayPaymentId.trim().isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          'UTR / reference: ${order.gatewayPaymentId}',
                          style: TextStyle(color: context.bloom.textSecondary, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _cancel(OrderRecord order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('You can cancel only before the store starts packing.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel order')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    final error = await ref.read(backendProvider).cancelOrder(order.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _actionError = error;
    });
  }

  Future<void> _enterUtr(OrderRecord order) async {
    final controller = TextEditingController(text: order.gatewayPaymentId);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UPI reference'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'UTR / UPI reference',
            hintText: 'Optional letters and numbers',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    final cleaned = normalizeUpiReference(value);
    if (cleaned == null) {
      setState(() => _actionError = 'Enter the UPI reference as letters and numbers only.');
      return;
    }
    setState(() {
      _busy = true;
      _actionError = null;
    });
    final error = await ref.read(backendProvider).noteUpiPayment(
      orderId: order.id,
      reference: cleaned,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _actionError = error;
    });
  }

  Future<void> _openPayAgain(OrderRecord order) async {
    final backend = ref.read(backendProvider);
    final upiId = order.gatewayOrderId.trim().isNotEmpty
        ? order.gatewayOrderId.trim()
        : backend.store.upiId.trim();
    final payment = OnlinePayment(
      order: order,
      upiId: upiId,
      upiName: backend.store.upiName,
      amountRupees: order.total,
    );
    final reference = await showUpiPaymentSheet(context, payment: payment);
    if (reference == null || !mounted) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    final error = await backend.noteUpiPayment(orderId: order.id, reference: reference);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _actionError = error;
    });
  }
}

String _heroTitle(OrderRecord order, String eta) {
  if (order.status == OrderStatus.cancelled) return 'Cancelled';
  if (order.status == OrderStatus.delivered) return 'Delivered';
  if (order.awaitingPayment) return 'Awaiting payment';
  return eta;
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.bloom.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: context.bloom.cardShadow,
      ),
      child: child,
    );
  }
}

class _AwaitingUpi extends StatelessWidget {
  const _AwaitingUpi({
    required this.order,
    required this.busy,
    this.onEnterUtr,
    this.onOpenPay,
  });

  final OrderRecord order;
  final bool busy;
  final VoidCallback? onEnterUtr;
  final VoidCallback? onOpenPay;

  @override
  Widget build(BuildContext context) {
    final remaining = OrderRecord.upiPaymentTimeout - DateTime.now().difference(order.placedAt);
    final mins = remaining.isNegative ? 0 : remaining.inMinutes;
    final submitted = order.paymentStatus == PaymentStatus.submitted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bloom.awaitingBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            submitted
                ? 'Payment submitted — waiting for the store'
                : 'Awaiting UPI payment',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            submitted
                ? 'You marked this as paid. The store confirms the credit in their UPI app before packing. UTR: ${order.gatewayPaymentId.isEmpty ? 'not entered' : order.gatewayPaymentId}.'
                : 'Pay with BHIM, GPay, PhonePe, or Paytm, then save your UTR. This order expires in about $mins min if unpaid.',
            style: TextStyle(color: context.bloom.textSecondary),
          ),
          if (onOpenPay != null || onEnterUtr != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onOpenPay != null)
                  FilledButton(
                    onPressed: busy ? null : onOpenPay,
                    child: const Text('Open UPI again'),
                  ),
                if (onEnterUtr != null)
                  OutlinedButton(
                    onPressed: busy ? null : onEnterUtr,
                    child: Text(submitted ? 'Update UTR' : 'I have paid · add UTR'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StoreContact extends StatelessWidget {
  const _StoreContact({required this.phone, required this.orderId});

  final String phone;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final call = PhoneNumber.telUri(phone);
    final chat = PhoneNumber.whatsAppUri(phone, text: 'Hi, about Bloom order $orderId');
    if (call == null && chat == null) return const SizedBox.shrink();
    return Row(
      children: [
        if (call != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(call),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call store'),
            ),
          ),
        if (call != null && chat != null) const SizedBox(width: 8),
        if (chat != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(chat, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp'),
            ),
          ),
      ],
    );
  }
}

class _Cancelled extends StatelessWidget {
  const _Cancelled({this.upiFailed = false});

  final bool upiFailed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bloom.cancelledBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        upiFailed
            ? 'Cancelled — UPI was not confirmed in time (or was cancelled).'
            : 'Cancelled',
        style: TextStyle(
          color: context.bloom.danger,
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
    const icons = [
      Icons.receipt_long_outlined,
      Icons.inventory_2_outlined,
      Icons.delivery_dining_outlined,
      Icons.spa_outlined,
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= index ? context.bloom.primary : context.bloom.sunken,
                    ),
                    child: Icon(
                      i < index ? Icons.check_rounded : icons[i],
                      size: 16,
                      color: i <= index ? context.bloom.onPrimary : context.bloom.textSecondary,
                    ),
                  ),
                  if (i != OrderStatus.flow.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: i < index ? context.bloom.primary : context.bloom.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel(OrderStatus.flow[i]),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: i == index
                              ? context.bloom.link
                              : i < index
                              ? context.bloom.text
                              : context.bloom.textSecondary,
                        ),
                      ),
                      Text(
                        captions[i],
                        style: TextStyle(color: context.bloom.textSecondary, fontSize: 12),
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
