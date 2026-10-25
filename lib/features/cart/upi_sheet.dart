import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/online_payment.dart';

/// Returns the UPI reference the customer typed, or null if they closed the sheet.
/// An empty string means they paid and did not enter a reference.
Future<String?> showUpiPaymentSheet(BuildContext context, {required OnlinePayment payment}) {
  final uri = payment.payUri;
  if (uri == null) return Future.value();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BloomlyColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _UpiSheet(payment: payment, uri: uri),
  );
}

class _UpiSheet extends StatefulWidget {
  const _UpiSheet({required this.payment, required this.uri});

  final OnlinePayment payment;
  final String uri;

  @override
  State<_UpiSheet> createState() => _UpiSheetState();
}

class _UpiSheetState extends State<_UpiSheet> {
  final _reference = TextEditingController();
  String? _hint;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BloomlyColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Pay ${money(widget.payment.amountRupees)}', style: BloomlyType.display(28)),
            const SizedBox(height: 6),
            Text(
              'Opens BHIM, GPay, PhonePe, or Paytm. Bloom never sees your UPI PIN.',
              style: const TextStyle(color: BloomlyColors.muted),
            ),
            const SizedBox(height: 16),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: QrImageView(
                    data: widget.uri,
                    size: 168,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.payment.upiId,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              widget.payment.upiName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BloomlyColors.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _openApp,
              child: const Text('Open UPI app'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.payment.upiId));
                if (mounted) setState(() => _hint = 'UPI ID copied.');
              },
              child: const Text('Copy UPI ID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reference,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'UPI reference, if you have it',
                hintText: 'Optional',
              ),
            ),
            if (_hint != null) ...[
              const SizedBox(height: 8),
              Text(_hint!, style: const TextStyle(color: BloomlyColors.muted)),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context, _reference.text),
              child: const Text('I have paid'),
            ),
            const SizedBox(height: 6),
            Text(
              'The store checks the payment in their UPI app before packing.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: BloomlyColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openApp() async {
    try {
      final opened = await launchUrl(
        Uri.parse(widget.uri),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() => _hint = 'Scan the QR with BHIM, GPay, PhonePe, or Paytm.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hint = 'Scan the QR with BHIM, GPay, PhonePe, or Paytm.');
      }
    }
  }
}
