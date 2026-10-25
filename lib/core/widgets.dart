import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/catalog_seed.dart';
import 'bloom_emoji.dart';
import 'theme.dart';

/// Emoji must not inherit Plus Jakarta Sans. That font has no emoji, and on
/// the web the missing glyph draws as a menu icon.
class BloomEmoji extends StatelessWidget {
  const BloomEmoji(this.emoji, {this.size = 28, super.key});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => bloomEmoji(emoji, size);
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
        return ColoredBox(
          color: BloomlyColors.canvas,
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
        _tile(),
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
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _tile() {
    final color = switch (kind) {
      ColorKind.fruit => BloomlyColors.fruitWash,
      ColorKind.flower => BloomlyColors.peach,
      ColorKind.vegetable => BloomlyColors.leafWash,
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
    return Material(
      color: BloomlyColors.green,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(Icons.remove, onMinus, minusKey),
            SizedBox(
              width: 22,
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BloomlyColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _button(Icons.add, onPlus, plusKey),
          ],
        ),
      ),
    );
  }

  Widget _button(IconData icon, VoidCallback onPressed, Key? key) {
    return InkWell(
      key: key,
      onTap: onPressed,
      child: SizedBox(
        width: 28,
        height: 32,
        child: Icon(icon, size: 16, color: BloomlyColors.ink),
      ),
    );
  }
}
