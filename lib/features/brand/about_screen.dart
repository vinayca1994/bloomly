import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../core/bloom_icons.dart';

class AboutBlock {
  const AboutBlock(this.heading, this.body);

  final String heading;
  final String body;
}

List<AboutBlock> aboutBlocks(StoreSettings store) => [
  const AboutBlock(
    'What Bloom is',
    'Bloom is one shop for vegetables, fruit, and regional flowers. Browse without an account, and sign in when you order.',
  ),
  const AboutBlock(
    'What we carry',
    'Daily vegetables, fruit, and flowers from the North, South, East, and West.',
  ),
  AboutBlock(
    'Where and how fast',
    'Bloom delivers in ${store.city}. Orders usually arrive in ${store.etaLabel}. Delivery is ${money(store.deliveryFee)}, and free on orders over ${money(store.freeDeliveryAbove)}.',
  ),
  const AboutBlock(
    'How an order moves',
    'Cash orders are Placed immediately. UPI orders are Placed after the store confirms the payment. Then the order moves through Packing, Out for delivery, and Delivered.',
  ),
];

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(backendProvider).store;
    final call = PhoneNumber.telUri(store.storePhone);
    final blocks = aboutBlocks(store);
    return Scaffold(
      appBar: AppBar(title: const Text('About Bloom')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          for (final block in blocks) ...[
            Text(block.heading, style: BloomlyType.display(26)),
            const SizedBox(height: 8),
            Text(block.body),
            const SizedBox(height: 22),
          ],
          if (call != null)
            OutlinedButton.icon(
              onPressed: () => launchUrl(call),
              icon: const Icon(BloomIcons.phone),
              label: const Text('Call the store'),
            ),
        ],
      ),
    );
  }
}
