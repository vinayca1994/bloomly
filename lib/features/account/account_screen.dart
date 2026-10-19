import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
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
                        color: Colors.white,
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
                              : (user.name.trim().isEmpty ? 'Bloomly customer' : user.name),
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
              child: const Text('Sign in'),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      final error = await ref.read(appLockProvider).setEnabled(value);
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => backend.signOut(),
              child: const Text('Log out'),
            ),
            if (!user.isOwner) ...[
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
                    content: Text('The store console is for the owner account.'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This deletes your Bloomly sign-in, saved addresses, and orders.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await ref.read(backendProvider).deleteAccount();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
