import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/stories.dart';
import 'promo_card.dart';

class StoryClipRail extends StatelessWidget {
  const StoryClipRail({required this.stories, super.key});

  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();
    return _ClipRail(stories: stories);
  }
}

class _ClipRail extends StatefulWidget {
  const _ClipRail({required this.stories});

  final List<Story> stories;

  @override
  State<_ClipRail> createState() => _ClipRailState();
}

class _ClipRailState extends State<_ClipRail>
    with SingleTickerProviderStateMixin {
  late final PageController _page;
  late final AnimationController _loop;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.34);
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _curve = CurvedAnimation(parent: _loop, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 1, end: 1.03).animate(_curve);
    _loop.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
      _loop.value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _loop.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxWidth * 0.34 * 16 / 9;
          return SizedBox(
            height: height,
            child: PageView.builder(
              controller: _page,
              padEnds: false,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final tile = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: _ClipTile(story: widget.stories[index]),
                );
                if (index != 0) return tile;
                return AnimatedBuilder(
                  animation: _scale,
                  builder: (context, child) =>
                      Transform.scale(scale: _scale.value, child: child),
                  child: tile,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ClipTile extends StatelessWidget {
  const _ClipTile({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final route = story.route;
    return PromoCard(
      story: story,
      compact: true,
      onTap: route == null ? null : () => context.go(route),
    );
  }
}
