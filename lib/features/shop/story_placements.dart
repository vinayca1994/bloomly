import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloom_icons.dart';
import '../../core/theme.dart';
import '../../data/stories.dart';
import 'promo_card.dart';

class OfferStrip extends StatefulWidget {
  const OfferStrip({required this.stories, super.key});

  final List<Story> stories;

  @override
  State<OfferStrip> createState() => _OfferStripState();
}

class _OfferStripState extends State<OfferStrip> {
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
    } else {
      _arm();
    }
  }

  void _arm() {
    _timer?.cancel();
    final count = widget.stories.length.clamp(0, 3);
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      setState(() => _index = (_index + 1) % count);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return const SizedBox.shrink();
    final tokens = context.bloom;
    final count = widget.stories.length.clamp(0, 3);
    final story = widget.stories[_index % count];
    final route = story.route;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: tokens.discountBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: route == null || GoRouter.maybeOf(context) == null
              ? null
              : () => context.go(route),
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      story.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BloomlyType.uiText(
                        13,
                        weight: FontWeight.w800,
                        color: tokens.discountFg,
                      ),
                    ),
                  ),
                  Icon(BloomIcons.caretRight, size: 16, color: tokens.discountFg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StoryTileGrid extends StatelessWidget {
  const StoryTileGrid({required this.stories, super.key});

  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();
    final tiles = stories.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          return PromoCard(story: tiles[index], compact: true);
        },
      ),
    );
  }
}
