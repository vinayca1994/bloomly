import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/stories.dart';

class StoryPalette {
  const StoryPalette({
    required this.wash,
    required this.title,
    required this.subtitle,
  });

  final Color wash;
  final Color title;
  final Color subtitle;

  static StoryPalette of(StoryTone tone) {
    return switch (tone) {
      StoryTone.marigold => const StoryPalette(
        wash: BloomlyColors.marigold,
        title: Colors.white,
        subtitle: Color(0xE6FFFFFF),
      ),
      StoryTone.flower => const StoryPalette(
        wash: BloomlyColors.peach,
        title: BloomlyColors.ink,
        subtitle: BloomlyColors.muted,
      ),
      StoryTone.fruit => const StoryPalette(
        wash: BloomlyColors.fruitWash,
        title: BloomlyColors.ink,
        subtitle: BloomlyColors.muted,
      ),
      StoryTone.leaf => const StoryPalette(
        wash: BloomlyColors.leafWash,
        title: BloomlyColors.ink,
        subtitle: BloomlyColors.muted,
      ),
    };
  }
}
