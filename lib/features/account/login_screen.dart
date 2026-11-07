import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/phone.dart';
import '../../core/sign_in_route.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/auth_result.dart';
import '../../data/providers.dart';

enum _Step { mail, phone, otp, name, email, recover, reset }

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
  Timer? _resend;
  int _resendLeft = 0;
  var _queryApplied = false;
  final _otpFocus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_queryApplied) return;
    _queryApplied = true;
    final query = GoRouterState.of(context).uri.queryParameters;
    if (query['step'] == 'otp' && (query['userId'] ?? '').isNotEmpty) {
      _userId = query['userId'];
      _phone.text = query['phone'] ?? _phone.text;
      _email.text = query['email'] ?? _email.text;
      _channel = switch (query['channel']) {
        'email' => OtpChannel.email,
        'sms' when smsLoginLive => OtpChannel.sms,
        _ => OtpChannel.whatsapp,
      };
      _step = _Step.otp;
      _armResend();
      return;
    }
    final next = query['next'] ?? '';
    if (next.startsWith('/owner') || next.startsWith('/rider')) {
      _step = _Step.email;
      _create = false;
    }
  }

  void _armResend() {
    _resend?.cancel();
    _resendLeft = 30;
    _resend = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _resendLeft -= 1;
        if (_resendLeft <= 0) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _resend?.cancel();
    _otpFocus.dispose();
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
    final tokens = context.bloom;
    return Scaffold(
      backgroundColor: tokens.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthHeader(title: _title, subtitle: _subtitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              children: [
                if (kDebugMode && showDemo) ...[
                  Text(
                    'Continue as',
                    style: BloomlyType.uiText(
                      14,
                      weight: FontWeight.w800,
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _demoChip(
                        'Customer',
                        tokens.washVeg,
                        tokens.success,
                        _busy ? null : () => _signInDemo('customer'),
                      ),
                      _demoChip(
                        'Store owner',
                        tokens.washFruit,
                        tokens.warning,
                        _busy ? null : () => _signInDemo('owner'),
                      ),
                      _demoChip(
                        'Rider',
                        tokens.awaitingBg,
                        tokens.awaitingFg,
                        _busy ? null : () => _signInDemo('rider'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                ..._fields(showDemo),
                if (_error != null) ...[
                  SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.bloom.danger)),
                ],
                const SizedBox(height: 18),
                if (_step == _Step.phone)
                  ..._sendButtons()
                else ...[
                  _primaryButton(
                    _busy ? 'Please wait…' : _action,
                    _busy ? null : _submit,
                  ),
                  if (_step == _Step.mail) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _continueGuest,
                      child: const Text('Continue as guest'),
                    ),
                    _legalLine(),
                  ],
                ],
                ..._links(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (_step) {
      case _Step.mail:
        return 'Welcome to bloom';
      case _Step.phone:
        return 'Welcome to bloom';
      case _Step.otp:
        return 'Enter the 6-digit code';
      case _Step.name:
        return 'What should we call you?';
      case _Step.email:
        return _create ? 'Create an account' : 'Sign in with a password';
      case _Step.recover:
        return 'Reset your password';
      case _Step.reset:
        return 'Choose a new password';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _Step.mail:
        return 'We will email a 6-digit code.';
      case _Step.phone:
        return 'Fresh vegetables, fruit and flowers in minutes.';
      case _Step.otp:
        if (_channel == OtpChannel.email) {
          return 'We sent a 6-digit code to ${_email.text.trim()}.';
        }
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
      case _Step.mail:
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
      case _Step.mail:
        return [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: _field('Email'),
          ),
        ];
      case _Step.phone:
        return [
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _field('Mobile number'),
          ),
        ];
      case _Step.otp:
        final clock =
            '${_resendLeft ~/ 60}:${(_resendLeft % 60).toString().padLeft(2, '0')}';
        return [
          OtpBoxes(controller: _code, focusNode: _otpFocus),
          SizedBox(
            height: 0,
            child: TextField(
              controller: _code,
              focusNode: _otpFocus,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (value) {
                final digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits != value) {
                  _code.value = TextEditingValue(
                    text: digits,
                    selection: TextSelection.collapsed(offset: digits.length),
                  );
                }
                setState(() {});
              },
            ),
          ),
          SizedBox(height: 8),
          Text(
            _resendLeft > 0 ? 'Resend in $clock' : 'You can resend the code',
            style: BloomlyType.uiText(12, color: context.bloom.textSecondary),
          ),
          if (showDemo)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Demo code 123456',
                style: BloomlyType.uiText(
                  12,
                  color: context.bloom.textSecondary,
                ),
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
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Demo code 123456',
                style: BloomlyType.uiText(
                  12,
                  color: context.bloom.textSecondary,
                ),
              ),
            ),
        ];
    }
  }

  InputDecoration _field(String label) => InputDecoration(labelText: label);

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
      case _Step.mail:
        return [
          TextButton(
            onPressed: _busy ? null : () => _go(_Step.phone),
            child: const Text('Use a mobile number'),
          ),
          TextButton(
            onPressed: () => _go(_Step.email),
            child: const Text('Sign in with a password'),
          ),
        ];
      case _Step.phone:
        return [
          TextButton(
            onPressed: () => _go(_Step.mail),
            child: const Text('Get a code by email'),
          ),
          TextButton(
            onPressed: () => _go(_Step.email),
            child: const Text('Sign in with a password'),
          ),
        ];
      case _Step.otp:
        final other = _channel == OtpChannel.whatsapp
            ? OtpChannel.sms
            : OtpChannel.whatsapp;
        final resendLabel = _resendLeft > 0
            ? 'Resend in 0:${_resendLeft.toString().padLeft(2, '0')}'
            : _channel == OtpChannel.email
            ? 'Resend email'
            : _channel == OtpChannel.whatsapp
            ? 'Resend on WhatsApp'
            : 'Resend by SMS';
        return [
          TextButton(
            onPressed: _busy || _resendLeft > 0
                ? null
                : () => _channel == OtpChannel.email
                      ? _submitEmailCode()
                      : _submitPhone(_channel),
            child: Text(resendLabel),
          ),
          if (smsLoginLive && _channel != OtpChannel.email)
            TextButton(
              onPressed: _busy ? null : () => _submitPhone(other),
              child: Text(
                other == OtpChannel.whatsapp
                    ? 'Get code on WhatsApp'
                    : 'Get code by SMS',
              ),
            ),
          TextButton(
            onPressed: () =>
                _go(_channel == OtpChannel.email ? _Step.mail : _Step.phone),
            child: Text(
              _channel == OtpChannel.email ? 'Change email' : 'Change number',
            ),
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
            onPressed: () => _go(_Step.mail),
            child: const Text('Get a code by email'),
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
            child: const Text('Back to password sign in'),
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
    try {
      switch (_step) {
        case _Step.mail:
          await _submitEmailCode();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not sign in. Try again.';
      });
    }
  }

  List<Widget> _sendButtons() {
    return [
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: context.bloom.strong,
          foregroundColor: context.bloom.onStrong,
        ),
        onPressed: _busy ? null : () => _submitPhone(OtpChannel.whatsapp),
        child: Text(_pendingLabel(OtpChannel.whatsapp, 'Get code on WhatsApp')),
      ),
      if (smsLoginLive) ...[
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _busy ? null : () => _submitPhone(OtpChannel.sms),
          child: Text(_pendingLabel(OtpChannel.sms, 'Get code by SMS')),
        ),
      ],
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : _continueGuest,
        child: const Text('Continue as guest'),
      ),
      _legalLine(),
    ];
  }

  Widget _legalLine() {
    final style = BloomlyType.uiText(12, color: context.bloom.textSecondary);
    final link = style.copyWith(
      color: context.bloom.strong,
      decoration: TextDecoration.underline,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('By continuing you agree to the ', style: style),
        GestureDetector(
          onTap: () => context.push('/account/terms'),
          child: Text('Terms', style: link),
        ),
        Text(' and ', style: style),
        GestureDetector(
          onTap: () => context.push('/account/privacy'),
          child: Text('Privacy policy', style: link),
        ),
        Text('.', style: style),
      ],
    );
  }

  void _continueGuest() {
    final next = safeReturnPath(
      GoRouterState.of(context).uri.queryParameters['next'],
    );
    if (next != null &&
        !next.startsWith('/owner') &&
        !next.startsWith('/rider')) {
      context.go(next);
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }

  String _pendingLabel(OtpChannel channel, String label) {
    if (_busy && _pendingChannel == channel) return 'Please wait…';
    return label;
  }

  Future<void> _submitEmailCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(backendProvider).startEmailLogin(_email.text);
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
      _channel = OtpChannel.email;
      _userId = result.userId;
      _code.clear();
      _step = _Step.otp;
      _armResend();
    });
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
      _armResend();
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
    final backend = ref.read(backendProvider);
    final error = _channel == OtpChannel.email
        ? await backend.verifyEmailOtp(userId: userId, code: _code.text)
        : await backend.verifyPhoneOtp(
            userId: userId,
            code: _code.text,
            channel: _channel,
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
    final profile = ref.read(backendProvider).currentUser;
    if (profile == null) {
      setState(() {
        _busy = false;
        _error = 'Could not sign in. Try again.';
      });
      return;
    }
    final landing = landingAfterSignIn(
      role: profile.role,
      next: GoRouterState.of(context).uri.queryParameters['next'],
    );
    final notice = landing.notice;
    if (notice != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(notice)));
    }
    context.go(landing.location);
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Container(
      height: 248,
      decoration: const BoxDecoration(
        color: Market.canvas,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(color: tokens.text),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'bloom',
                      style: BloomlyType.display(26, color: tokens.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: BloomlyType.display(28, color: tokens.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: BloomlyType.uiText(
                        14,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
