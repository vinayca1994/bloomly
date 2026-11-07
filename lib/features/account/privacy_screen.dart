import 'package:flutter/material.dart';

import '../../core/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('What Bloom keeps', style: BloomlyType.display(28)),
          const SizedBox(height: 12),
          Text(
            'Your email or mobile number is used to sign in. A one-time code is emailed to you, or sent on WhatsApp when you sign in with a mobile number. Passwords are stored by the account service, not on this phone for Face ID.',
          ),
          SizedBox(height: 12),
          Text(
            'Location is used while the app is open, to check that Bloom delivers in your city and to fill an address. A rider’s phone shares its location only during an active delivery. That pin is shown to the customer on that order and to the store. You can type an address instead.',
          ),
          SizedBox(height: 12),
          Text(
            'UPI opens in GPay, PhonePe, Paytm, or BHIM through Razorpay. Bloom stores the payment status and the payment id, not your UPI PIN. A captured payment places the order. Cash on delivery stays unpaid until the order arrives.',
          ),
          SizedBox(height: 12),
          Text(
            'Face ID or fingerprint only unlocks this phone. It is not a separate Bloom account. You can turn it off in Account.',
          ),
          SizedBox(height: 12),
          Text(
            'Delete account removes your sign-in, saved addresses, and orders. A paid UPI order has to be refunded first. A public copy of this note is at vinayca1994.github.io/bloomly/privacy.html.',
            style: TextStyle(color: context.bloom.textSecondary),
          ),
        ],
      ),
    );
  }
}
