import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

String? aisleEmoji(String id) {
  return switch (id) {
    'vegetables' => '🥬',
    'fruits' => '🍎',
    'flowers' => '🌸',
    'puja' => '🪔',
    'gifting' => '🎁',
    'festival' || 'diwali' => '🪔',
    _ => null,
  };
}

class AisleCircle extends StatelessWidget {
  const AisleCircle({
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.icon,
    this.rail = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;

  /// Narrow stack used in the category rail.
  final bool rail;

  @override
  Widget build(BuildContext context) {
    if (rail) return _rail(context);
    final tokens = context.bloom;
    final mark = emoji;
    final disc = tokens.sunken;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: disc,
              shape: CircleBorder(
                side: BorderSide(
                  color: selected ? tokens.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                excludeFromSemantics: true,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: mark != null
                        ? BloomEmoji(mark, size: 32)
                        : Icon(icon, size: 28, color: tokens.text),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: BloomlyType.uiText(
                    12,
                    weight: FontWeight.w500,
                    color: tokens.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail(BuildContext context) {
    final tokens = context.bloom;
    final mark = emoji;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? tokens.surface : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? tokens.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 4, 10),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.canvas,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? tokens.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: mark != null
                      ? BloomEmoji(mark, size: 20)
                      : Icon(icon, size: 20, color: tokens.text),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: BloomlyType.uiText(
                    10,
                    weight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? tokens.primary : tokens.text,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
