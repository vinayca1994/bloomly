import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/catalog_seed.dart';
import 'bloom_emoji.dart';
import 'theme.dart';
import 'bloom_icons.dart';

/// Emoji must not inherit Plus Jakarta Sans. That font has no emoji, and on
/// the web the missing glyph draws as a menu icon.
class BloomEmoji extends StatelessWidget {
  const BloomEmoji(this.emoji, {this.size = 28, super.key});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => bloomEmoji(emoji, size, context.bloom.text);
}

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(480.0, constraints.maxWidth);
        final height = constraints.maxHeight;
        final tokens = context.bloom;
        return ColoredBox(
          color: tokens.canvas,
          child: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        );
      },
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.emoji,
    required this.kind,
    this.url,
    this.bytes,
    super.key,
  });

  final String emoji;
  final ColorKind kind;
  final String? url;
  final Uint8List? bytes;

  /// Tests turn this off so product photos never hit the network.
  static bool enableNetwork = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _tile(context),
        if (bytes != null)
          Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true)
        else if (url != null && url!.startsWith('assets/'))
          Image.asset(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        else if (enableNetwork && url != null && url!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            placeholder: (_, _) => const SizedBox.shrink(),
            errorWidget: (_, _, _) => SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _tile(BuildContext context) {
    final tokens = context.bloom;
    final color = switch (kind) {
      ColorKind.fruit => tokens.washFruit,
      ColorKind.flower => tokens.washFlower,
      ColorKind.vegetable => tokens.washVeg,
    };
    return ColoredBox(
      color: color,
      child: Center(child: BloomEmoji(emoji, size: 42)),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    this.minusKey,
    this.plusKey,
    super.key,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final Key? minusKey;
  final Key? plusKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Material(
      color: tokens.primary,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(context, BloomIcons.minus, onMinus, minusKey, 'Decrease, $qty in cart'),
            SizedBox(
              width: 28,
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: BloomlyType.uiText(
                  14,
                  weight: FontWeight.w800,
                  color: tokens.onPrimary,
                ),
              ),
            ),
            _button(context, BloomIcons.add, onPlus, plusKey, '$qty in cart, increase'),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    Key? key,
    String label,
  ) {
    final tokens = context.bloom;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: key,
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: tokens.onPrimary),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, required this.label, super.key});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pair = context.bloom.status(status);
    return Semantics(
      label: 'Status $label',
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: pair.$1,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: pair.$2, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: BloomlyType.uiText(12, weight: FontWeight.w800, color: pair.$2),
            ),
          ],
        ),
      ),
    );
  }
}

class FreeDeliveryBar extends StatelessWidget {
  const FreeDeliveryBar({
    required this.subtotal,
    required this.freeAbove,
    super.key,
  });

  final int subtotal;
  final int freeAbove;

  @override
  Widget build(BuildContext context) {
    if (subtotal <= 0 || freeAbove <= 0) return SizedBox.shrink();
    final tokens = context.bloom;
    final unlocked = subtotal >= freeAbove;
    final remaining = freeAbove - subtotal;
    final progress = (subtotal / freeAbove).clamp(0.0, 1.0);
    final label = unlocked
        ? 'Free delivery unlocked'
        : 'Add ₹$remaining more for free delivery';
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: unlocked ? tokens.successBg : tokens.secondary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  unlocked ? BloomIcons.checkCircle : BloomIcons.truck,
                  size: 18,
                  color: unlocked ? tokens.success : tokens.onSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: BloomlyType.uiText(
                      13,
                      weight: FontWeight.w800,
                      color: unlocked ? tokens.success : tokens.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                backgroundColor: tokens.surface,
                color: unlocked ? tokens.success : tokens.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BloomEmpty extends StatelessWidget {
  const BloomEmpty({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: tokens.washFlower,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tokens.link, size: 52),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BloomlyType.display(24, color: tokens.text),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: BloomlyType.uiText(14, color: tokens.textSecondary, height: 1.4),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onPressed, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Six visual boxes over one code field. The field stays the source of truth.
class OtpBoxes extends StatelessWidget {
  const OtpBoxes({required this.controller, required this.focusNode, super.key});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final digits = controller.text;
        return GestureDetector(
          onTap: focusNode.requestFocus,
          child: Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: i == digits.length ? tokens.borderFocus : tokens.borderStrong,
                        width: i == digits.length ? 2 : 1.5,
                      ),
                    ),
                    child: Text(
                      i < digits.length ? digits[i] : '',
                      style: BloomlyType.display(24, color: tokens.text),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
