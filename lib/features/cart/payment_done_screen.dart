import 'package:flutter/material.dart';

import '../../core/bloom_icons.dart';
import '../../core/theme.dart';

class PaymentDoneScreen extends StatelessWidget {
  const PaymentDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(BloomIcons.checkCircle, size: 72, color: tokens.success),
              const SizedBox(height: 16),
              Text(
                'Payment done',
                style: BloomlyType.display(32, color: tokens.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your order is placed. The store can pack it now.',
                style: BloomlyType.uiText(16, color: tokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Track order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
