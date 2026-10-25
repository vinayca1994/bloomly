import 'package:flutter/material.dart';

import '../../core/bloom_tokens.dart';
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

  /// Festival grounds stay on the primitive ramps in both themes.
  static StoryPalette of(StoryTone tone) {
    return switch (tone) {
      StoryTone.marigold => const StoryPalette(
        wash: Plum.s950,
        title: Sun.s100,
        subtitle: Sun.s300,
      ),
      StoryTone.flower => const StoryPalette(
        wash: Petal.s100,
        title: Petal.s900,
        subtitle: Petal.s700,
      ),
      StoryTone.fruit => const StoryPalette(
        wash: Mango.s300,
        title: Plum.s900,
        subtitle: Chili.s700,
      ),
      StoryTone.leaf => const StoryPalette(
        wash: Basil.s900,
        title: Sun.s50,
        subtitle: Mango.s300,
      ),
    };
  }
}
