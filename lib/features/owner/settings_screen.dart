import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../core/upi.dart';
import '../../data/cart_controller.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../core/bloom_icons.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _city;
  late final TextEditingController _eta;
  late final TextEditingController _fee;
  late final TextEditingController _free;
  late final TextEditingController _upiId;
  late final TextEditingController _upiName;
  late final TextEditingController _storePhone;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    final store = StoreSettings.fallback;
    _city = TextEditingController(text: store.city);
    _eta = TextEditingController(text: store.etaLabel);
    _fee = TextEditingController(text: '${store.deliveryFee}');
    _free = TextEditingController(text: '${store.freeDeliveryAbove}');
    _upiId = TextEditingController(text: store.upiId);
    _upiName = TextEditingController(text: store.upiName);
    _storePhone = TextEditingController(text: store.storePhone);
  }

  @override
  void dispose() {
    _city.dispose();
    _eta.dispose();
    _fee.dispose();
    _free.dispose();
    _upiId.dispose();
    _upiName.dispose();
    _storePhone.dispose();
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
      _upiId.text = backend.store.upiId;
      _upiName.text = backend.store.upiName;
      _storePhone.text = backend.store.storePhone;
    }
    final tokens = context.bloom;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('Settings', style: BloomlyType.display(28, color: tokens.text)),
        const SizedBox(height: 16),
        _group(tokens, 'Store', [
          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          TextField(
            controller: _eta,
            decoration: const InputDecoration(labelText: 'Delivery time shown'),
          ),
          TextField(
            controller: _storePhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Store phone',
              hintText: '10-digit mobile',
            ),
          ),
        ]),
        _group(tokens, 'Payments', [
          TextField(
            controller: _upiId,
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'bloom@oksbi',
            ),
          ),
          TextField(
            controller: _upiName,
            decoration: const InputDecoration(labelText: 'Name on the UPI account'),
          ),
          TextField(
            controller: _fee,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Delivery fee (₹)'),
          ),
          TextField(
            controller: _free,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Free delivery above (₹)'),
          ),
        ]),
        _group(tokens, 'Team', [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(BloomIcons.moped, color: tokens.text),
            title: const Text('Riders'),
            trailing: Icon(BloomIcons.caretRight, color: tokens.textSecondary),
            onTap: () => context.go('/owner/riders'),
          ),
        ]),
        if (_message != null) ...[
          SizedBox(height: 8),
          Text(
            _message!,
            style: TextStyle(
              color: _messageIsError
                  ? context.bloom.danger
                  : context.bloom.link,
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
            onPressed: () async {
              final fee = int.tryParse(_fee.text.trim());
              final free = int.tryParse(_free.text.trim());
              final upiId = _upiId.text.trim();
              if (_city.text.trim().isEmpty ||
                  fee == null ||
                  free == null ||
                  fee < 0 ||
                  free < 0) {
                setState(() {
                  _message = 'Check the city and the two amounts.';
                  _messageIsError = true;
                });
                return;
              }
              if (upiId.isNotEmpty && !isUpiId(upiId)) {
                setState(() {
                  _message = 'Use a UPI ID like bloom@oksbi.';
                  _messageIsError = true;
                });
                return;
              }
              final phoneRaw = _storePhone.text.trim();
              if (phoneRaw.isNotEmpty &&
                  PhoneNumber.normalizeIndia(phoneRaw) == null) {
                setState(() {
                  _message =
                      'Use a valid 10-digit Indian mobile for the store phone.';
                  _messageIsError = true;
                });
                return;
              }
              await backend.updateStore(
                StoreSettings(
                  city: _city.text.trim(),
                  etaLabel: _eta.text.trim().isEmpty
                      ? '15–30 min'
                      : _eta.text.trim(),
                  deliveryFee: fee,
                  freeDeliveryAbove: free,
                  upiId: upiId,
                  upiName: _upiName.text.trim().isEmpty
                      ? 'Bloom'
                      : _upiName.text.trim(),
                  storePhone: phoneRaw.isEmpty
                      ? ''
                      : PhoneNumber.normalizeIndia(phoneRaw)!,
                  promotions: backend.store.promotions,
                ),
              );
              if (mounted) {
                setState(() {
                  _message = 'Saved';
                  _messageIsError = false;
                });
              }
            },
            child: const Text('Save store settings'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            final error = await backend.signOut();
            if (error == null) {
              ref.read(cartProvider.notifier).clear();
              if (context.mounted) context.go('/');
            } else if (context.mounted) {
              setState(() {
                _message = error;
                _messageIsError = true;
              });
            }
          },
          child: Text('Sign out', style: TextStyle(color: tokens.danger)),
        ),
      ],
    );
  }

  Widget _group(BloomTokens tokens, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: BloomlyType.uiText(
                12,
                weight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BloomlyDecor.card(tokens),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  for (final child in children) ...[
                    child,
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
