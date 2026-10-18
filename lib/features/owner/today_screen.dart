import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final TextEditingController _city;
  late final TextEditingController _eta;
  late final TextEditingController _fee;
  late final TextEditingController _free;
  String? _message;

  @override
  void initState() {
    super.initState();
    final store = StoreSettings.fallback;
    _city = TextEditingController(text: store.city);
    _eta = TextEditingController(text: store.etaLabel);
    _fee = TextEditingController(text: '${store.deliveryFee}');
    _free = TextEditingController(text: '${store.freeDeliveryAbove}');
  }

  @override
  void dispose() {
    _city.dispose();
    _eta.dispose();
    _fee.dispose();
    _free.dispose();
    super.dispose();
  }

  bool _filled = false;

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    if (!_filled) {
      _filled = true;
      _city.text = backend.store.city;
      _eta.text = backend.store.etaLabel;
      _fee.text = '${backend.store.deliveryFee}';
      _free.text = '${backend.store.freeDeliveryAbove}';
    }
    final now = DateTime.now();
    final open = backend.orders
        .where(
          (order) =>
              order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled,
        )
        .length;
    final revenue = backend.orders
        .where(
          (order) =>
              order.status != OrderStatus.cancelled && sameDay(order.placedAt, now),
        )
        .fold<int>(0, (sum, order) => sum + order.total);
    final unavailable = backend.products.where((product) => !product.isAvailable).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Today',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat('Open orders', '$open'),
            _stat('Revenue', money(revenue)),
            _stat('Unavailable', '$unavailable'),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Store',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
        const SizedBox(height: 8),
        TextField(controller: _eta, decoration: const InputDecoration(labelText: 'ETA label')),
        const SizedBox(height: 8),
        TextField(
          controller: _fee,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Delivery fee (₹)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _free,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Free delivery above (₹)'),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!, style: const TextStyle(color: BloomlyColors.greenDark)),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () async {
              final fee = int.tryParse(_fee.text.trim());
              final free = int.tryParse(_free.text.trim());
              if (_city.text.trim().isEmpty || fee == null || free == null || fee < 0 || free < 0) {
                setState(() => _message = 'Check the city and the two amounts.');
                return;
              }
              await backend.updateStore(
                StoreSettings(
                  city: _city.text.trim(),
                  etaLabel: _eta.text.trim().isEmpty ? '15–30 min' : _eta.text.trim(),
                  deliveryFee: fee,
                  freeDeliveryAbove: free,
                ),
              );
              if (mounted) setState(() => _message = 'Saved');
            },
            child: const Text('Save store settings'),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return SizedBox(
      width: 180,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: BloomlyColors.muted)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
