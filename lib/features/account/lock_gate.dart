import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';

class LockGate extends ConsumerStatefulWidget {
  const LockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  bool _synced = false;
  bool _signedIn = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(appLockProvider);
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (lock.prompting) lock.sawResumeDuringPrompt = true;
      _paused = true;
      return;
    }
    if (state != AppLifecycleState.resumed || !_paused) return;
    _paused = false;
    if (lock.prompting) {
      lock.sawResumeDuringPrompt = true;
      return;
    }
    if (lock.suppressResume) {
      lock.suppressResume = false;
      return;
    }
    if (ref.read(backendProvider).currentUser != null) lock.engage();
  }

  void _sync() {
    final backend = ref.read(backendProvider);
    final lock = ref.read(appLockProvider);
    if (!backend.ready || !lock.ready) return;
    final signedIn = backend.currentUser != null;
    if (!_synced) {
      _synced = true;
      _signedIn = signedIn;
      if (signedIn) lock.engage();
      return;
    }
    if (!signedIn) {
      _signedIn = false;
      lock.disengage();
      return;
    }
    if (!_signedIn) _signedIn = true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(backendProvider, (_, _) => _sync());
    ref.listen(appLockProvider, (_, _) => _sync());
    final lock = ref.watch(appLockProvider);
    final backend = ref.watch(backendProvider);
    if (backend.ready && lock.ready && !_synced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sync();
      });
    }
    if (!lock.locked) return widget.child;
    return const _LockScreen();
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    return ColoredBox(
      color: BloomlyColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 72,
                width: 120,
                child: CustomPaint(painter: _LockMarkPainter()),
              ),
              const SizedBox(height: 12),
              Text('bloomly', style: BloomlyType.display(32)),
              const SizedBox(height: 6),
              Text(
                'Unlock with ${lock.label}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: BloomlyColors.danger)),
              ],
              const SizedBox(height: 16),
              FilledButton(onPressed: _unlock, child: const Text('Unlock')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    final ok = await ref.read(appLockProvider).unlock();
    if (!ok && mounted) {
      setState(() => _error = 'Try again, or use your device passcode.');
    }
  }
}

class _LockMarkPainter extends CustomPainter {
  const _LockMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final arc = Paint()
      ..color = BloomlyColors.marigold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.72, size.height), radius: 36),
      -2.6,
      1.6,
      false,
      arc,
    );
    final leaf = Path()
      ..moveTo(8, size.height - 8)
      ..quadraticBezierTo(28, 4, 62, 18)
      ..quadraticBezierTo(34, 28, 8, size.height - 8);
    canvas.drawPath(leaf, Paint()..color = BloomlyColors.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
