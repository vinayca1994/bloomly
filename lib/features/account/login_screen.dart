import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/memory_backend.dart';
import '../../data/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _create = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('bloomly')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Fresh in minutes.',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vegetables, fruit, and regional flowers.',
            style: TextStyle(color: BloomlyColors.muted),
          ),
          const SizedBox(height: 20),
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: BloomlyColors.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Please wait…' : (_create ? 'Create account' : 'Sign in')),
          ),
          TextButton(
            onPressed: () => setState(() {
              _create = !_create;
              _error = null;
            }),
            child: Text(_create ? 'I already have an account' : 'Create an account'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Demo accounts',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 8),
          Text(
            'Password ${MemoryBackend.demoPassword}',
            style: const TextStyle(color: BloomlyColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _fill(String email) {
    setState(() {
      _create = false;
      _email.text = email;
      _password.text = MemoryBackend.demoPassword;
      _error = null;
    });
  }

  Future<void> _submit() async {
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
