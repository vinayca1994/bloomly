import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/bloom_icons.dart';
import '../../core/format.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../orders/review_panel.dart';

class RiderScreen extends ConsumerStatefulWidget {
  const RiderScreen({super.key});

  @override
  ConsumerState<RiderScreen> createState() => _RiderScreenState();
}

class _RiderScreenState extends ConsumerState<RiderScreen> {
  Timer? _pulse;
  String? _sharingOrderId;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pulse?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final user = backend.currentUser;
    final orders = [
      for (final order in backend.orders)
        if (user != null && order.riderId == user.id && _visible(order.status)) order,
    ]..sort((a, b) {
        if (a.status == b.status) return b.placedAt.compareTo(a.placedAt);
        if (a.status == OrderStatus.outForDelivery) return -1;
        return 1;
      });

    final tokens = context.bloom;
    final active = orders.where((order) => order.status == OrderStatus.outForDelivery).toList();
    final next = active.isEmpty ? null : active.first;
    final later = [
      for (final order in orders)
        if (next == null || order.id != next.id) order,
    ];
    final sharing = next != null && _sharingOrderId == next.id;
    final loadError = backend.ordersError;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            tooltip: 'Account',
            onPressed: () => context.push('/account'),
            icon: const Icon(BloomIcons.user),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: orders.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
                children: [
                  _Waiting(
                    title: loadError == null ? 'No orders assigned yet' : 'Couldn\'t load deliveries',
                    body: loadError == null
                        ? 'You\'ll see a delivery here when the store sends one.'
                        : 'Pull to try again.',
                    danger: loadError != null,
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (loadError != null || _error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        loadError ?? _error!,
                        style: TextStyle(color: tokens.danger),
                      ),
                    ),
                  if (next == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'No delivery in progress',
                        style: BloomlyType.uiText(14, color: tokens.textSecondary),
                      ),
                    ),
                  if (next != null) ...[
                    DecoratedBox(
                      decoration: BloomlyDecor.card(tokens, border: false),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Next delivery',
                                  style: BloomlyType.uiText(
                                    12,
                                    weight: FontWeight.w700,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                StatusPill(status: next.status, label: statusLabel(next.status)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '#${next.id}',
                              style: BloomlyType.display(22, color: tokens.text),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              next.addressSnapshot,
                              style: BloomlyType.uiText(14, color: tokens.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              next.items.isEmpty
                                  ? 'Items are not on this order yet.'
                                  : next.items
                                        .map((item) => '${item.name} × ${item.qty}')
                                        .join(', '),
                            ),
                            const SizedBox(height: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: tokens.secondary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  _collectLabel(next),
                                  style: BloomlyType.uiText(
                                    13,
                                    weight: FontWeight.w800,
                                    color: tokens.onSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DutyActions(order: next),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BloomlyDecor.card(tokens),
                      child: SwitchListTile(
                        title: const Text('Sharing live location'),
                        subtitle: Text(
                          sharing
                              ? 'Customer sees you on the map'
                              : 'Start sharing when you leave',
                          style: TextStyle(color: tokens.textSecondary),
                        ),
                        value: sharing,
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value) {
                                  _start(next.id);
                                } else {
                                  _stop();
                                }
                              },
                      ),
                    ),
                  ],
                  if (later.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Finished',
                      style: BloomlyType.uiText(
                        12,
                        weight: FontWeight.w700,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final order in later) ...[
                      DecoratedBox(
                        decoration: BloomlyDecor.card(tokens),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '#${order.id}',
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  StatusPill(
                                    status: order.status,
                                    label: statusLabel(order.status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(order.addressSnapshot),
                              if (backend.reviewFor(order.id) case final review?) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Your review',
                                  style: BloomlyType.display(16, color: tokens.text),
                                ),
                                RiderScoreList(review: review),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
      ),
      bottomNavigationBar: next == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _deliver(next.id),
                  icon: const Icon(BloomIcons.check),
                  label: const Text('Mark delivered'),
                ),
              ),
            ),
    );
  }

  bool _visible(String status) {
    return status == OrderStatus.outForDelivery || status == OrderStatus.delivered;
  }

  Future<void> _refresh() => ref.read(backendProvider).refreshOrders();

  Future<void> _start(String orderId) async {
    _pulse?.cancel();
    setState(() {
      _sharingOrderId = orderId;
      _error = null;
    });
    await _ping(orderId);
    _pulse = Timer.periodic(const Duration(seconds: 10), (_) => _ping(orderId));
  }

  void _stop() {
    _pulse?.cancel();
    _pulse = null;
    if (mounted) setState(() => _sharingOrderId = null);
  }

  Future<void> _ping(String orderId) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _stop();
        if (mounted) setState(() => _error = 'Allow location to share this delivery.');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final error = await ref.read(backendProvider).updateRiderLocation(
        orderId: orderId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() => _error = error);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Location is not available.');
    }
  }

  Future<void> _deliver(String orderId) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(backendProvider).markDelivered(orderId);
    if (!mounted) return;
    if (_sharingOrderId == orderId) _stop();
    setState(() {
      _busy = false;
      _error = error;
    });
  }
}

String _collectLabel(OrderRecord order) {
  final cashDue =
      order.paymentMethod == PaymentMethod.cod && order.paymentStatus != PaymentStatus.paid;
  if (cashDue) return 'Collect ${money(order.total)} cash';
  return 'Paid online';
}

Uri _mapsUri(OrderRecord order) {
  final lat = order.destLatitude;
  final lng = order.destLongitude;
  final destination = lat != null && lng != null ? '$lat,$lng' : order.addressSnapshot;
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': destination,
  });
}

class _DutyActions extends StatelessWidget {
  const _DutyActions({required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final call = PhoneNumber.telUri(order.customerPhone);
    return Row(
      children: [
        if (call != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(call),
              icon: const Icon(BloomIcons.phone),
              label: const Text('Call'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => launchUrl(_mapsUri(order), mode: LaunchMode.externalApplication),
            icon: const Icon(BloomIcons.navigation),
            label: const Text('Open in maps'),
          ),
        ),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.title, required this.body, required this.danger});

  final String title;
  final String body;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: tokens.washVeg, shape: BoxShape.circle),
          child: Icon(BloomIcons.moped, color: danger ? tokens.danger : tokens.link),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: BloomlyType.display(26, color: danger ? tokens.danger : tokens.text),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}
