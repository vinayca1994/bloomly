import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/memory_backend.dart';
import '../../data/providers.dart';

enum _Step { phone, otp, name, email, recover, reset }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _resetPassword = TextEditingController();
  _Step _step = _Step.phone;
  bool _create = false;
  bool _busy = false;
  String? _error;
  String? _userId;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _resetPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final showDemo = kDebugMode && backend.demoShortcuts;
    return Scaffold(
      backgroundColor: const Color(0xFF2C211B),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: BackButton(color: Color(0xFFFFF6EC)),
            ),
          ),
          const _BotanicalHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('bloomly', style: BloomlyType.display(40, color: const Color(0xFFFFF6EC))),
                const SizedBox(height: 6),
                Text(_title, style: BloomlyType.display(22, color: const Color(0xFFE2A04A))),
              ],
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFFFF6EC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                children: [
                  Text(_subtitle, style: const TextStyle(color: Color(0xFF8A7564))),
                  const SizedBox(height: 18),
                  ..._fields(showDemo),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: BloomlyColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Please wait…' : _action),
                  ),
                  ..._links(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (_step) {
      case _Step.phone:
        return 'Fresh in minutes.';
      case _Step.otp:
        return 'Enter the code';
      case _Step.name:
        return 'What should we call you?';
      case _Step.email:
        return _create ? 'Create an account' : 'Sign in with email';
      case _Step.recover:
        return 'Reset your password';
      case _Step.reset:
        return 'Choose a new password';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _Step.phone:
        return 'Sign in with your mobile number.';
      case _Step.otp:
        return 'We sent a 6-digit code to ${_phone.text.trim()}.';
      case _Step.name:
        return 'This is how the store greets you.';
      case _Step.email:
        return 'Use this for the store owner, or if you prefer a password.';
      case _Step.recover:
        return 'We will email a 6-digit code.';
      case _Step.reset:
        return 'Use the code from the email.';
    }
  }

  String get _action {
    switch (_step) {
      case _Step.phone:
        return 'Send code';
      case _Step.otp:
        return 'Verify';
      case _Step.name:
        return 'Continue';
      case _Step.email:
        return _create ? 'Create account' : 'Sign in';
      case _Step.recover:
        return 'Send code';
      case _Step.reset:
        return 'Update password';
    }
  }

  List<Widget> _fields(bool showDemo) {
    switch (_step) {
      case _Step.phone:
        return [
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number'),
          ),
          if (showDemo) ...[
            const SizedBox(height: 16),
            const Text('Demo accounts', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Customer'),
                  onPressed: () => _fill(MemoryBackend.customerEmail),
                ),
                ActionChip(
                  label: const Text('Store owner'),
                  onPressed: () => _fill(MemoryBackend.ownerEmail),
                ),
              ],
            ),
          ],
        ];
      case _Step.otp:
        return [
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '6-digit code'),
          ),
          if (showDemo)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Demo code 123456',
                style: TextStyle(color: BloomlyColors.muted, fontSize: 12),
              ),
            ),
        ];
      case _Step.name:
        return [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
        ];
      case _Step.email:
        return [
          if (_create) ...[
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ];
      case _Step.recover:
        return [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ];
      case _Step.reset:
        return [
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '6-digit code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resetPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          if (showDemo)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Demo code 123456',
                style: TextStyle(color: BloomlyColors.muted, fontSize: 12),
              ),
            ),
        ];
    }
  }

  List<Widget> _links() {
    switch (_step) {
      case _Step.phone:
        return [
          TextButton(
            onPressed: () => _go(_Step.email),
            child: const Text('Sign in with email'),
          ),
        ];
      case _Step.otp:
        return [
          TextButton(
            onPressed: _busy ? null : _submitPhone,
            child: const Text('Resend code'),
          ),
          TextButton(
            onPressed: () => _go(_Step.phone),
            child: const Text('Change number'),
          ),
        ];
      case _Step.name:
        return const [];
      case _Step.email:
        return [
          TextButton(
            onPressed: () => setState(() {
              _create = !_create;
              _error = null;
            }),
            child: Text(_create ? 'I already have an account' : 'Create an account'),
          ),
          if (!_create)
            TextButton(
              onPressed: () => _go(_Step.recover),
              child: const Text('Forgot password'),
            ),
          TextButton(
            onPressed: () => _go(_Step.phone),
            child: const Text('Use a mobile number'),
          ),
        ];
      case _Step.recover:
      case _Step.reset:
        return [
          TextButton(
            onPressed: () => _go(_Step.email),
            child: const Text('Back to email sign in'),
          ),
        ];
    }
  }

  void _go(_Step step) {
    setState(() {
      _step = step;
      _error = null;
      _busy = false;
    });
  }

  void _fill(String email) {
    setState(() {
      _step = _Step.email;
      _create = false;
      _email.text = email;
      _password.text = MemoryBackend.demoPassword;
      _error = null;
    });
  }

  Future<void> _submit() async {
    switch (_step) {
      case _Step.phone:
        await _submitPhone();
      case _Step.otp:
        await _submitOtp();
      case _Step.name:
        await _submitName();
      case _Step.email:
        await _submitEmail();
      case _Step.recover:
        await _submitRecover();
      case _Step.reset:
        await _submitReset();
    }
  }

  Future<void> _submitPhone() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(backendProvider).startPhoneLogin(_phone.text);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _busy = false;
        _error = result.error;
      });
      return;
    }
    setState(() {
      _busy = false;
      _userId = result.userId;
      _code.clear();
      _step = _Step.otp;
    });
  }

  Future<void> _submitOtp() async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _error = 'Request a new code.');
      return;
    }
    if (_code.text.trim().length < 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(backendProvider).verifyPhoneOtp(
      userId: userId,
      code: _code.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    final name = ref.read(backendProvider).currentUser?.name ?? '';
    if (name.trim().isEmpty) {
      setState(() {
        _busy = false;
        _step = _Step.name;
      });
      return;
    }
    _leave();
  }

  Future<void> _submitName() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(backendProvider).updateDisplayName(_name.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    _leave();
  }

  Future<void> _submitEmail() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || password.length < 8) {
      setState(() => _error = 'Enter a valid email and a password of 8+ characters.');
      return;
    }
    if (_create && _name.text.trim().isEmpty) {
      setState(() => _error = 'Add your name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final backend = ref.read(backendProvider);
    final error = _create
        ? await backend.signUp(_name.text, email, password)
        : await backend.signIn(email, password);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    _leave();
  }

  Future<void> _submitRecover() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter the email on the account.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(backendProvider).sendPasswordReset(email);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _busy = false;
        _error = result.error;
      });
      return;
    }
    setState(() {
      _busy = false;
      _userId = result.userId;
      _code.clear();
      _step = _Step.reset;
    });
  }

  Future<void> _submitReset() async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _error = 'Request a new code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(backendProvider).completePasswordReset(
      userId: userId,
      code: _code.text,
      password: _resetPassword.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    setState(() {
      _busy = false;
      _password.clear();
      _step = _Step.email;
      _create = false;
      _error = 'Password updated. Sign in with the new one.';
    });
  }

  void _leave() {
    final backend = ref.read(backendProvider);
    final profile = backend.currentUser;
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    if (profile?.isOwner == true && (next == null || next.startsWith('/owner'))) {
      context.go(next ?? '/owner');
      return;
    }
    if (next != null && next.startsWith('/') && !next.startsWith('/owner')) {
      context.go(next);
      return;
    }
    context.go('/');
  }
}

class _BotanicalHeader extends StatelessWidget {
  const _BotanicalHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 64,
      width: double.infinity,
      child: CustomPaint(painter: _MarketMarkPainter()),
    );
  }
}

class _MarketMarkPainter extends CustomPainter {
  const _MarketMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final arc = Paint()
      ..color = const Color(0xFFE2A04A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.82, size.height + 18), radius: 46),
      -2.7,
      1.7,
      false,
      arc,
    );
    final leaf = Path()
      ..moveTo(28, 52)
      ..quadraticBezierTo(46, 8, 84, 22)
      ..quadraticBezierTo(52, 32, 28, 52);
    canvas.drawPath(leaf, Paint()..color = const Color(0xFFFFF6EC));
    canvas.drawLine(
      const Offset(36, 46),
      const Offset(70, 24),
      Paint()
        ..color = BloomlyColors.greenDark
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
