import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/auth_result.dart';
import '../../data/cart_controller.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final user = backend.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DecoratedBox(
            decoration: BloomlyDecor.card(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: BloomlyColors.green,
                    child: Text(
                      (user == null || user.name.isEmpty)
                          ? 'B'
                          : user.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: BloomlyColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user == null
                              ? 'Guest'
                              : (user.name.trim().isEmpty
                                    ? 'Bloom customer'
                                    : user.name),
                          style: BloomlyType.display(24),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.contact.isNotEmpty == true
                              ? user!.contact
                              : 'Sign in to place an order',
                          style: const TextStyle(color: BloomlyColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (user == null)
            FilledButton(
              onPressed: () => context.push('/login'),
              child: Text(
                'Sign in',
                style: BloomlyType.label.copyWith(color: BloomlyColors.ink),
              ),
            )
          else ...[
            _tile(
              icon: Icons.location_on_outlined,
              title: 'Addresses',
              onTap: () => context.push('/account/addresses'),
            ),
            _tile(
              icon: Icons.receipt_long_outlined,
              title: 'Orders',
              onTap: () => context.go('/orders'),
            ),
            if (ref.watch(appLockProvider).supported)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DecoratedBox(
                  decoration: BloomlyDecor.card(),
                  child: SwitchListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Unlock with ${ref.watch(appLockProvider).label}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Face ID or fingerprint opens the app. Your password stays with the account.',
                    ),
                    value: ref.watch(appLockProvider).enabled,
                    activeThumbColor: BloomlyColors.green,
                    onChanged: (value) async {
                      final error = await ref
                          .read(appLockProvider)
                          .setEnabled(value);
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
                  ),
                ),
              ),
            if (user.isOwner)
              _tile(
                icon: Icons.storefront_outlined,
                title: 'Open store console',
                onTap: () => context.go('/owner'),
              ),
            if (user.isRider)
              _tile(
                icon: Icons.delivery_dining_outlined,
                title: 'Open deliveries',
                onTap: () => context.go('/rider'),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final error = await backend.signOut();
                if (error == null) {
                  ref.read(cartProvider.notifier).clear();
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              },
              child: const Text('Log out'),
            ),
            if (!user.isOwner && !user.isRider) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _delete(context, ref),
                child: const Text(
                  'Delete account',
                  style: TextStyle(color: BloomlyColors.danger),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          _tile(
            icon: Icons.local_florist_outlined,
            title: 'About Bloom',
            onTap: () => context.push('/account/about'),
          ),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            onTap: () => context.push('/account/privacy'),
          ),
          _tile(
            icon: Icons.store_outlined,
            title: 'Store team sign in',
            onTap: () {
              if (user?.isOwner == true) {
                context.go('/owner');
              } else if (user != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'The store console is for the owner account.',
                    ),
                  ),
                );
              } else {
                context.push('/login?next=/owner');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final user = ref.read(backendProvider).currentUser;
    if (user == null) return;
    final secret = await showDialog<String>(
      context: context,
      builder: (context) => _DeleteAccountDialog(user: user),
    );
    if (secret == null || !context.mounted) return;
    final error = await ref
        .read(backendProvider)
        .deleteAccount(password: user.email.isEmpty ? null : secret);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BloomlyDecor.card(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: BloomlyColors.leafWash,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: BloomlyColors.greenDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: BloomlyColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog({required this.user});

  final Profile user;

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _secret = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _secret.dispose();
    super.dispose();
  }

  bool get _email => widget.user.email.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This deletes your Bloom sign-in, saved addresses, and orders.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _secret,
            obscureText: _email,
            keyboardType: _email
                ? TextInputType.visiblePassword
                : TextInputType.number,
            decoration: InputDecoration(
              labelText: _email ? 'Password' : 'Login code',
            ),
          ),
          if (!_email) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _sendCode,
              child: Text(_codeSent ? 'Send the code again' : 'Send a code'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: BloomlyColors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final started = await ref
        .read(backendProvider)
        .startPhoneLogin(widget.user.phone, channel: OtpChannel.sms);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeSent = started.ok;
      _error = started.ok ? null : started.error;
    });
  }

  Future<void> _confirm() async {
    final secret = _secret.text.trim();
    if (_email) {
      if (secret.length < 8) {
        setState(() => _error = 'Enter your password to delete the account.');
        return;
      }
      Navigator.pop(context, secret);
      return;
    }
    if (!_codeSent) {
      setState(() => _error = 'Send a code first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref
        .read(backendProvider)
        .verifyPhoneOtp(
          userId: widget.user.id,
          code: secret,
          channel: OtpChannel.sms,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context, secret);
  }
}
