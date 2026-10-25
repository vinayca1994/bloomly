import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Deliveries')),
      body: orders.isEmpty
          ? const Center(child: Text('No deliveries yet', style: TextStyle(color: BloomlyColors.muted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length + (_error == null ? 0 : 1),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (_error != null && index == 0) {
                  return Text(_error!, style: const TextStyle(color: BloomlyColors.danger));
                }
                final order = orders[_error == null ? index : index - 1];
                final review = backend.reviewFor(order.id);
                final sharing = _sharingOrderId == order.id;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(statusLabel(order.status), style: const TextStyle(fontWeight: FontWeight.w800)),
                            const Spacer(),
                            Text(money(order.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(order.addressSnapshot),
                        const SizedBox(height: 6),
                        Text(order.items.map((item) => '${item.name} × ${item.qty}').join(', ')),
                        if (order.status == OrderStatus.outForDelivery) ...[
                          const SizedBox(height: 10),
                          if (sharing)
                            const Text('Sharing location', style: TextStyle(color: BloomlyColors.amber, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed: _busy ? null : () => sharing ? _stop() : _start(order.id),
                                child: Text(sharing ? 'Stop sharing' : 'Start delivery'),
                              ),
                              OutlinedButton(
                                onPressed: _busy ? null : () => _deliver(order.id),
                                child: const Text('Mark delivered'),
                              ),
                            ],
                          ),
                        ],
                        if (review != null) ...[
                          const SizedBox(height: 8),
                          Text('Your review', style: BloomlyType.display(16)),
                          RiderScoreList(review: review),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool _visible(String status) {
    return status == OrderStatus.outForDelivery || status == OrderStatus.delivered;
  }

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
