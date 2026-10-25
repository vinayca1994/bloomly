import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/auth_result.dart';
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
  OtpChannel _channel = OtpChannel.whatsapp;
  OtpChannel? _pendingChannel;
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
      backgroundColor: BloomlyColors.ink,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: BackButton(color: Color(0xFFF6F1E4)),
            ),
          ),
          const _BotanicalHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'bloom',
                  style: BloomlyType.display(
                    42,
                    color: const Color(0xFFF6F1E4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _title,
                  style: BloomlyType.display(
                    22,
                    color: const Color(0xFFF0C14A),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F4EC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  if (kDebugMode) ...[
                    const Text(
                      'Continue as',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _demoChip(
                          'Customer',
                          const Color(0xFFE5F4F1),
                          BloomlyColors.greenDark,
                          _busy ? null : () => _signInDemo('customer'),
                        ),
                        _demoChip(
                          'Store owner',
                          const Color(0xFFFFF0E8),
                          const Color(0xFFB42318),
                          _busy ? null : () => _signInDemo('owner'),
                        ),
                        _demoChip(
                          'Rider',
                          const Color(0xFFFFF6D8),
                          const Color(0xFF8A5A00),
                          _busy ? null : () => _signInDemo('rider'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6E6254),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._fields(showDemo),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: BloomlyColors.danger),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_step == _Step.phone)
                    ..._sendButtons()
                  else
                    _primaryButton(
                      _busy ? 'Please wait…' : _action,
                      _busy ? null : _submit,
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
        return 'Sign in with a code on WhatsApp or by SMS.';
      case _Step.otp:
        final where = _channel == OtpChannel.whatsapp
            ? 'on WhatsApp'
            : 'by SMS';
        return 'We sent a 6-digit code $where to ${_phone.text.trim()}.';
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
            decoration: _field('Mobile number'),
          ),
        ];
      case _Step.otp:
        return [
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: _field('6-digit code'),
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
            decoration: _field('Name'),
          ),
        ];
      case _Step.email:
        return [
          if (_create) ...[
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: _field('Name'),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: _field('Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: _field('Password'),
          ),
        ];
      case _Step.recover:
        return [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: _field('Email'),
          ),
        ];
      case _Step.reset:
        return [
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: _field('6-digit code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resetPassword,
            obscureText: true,
            decoration: _field('New password'),
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

  InputDecoration _field(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE4DDD0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE4DDD0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: BloomlyColors.amber, width: 1.6),
      ),
    );
  }

  Future<void> _signInDemo(String role) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(backendProvider).signInDemo(role);
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

  Widget _demoChip(
    String label,
    Color fill,
    Color ink,
    VoidCallback? onPressed,
  ) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
      backgroundColor: fill,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onPressed: onPressed,
    );
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
        final other = _channel == OtpChannel.whatsapp
            ? OtpChannel.sms
            : OtpChannel.whatsapp;
        return [
          TextButton(
            onPressed: _busy ? null : () => _submitPhone(_channel),
            child: Text(
              _channel == OtpChannel.whatsapp
                  ? 'Resend on WhatsApp'
                  : 'Resend by SMS',
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => _submitPhone(other),
            child: Text(
              other == OtpChannel.whatsapp
                  ? 'Get code on WhatsApp'
                  : 'Get code by SMS',
            ),
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
            child: Text(
              _create ? 'I already have an account' : 'Create an account',
            ),
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
      _pendingChannel = null;
    });
  }

  Future<void> _submit() async {
    switch (_step) {
      case _Step.phone:
        return;
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

  List<Widget> _sendButtons() {
    return [
      _primaryButton(
        _pendingLabel(OtpChannel.whatsapp, 'Get code on WhatsApp'),
        _busy ? null : () => _submitPhone(OtpChannel.whatsapp),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: BloomlyColors.amber,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: BloomlyColors.amber),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _busy ? null : () => _submitPhone(OtpChannel.sms),
        child: Text(_pendingLabel(OtpChannel.sms, 'Get code by SMS')),
      ),
    ];
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: BloomlyColors.gold,
        foregroundColor: BloomlyColors.ink,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  String _pendingLabel(OtpChannel channel, String label) {
    if (_busy && _pendingChannel == channel) return 'Please wait…';
    return label;
  }

  Future<void> _submitPhone(OtpChannel channel) async {
    setState(() {
      _busy = true;
      _pendingChannel = channel;
      _error = null;
    });
    final result = await ref
        .read(backendProvider)
        .startPhoneLogin(_phone.text, channel: channel);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _busy = false;
        _pendingChannel = null;
        _error = result.error;
      });
      return;
    }
    setState(() {
      _busy = false;
      _pendingChannel = null;
      _channel = channel;
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
    final error = await ref
        .read(backendProvider)
        .verifyPhoneOtp(userId: userId, code: _code.text, channel: _channel);
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
      setState(
        () => _error = 'Enter a valid email and a password of 8+ characters.',
      );
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
    final error = await ref
        .read(backendProvider)
        .completePasswordReset(
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
    if (profile?.isRider == true) {
      context.go('/rider');
      return;
    }
    if (profile?.isOwner == true &&
        (next == null || next.startsWith('/owner'))) {
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
    canvas.drawCircle(
      Offset(size.width * 0.12, 8),
      28,
      Paint()..color = const Color(0xFF2C261C),
    );
    final arc = Paint()
      ..color = const Color(0xFFF0C14A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.82, size.height + 18),
        radius: 46,
      ),
      -2.7,
      1.7,
      false,
      arc,
    );
    final leaf = Path()
      ..moveTo(28, 52)
      ..quadraticBezierTo(46, 8, 84, 22)
      ..quadraticBezierTo(52, 32, 28, 52);
    canvas.drawPath(leaf, Paint()..color = const Color(0xFFE7F6F1));
    canvas.drawLine(
      const Offset(36, 46),
      const Offset(70, 24),
      Paint()
        ..color = const Color(0xFFF0C14A)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
