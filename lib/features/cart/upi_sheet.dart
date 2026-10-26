import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/online_payment.dart';

/// Returns the UPI reference the customer typed, or null if they closed the sheet.
/// An empty string means they paid and did not enter a reference.
Future<String?> showUpiPaymentSheet(
  BuildContext context, {
  required OnlinePayment payment,
}) {
  final uri = payment.payUri;
  if (uri == null) return Future.value();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.bloom.raised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
  var _step = 1;
  Timer? _ticker;
  late Duration _left;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left = _remaining());
    });
  }

  Duration _remaining() {
    final elapsed = DateTime.now().difference(widget.payment.order.placedAt);
    final left = OrderRecord.upiPaymentTimeout - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get _expired => _left == Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final tokens = context.bloom;
    final clock =
        '${_left.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(_left.inSeconds % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.borderStrong,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pay ${money(widget.payment.amountRupees)} by UPI',
              style: BloomlyType.display(24, color: tokens.text),
            ),
            const SizedBox(height: 12),
            _Steps(current: _expired ? 0 : _step),
            const SizedBox(height: 16),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bloomWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: QrImageView(
                    data: widget.uri,
                    size: 168,
                    backgroundColor: bloomWhite,
                    eyeStyle: const QrEyeStyle(color: Plum.s950, eyeShape: QrEyeShape.square),
                    dataModuleStyle: const QrDataModuleStyle(
                      color: Plum.s950,
                      dataModuleShape: QrDataModuleShape.square,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.payment.upiId,
              textAlign: TextAlign.center,
              style: BloomlyType.uiText(16, weight: FontWeight.w800, color: tokens.text),
            ),
            Text(
              widget.payment.upiName,
              textAlign: TextAlign.center,
              style: BloomlyType.uiText(13, color: tokens.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.payment.upiId));
                if (mounted) setState(() => _hint = 'UPI ID copied.');
              },
              child: const Text('Copy UPI ID'),
            ),
            OutlinedButton(
              onPressed: _openApp,
              child: const Text('Open UPI app'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reference,
              textCapitalization: TextCapitalization.characters,
              onTap: () => setState(() => _step = 3),
              decoration: const InputDecoration(
                labelText: 'UPI reference, if you have it',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: _expired ? 'Payment window ended' : 'Expires in $clock',
              child: Text(
                _expired ? 'This payment window has ended.' : 'Expires in $clock',
                textAlign: TextAlign.center,
                style: BloomlyType.uiText(
                  13,
                  weight: FontWeight.w800,
                  color: _expired ? tokens.danger : tokens.awaitingFg,
                ),
              ),
            ),
            if (_hint != null) ...[
              const SizedBox(height: 8),
              Text(
                _hint!,
                textAlign: TextAlign.center,
                style: BloomlyType.uiText(13, color: tokens.textSecondary),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _expired ? () => Navigator.pop(context) : () => Navigator.pop(context, _reference.text),
              child: Text(_expired ? 'Retry' : 'I have paid'),
            ),
            const SizedBox(height: 6),
            Text(
              'The store checks the payment in their UPI app before packing.',
              textAlign: TextAlign.center,
              style: BloomlyType.uiText(12, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openApp() async {
    setState(() => _step = 2);
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

class _Steps extends StatelessWidget {
  const _Steps({required this.current});

  final int current;

  static const labels = ['Scan or open app', 'Pay', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i + 1 <= current ? tokens.primary : tokens.sunken,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${i + 1} ${labels[i]}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: BloomlyType.uiText(
                    11,
                    weight: FontWeight.w800,
                    color: i + 1 == current ? tokens.awaitingFg : tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
