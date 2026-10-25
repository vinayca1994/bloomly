import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/stories.dart';
import 'promo_card.dart';

class StoryBanner extends StatelessWidget {
  const StoryBanner({required this.stories, super.key});

  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();
    return _BannerCarousel(stories: stories);
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.stories});

  final List<Story> stories;

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
      duration: const Duration(seconds: 4),
    );
    _dwell.addStatusListener(_onDwell);
    if (widget.stories.length > 1) _dwell.forward();
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
    if (widget.stories.length < 2) return;
    final next = (_index + 1) % widget.stories.length;
    _page.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          SizedBox(
            height: 156,
            child: Listener(
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
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: PromoCard(story: widget.stories[index]),
                ),
              ),
            ),
          ),
          if (widget.stories.length > 1) ...[
            const SizedBox(height: 10),
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
            width: i == index ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == index ? BloomlyColors.ink : BloomlyColors.line,
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
