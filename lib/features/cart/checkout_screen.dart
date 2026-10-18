import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/cart_controller.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedId;
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final summary = ref.watch(cartSummaryProvider);
    final user = backend.currentUser;
    final addresses = user == null ? <Address>[] : backend.addressesFor(user.id);
    _selectedId ??= addresses.where((item) => item.isDefault).firstOrNull?.id ??
        addresses.firstOrNull?.id;
    final selected = addresses.where((item) => item.id == _selectedId).firstOrNull;
    final outside = selected != null &&
        selected.city.trim().toLowerCase() !=
            backend.store.city.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Deliver to',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (user == null)
            const Text(
              'Sign in to choose an address.',
              style: TextStyle(color: BloomlyColors.muted),
            )
          else if (addresses.isEmpty)
            const Text(
              'Add an address to place the order.',
              style: TextStyle(color: BloomlyColors.muted),
            )
          else
            RadioGroup<String>(
              groupValue: _selectedId,
              onChanged: (value) => setState(() => _selectedId = value),
              child: Column(
                children: [
                  for (final address in addresses)
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: address.id == _selectedId
                              ? BloomlyColors.green
                              : BloomlyColors.line,
                        ),
                      ),
                      child: RadioListTile<String>(
                        value: address.id,
                        title: Text(
                          address.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(address.snapshot),
                      ),
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                if (user == null) {
                  context.push(
                    '/login?next=${Uri.encodeComponent('/account/addresses')}',
                  );
                } else {
                  context.push('/account/addresses');
                }
              },
              child: const Text('Add address'),
            ),
          ),
          if (outside)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'This address is outside the delivery area.',
                style: TextStyle(color: BloomlyColors.danger, fontWeight: FontWeight.w600),
              ),
            ),
          const Text(
            'Payment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.payments_outlined, color: BloomlyColors.green),
              title: Text('Cash on delivery'),
              subtitle: Text('Pay when the order arrives'),
              trailing: Icon(Icons.check_circle, color: BloomlyColors.green),
            ),
          ),
          const SizedBox(height: 16),
          _line('Item total', money(summary.subtotal)),
          _line(
            'Delivery fee',
            summary.deliveryFee == 0 ? 'Free' : money(summary.deliveryFee),
          ),
          _line('To pay', money(summary.total), strong: true),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: BloomlyColors.danger)),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _busy || summary.count == 0 || outside
              ? null
              : () => _place(user, selected),
          child: Text(_busy ? 'Placing order…' : 'Place order'),
        ),
      ),
    );
  }

  Future<void> _place(Profile? user, Address? address) async {
    if (user == null) {
      context.push('/login?next=${Uri.encodeComponent('/checkout')}');
      return;
    }
    if (address == null) {
      setState(() => _error = 'Add a delivery address first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final lines = ref.read(cartProvider);
      final order = await ref.read(backendProvider).placeOrder(
        userId: user.id,
        address: address,
        lines: lines,
      );
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      context.go('/orders/${order.id}');
    } on BloomlyException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not place the order.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _line(String label, String value, {bool strong = false}) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      fontSize: strong ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}
