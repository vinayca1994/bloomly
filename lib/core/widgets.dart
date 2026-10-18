import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/catalog_seed.dart';
import 'theme.dart';

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
      ColorKind.fruit => const Color(0xFFF8E7D2),
      ColorKind.flower => const Color(0xFFFBE6CF),
      ColorKind.vegetable => const Color(0xFFE5F3E4),
    };
    return ColoredBox(
      color: color,
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 42))),
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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: BloomlyColors.green),
      ),
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
                  color: BloomlyColors.greenDark,
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
        child: Icon(icon, size: 16, color: BloomlyColors.greenDark),
      ),
    );
  }
}
