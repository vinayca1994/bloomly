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

  /// Festival grounds stay on the poster ramps, separate from the shop.
  static StoryPalette of(StoryTone tone) {
    return switch (tone) {
      StoryTone.marigold => const StoryPalette(
        wash: Poster.night,
        title: Poster.nightInk,
        subtitle: Poster.harvest,
      ),
      StoryTone.flower => const StoryPalette(
        wash: Market.flower,
        title: Market.ink,
        subtitle: Poster.red,
      ),
      StoryTone.fruit => const StoryPalette(
        wash: Poster.cream,
        title: Market.ink,
        subtitle: Poster.citrus,
      ),
      StoryTone.leaf => const StoryPalette(
        wash: Poster.pine,
        title: bloomWhite,
        subtitle: Poster.lime,
      ),
    };
  }
}
