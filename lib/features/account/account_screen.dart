import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/autoplay.dart';
import '../../core/theme.dart';
import '../../data/auth_result.dart';
import '../../data/cart_controller.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../core/bloom_icons.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final user = backend.currentUser;
    final tokens = context.bloom;
    final lock = ref.watch(appLockProvider);
    final saved = user == null ? 0 : backend.addressesFor(user.id).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: tokens.sunken,
                  child: user == null || user.name.trim().isEmpty
                      ? Icon(BloomIcons.userFill, color: tokens.textSecondary)
                      : Text(
                          user.name.trim()[0].toUpperCase(),
                          style: BloomlyType.display(24, color: tokens.text),
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
                        style: BloomlyType.display(20, color: tokens.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.contact.isNotEmpty == true
                            ? user!.contact
                            : 'Sign in to place an order',
                        style: BloomlyType.uiText(
                          13,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (user == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign in'),
              ),
            ),
          _group(context, 'Autoplay videos', [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SegmentedButton<AutoplayChoice>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AutoplayChoice.always,
                    label: Text('Always'),
                  ),
                  ButtonSegment(
                    value: AutoplayChoice.wifi,
                    label: Text('Wi-Fi only'),
                  ),
                  ButtonSegment(
                    value: AutoplayChoice.never,
                    label: Text('Never'),
                  ),
                ],
                selected: {ref.watch(autoplayProvider).choice},
                onSelectionChanged: (value) {
                  ref.read(autoplayProvider).setChoice(value.first);
                },
              ),
            ),
          ]),
          if (user != null)
            _group(context, 'Orders, addresses and security', [
              _row(
                context,
                icon: BloomIcons.shoppingBag,
                title: 'Your orders',
                onTap: () => context.go('/orders'),
              ),
              _row(
                context,
                icon: BloomIcons.mapPin,
                title: 'Saved addresses',
                subtitle: saved == 0 ? 'None saved' : '$saved saved',
                onTap: () => context.push('/account/addresses'),
              ),
              if (lock.supported)
                _row(
                  context,
                  icon: BloomIcons.lock,
                  title: 'App lock',
                  subtitle: lock.label,
                  trailing: Switch(
                    value: lock.enabled,
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
            ]),
          _group(context, 'Legal', [
            _row(
              context,
              icon: BloomIcons.info,
              title: 'About bloom',
              onTap: () => context.push('/account/about'),
            ),
            _row(
              context,
              icon: BloomIcons.shield,
              title: 'Privacy',
              onTap: () => context.push('/account/privacy'),
            ),
            _row(
              context,
              icon: BloomIcons.receipt,
              title: 'Terms',
              onTap: () => context.push('/account/terms'),
            ),
          ]),
          if (user != null)
            _group(context, 'Account', [
              _row(
                context,
                icon: BloomIcons.signOut,
                title: 'Sign out',
                danger: true,
                onTap: () async {
                  final error = await backend.signOut();
                  if (error == null) {
                    ref.read(cartProvider.notifier).clear();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(error)));
                  }
                },
              ),
              if (!user.isOwner && !user.isRider)
                _row(
                  context,
                  icon: BloomIcons.trash,
                  title: 'Delete account',
                  danger: true,
                  onTap: () => _delete(context, ref),
                ),
            ]),
          _group(context, 'Staff', [
            if (user?.isOwner == true)
              _row(
                context,
                icon: BloomIcons.storefront,
                title: 'Open store console',
                onTap: () => context.go('/owner'),
              ),
            if (user?.isRider == true)
              _row(
                context,
                icon: BloomIcons.moped,
                title: 'Open deliveries',
                onTap: () => context.go('/rider'),
              ),
            _row(
              context,
              icon: BloomIcons.storefront,
              title: 'Store team sign in',
              subtitle: 'Owner and riders',
              onTap: () {
                if (user?.isOwner == true) {
                  context.go('/owner');
                } else if (user?.isRider == true) {
                  context.go('/rider');
                } else {
                  context.push('/login?next=/owner');
                }
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> rows) {
    final tokens = context.bloom;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: BloomlyType.uiText(
                12,
                weight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BloomlyDecor.card(tokens, radius: 16),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i != rows.length - 1)
                    Divider(height: 1, color: tokens.border),
                ],
              ],
            ),
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

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool danger = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final tokens = context.bloom;
    final color = danger ? tokens.danger : tokens.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: BloomlyType.uiText(
                          15,
                          weight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: BloomlyType.uiText(
                            12,
                            color: tokens.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
                if (trailing == null && onTap != null)
                  Icon(BloomIcons.caretRight, color: tokens.textSecondary),
              ],
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
              child: Text(
                _codeSent ? 'Send the code again' : 'Send a code on WhatsApp',
              ),
            ),
          ],
          if (_error != null) ...[
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: context.bloom.danger)),
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
        .startPhoneLogin(widget.user.phone, channel: OtpChannel.whatsapp);
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
          channel: OtpChannel.whatsapp,
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
