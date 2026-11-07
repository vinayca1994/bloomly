import 'package:flutter/material.dart';

import '../../core/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Ordering from Bloom', style: BloomlyType.display(28)),
          const SizedBox(height: 12),
          const Text(
            'Bloom sells vegetables, fruit, and regional flowers. Prices, the delivery fee, and the amount that removes the delivery fee are shown before you pay.',
          ),
          const SizedBox(height: 12),
          const Text(
            'A mobile number signs in with a one-time code sent on WhatsApp. Do not share that code. Email sign-in uses a password.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Cash stays unpaid until the order arrives. UPI opens in GPay, PhonePe, Paytm, or BHIM. Bloom stores the payment status and the payment id, not your UPI PIN. A captured payment places the order.',
          ),
          const SizedBox(height: 12),
          const Text(
            'You can cancel an order before the store packs it. After that, contact the store from the order.',
          ),
          const SizedBox(height: 12),
          Text(
            'Bloom delivers where the app shows coverage. You can type an address if you do not share location.',
            style: TextStyle(color: context.bloom.textSecondary),
          ),
        ],
      ),
    );
  }
}
