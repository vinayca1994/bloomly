import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/stories.dart';
import 'promo_card.dart';

class StoryBanner extends StatelessWidget {
  const StoryBanner({
    required this.stories,
    this.bleed = false,
    this.aspect = 0,
    super.key,
  });

  final List<Story> stories;
  final bool bleed;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();
    return _BannerCarousel(stories: stories, bleed: bleed, aspect: aspect);
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({
    required this.stories,
    required this.bleed,
    required this.aspect,
  });

  final List<Story> stories;
  final bool bleed;
  final double aspect;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _page;
  late final AnimationController _dwell;
  var _index = 0;
  var _held = false;

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _dwell = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _dwell.addStatusListener(_onDwell);
    if (widget.stories.length > 1) _dwell.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _dwell.stop();
  }

  @override
  void didUpdateWidget(_BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameIds(oldWidget.stories, widget.stories)) return;
    _index = 0;
    if (_page.hasClients) _page.jumpToPage(0);
    _restartDwell();
  }

  @override
  void dispose() {
    _dwell.removeStatusListener(_onDwell);
    _dwell.dispose();
    _page.dispose();
    super.dispose();
  }

  void _onDwell(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || _held) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (widget.stories.length < 2) return;
    final next = (_index + 1) % widget.stories.length;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _page.jumpToPage(next);
      return;
    }
    _page.animateToPage(
      next,
      duration: BloomTokens.slow,
      curve: BloomTokens.easeEmphasized,
    );
  }

  void _restartDwell() {
    if (widget.stories.length < 2 || _held) {
      _dwell.stop();
      return;
    }
    _dwell.forward(from: 0);
  }

  void _hold(bool held) {
    _held = held;
    if (held) {
      _dwell.stop();
    } else {
      _restartDwell();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = Listener(
      onPointerDown: (_) => _hold(true),
      onPointerUp: (_) => _hold(false),
      onPointerCancel: (_) => _hold(false),
      child: PageView.builder(
        controller: _page,
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          setState(() => _index = index);
          _restartDwell();
        },
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.bleed ? 0 : 2),
          child: PromoCard(story: widget.stories[index], bleed: widget.bleed),
        ),
      ),
    );
    final frame = widget.aspect > 0
        ? AspectRatio(aspectRatio: widget.aspect, child: pages)
        : SizedBox(height: 156, child: pages);
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bleed ? 8 : 16),
      child: Column(
        children: [
          frame,
          if (widget.stories.length > 1) ...[
            const SizedBox(height: 8),
            _Dots(count: widget.stories.length, index: _index),
          ],
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: i == index ? 18 : 8,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == index ? context.bloom.primary : context.bloom.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

bool _sameIds(List<Story> a, List<Story> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id) return false;
  }
  return true;
}
