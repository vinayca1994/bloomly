import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/cart_controller.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'upi_sheet.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedId;
  String _payment = PaymentMethod.cod;
  bool _busy = false;
  String? _error;
  String? _checkoutKey;
  String? _checkoutFingerprint;

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
          Text('Deliver to', style: BloomlyType.display(24)),
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
                      color: BloomlyColors.card,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: address.id == _selectedId
                              ? BloomlyColors.ink
                              : BloomlyColors.line,
                          width: address.id == _selectedId ? 1.6 : 1,
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
          Text('Payment', style: BloomlyType.display(24)),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _payment,
            onChanged: (value) {
              if (value != null) setState(() => _payment = value);
            },
            child: Column(
              children: [
                _payTile(
                  value: PaymentMethod.cod,
                  icon: Icons.payments_outlined,
                  title: 'Cash on delivery',
                  subtitle: 'Pay when the order arrives',
                ),
                _payTile(
                  value: PaymentMethod.upi,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'UPI',
                  subtitle: backend.usesTestCheckout
                      ? 'Demo only, until the store adds a UPI ID. No bank is charged.'
                      : 'BHIM, GPay, PhonePe, or Paytm',
                ),
              ],
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
              : () => _payment == PaymentMethod.cod
                    ? _place(user, selected)
                    : _payOnline(user, selected),
          child: Text(
            _busy
                ? 'Please wait…'
                : _payment == PaymentMethod.cod
                ? 'Place order'
                : backend.usesTestCheckout
                ? 'Pay (demo)'
                : 'Pay with UPI',
          ),
        ),
      ),
    );
  }

  Widget _payTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _payment == value;
    return Card(
      color: BloomlyColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? BloomlyColors.ink : BloomlyColors.line,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        secondary: Icon(icon, color: BloomlyColors.ink),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Future<void> _payOnline(Profile? user, Address? address) async {
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
      final backend = ref.read(backendProvider);
      final lines = ref.read(cartProvider);
      final payment = await backend.startOnlinePayment(
        userId: user.id,
        address: address,
        lines: lines,
        idempotencyKey: _idempotency(address, lines),
      );
      if (!mounted) return;
      if (backend.usesTestCheckout) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('UPI demo'),
            content: Text('Mark ${money(payment.order.total)} as paid? No bank is charged until the store adds a UPI ID.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay')),
            ],
          ),
        );
        if (confirmed != true) {
          if (mounted) setState(() => _error = 'Payment cancelled.');
          return;
        }
        final error = await backend.completeTestPayment(payment.order.id);
        if (error != null) {
          if (mounted) setState(() => _error = error);
          return;
        }
        _finish(payment.order.id);
        return;
      }
      if (payment.payUri == null) {
        setState(() => _error = 'Add a valid store UPI ID before taking UPI payments.');
        return;
      }
      final reference = await showUpiPaymentSheet(context, payment: payment);
      if (!mounted) return;
      if (reference == null) {
        setState(() => _error = 'Payment cancelled.');
        return;
      }
      final error = await backend.noteUpiPayment(
        orderId: payment.order.id,
        reference: reference,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      _finish(payment.order.id);
    } on BloomlyException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not start the payment.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _idempotency(Address address, List<CartLine> lines) {
    final fingerprint = '${address.id}|$_payment|${[
      for (final line in lines) '${line.productId}:${line.variantId}:${line.qty}',
    ].join(',')}';
    if (_checkoutFingerprint != fingerprint || _checkoutKey == null) {
      _checkoutFingerprint = fingerprint;
      final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      final salt = Random().nextInt(0x7fffffff).toRadixString(36);
      final key = 'c$micros$salt';
      _checkoutKey = key.length <= 36 ? key : key.substring(0, 36);
    }
    return _checkoutKey!;
  }

  void _finish(String orderId) {
    ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    context.go('/orders/$orderId');
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
        idempotencyKey: _idempotency(address, lines),
      );
      _finish(order.id);
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
