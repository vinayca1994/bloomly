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
  Timer? _timer;

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
    super.dispose();
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
    if (leaveSplash(
      ready: backend.ready,
      timedOut: _timedOut,
      failed: failed,
    )) {
      return LockGate(child: widget.child ?? SizedBox.shrink());
    }
    if (splash.isNotEmpty) {
      return ColoredBox(
        color: context.bloom.canvas,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: PromoCard(story: splash.first),
              ),
            ),
          ),
        ),
      );
    }
    return _LaunchFrame(
      message: backend.loadError,
      onRetry: failed ? () => ref.read(backendProvider).reload() : null,
    );
  }
}

class _LaunchFrame extends StatelessWidget {
  _LaunchFrame({this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.bloom.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480),
          child: ColoredBox(
            color: context.bloom.canvas,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'bloom',
                        style: BloomlyType.display(52, color: context.bloom.link),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: onRetry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
