import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../core/bloom_icons.dart';

class RidersScreen extends ConsumerStatefulWidget {
  const RidersScreen({super.key});

  @override
  ConsumerState<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends ConsumerState<RidersScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  String? _notice;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final riders = backend.riders;
    final demo = backend.demoShortcuts;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Add a rider', style: BloomlyType.display(22)),
        SizedBox(height: 8),
        Text(
          demo
              ? 'The rider signs in with this email and password, then shares location from their phone.'
              : 'Bloom emails a sign-in code. The rider opens the app and taps Forgot password.',
          style: TextStyle(color: context.bloom.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        if (demo) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ],
        if (_error != null) ...[
          SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: context.bloom.danger)),
        ],
        if (_notice != null) ...[
          SizedBox(height: 8),
          Text(_notice!, style: TextStyle(color: context.bloom.link)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _add,
          child: const Text('Add rider'),
        ),
        const SizedBox(height: 24),
        Text('Riders', style: BloomlyType.display(22)),
        SizedBox(height: 8),
        if (riders.isEmpty)
          Text('No riders yet', style: TextStyle(color: context.bloom.textSecondary))
        else
          for (final rider in riders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(BloomIcons.moped),
              title: Text(rider.name),
              subtitle: Text(rider.email.isEmpty ? 'Rider' : rider.email),
            ),
      ],
    );
  }

  Future<void> _add() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    final demo = ref.read(backendProvider).demoShortcuts;
    final error = await ref.read(backendProvider).createRider(
      name: _name.text,
      email: _email.text,
      password: demo ? _password.text : '',
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error == null) {
        _name.clear();
        _email.clear();
        _password.clear();
        _notice = demo
            ? null
            : 'We emailed a sign-in code. The rider opens Bloom and taps Forgot password.';
      }
    });
  }
}
