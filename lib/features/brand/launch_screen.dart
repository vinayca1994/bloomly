import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../data/stories.dart';
import '../account/lock_gate.dart';
import '../shop/promo_card.dart';

/// The splash is the cold start only. Leave when the catalog is ready,
/// and never later than 1 second. A published splash fills that wait.
/// A load error stays here with Retry.
bool leaveSplash({
  required bool ready,
  required bool timedOut,
  required bool failed,
}) {
  if (failed) return false;
  return ready || timedOut;
}

class LaunchGate extends ConsumerStatefulWidget {
  const LaunchGate({required this.child, super.key});

  final Widget? child;

  @override
  ConsumerState<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<LaunchGate> {
  var _timedOut = false;
  var _skipped = false;
  var _page = 0;
  Timer? _timer;
  final _pages = PageController();

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _skip() {
    if (_skipped) return;
    setState(() => _skipped = true);
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final failed = backend.loadError != null;
    final splash = activeStories(
      StoryPlacement.splash,
      DateTime.now(),
      source: backend.store.promotions,
    );
    if (failed) {
      return _LaunchFrame(
        message: backend.loadError,
        onRetry: () => ref.read(backendProvider).reload(),
      );
    }
    if (_skipped ||
        leaveSplash(ready: backend.ready, timedOut: _timedOut, failed: false)) {
      return LockGate(child: widget.child ?? const SizedBox.shrink());
    }
    if (splash.isNotEmpty) {
      final page = _page.clamp(0, splash.length - 1);
      return _SplashFrame(
        stories: splash,
        page: page,
        controller: _pages,
        onPage: (index) => setState(() => _page = index),
        onSkip: _skip,
      );
    }
    return _LaunchFrame(onSkip: _skip);
  }
}

class _SplashFrame extends StatelessWidget {
  const _SplashFrame({
    required this.stories,
    required this.page,
    required this.controller,
    required this.onPage,
    required this.onSkip,
  });

  final List<Story> stories;
  final int page;
  final PageController controller;
  final ValueChanged<int> onPage;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Plum.s950,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: controller,
            itemCount: stories.length,
            onPageChanged: onPage,
            itemBuilder: (context, index) {
              return PromoCard(
                story: stories[index],
                bleed: true,
                onTap: () {},
              );
            },
          ),
          const IgnorePointer(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'bloom',
                        style: TextStyle(
                          fontFamily: BloomlyType.displayFamily,
                          fontSize: 40,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: BloomBrand.basilDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Fresh in 25 minutes',
                        style: TextStyle(
                          fontFamily: BloomlyType.ui,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Plum.s300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 16,
            child: SafeArea(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Sun.s100,
                  backgroundColor: const Color(0x800C1511),
                  minimumSize: const Size(48, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onSkip,
                child: const Text('Skip'),
              ),
            ),
          ),
          Positioned(
            left: 32,
            bottom: 32,
            child: Row(
              children: [
                for (var i = 0; i < stories.length; i++)
                  Container(
                    width: 24,
                    height: 4,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: i == page ? Sun.s300 : Sun.s100.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchFrame extends StatelessWidget {
  const _LaunchFrame({this.message, this.onRetry, this.onSkip});

  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final failed = message != null;
    return ColoredBox(
      color: failed ? context.bloom.canvas : Plum.s950,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'bloom',
                      style: BloomlyType.display(
                        52,
                        color: failed ? context.bloom.link : BloomBrand.basilDark,
                      ),
                    ),
                    if (!failed) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Fresh in 25 minutes',
                        style: TextStyle(
                          fontFamily: BloomlyType.ui,
                          color: Plum.s300,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.bloom.text),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (onSkip != null)
            Positioned(
              top: 0,
              right: 16,
              child: SafeArea(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Sun.s100,
                    backgroundColor: const Color(0x800C1511),
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
