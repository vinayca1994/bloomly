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
          Row(
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
                      user?.name ?? 'Guest',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      user?.email ?? 'Sign in to place an order',
                      style: const TextStyle(color: BloomlyColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          ],
          const SizedBox(height: 16),
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

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: BloomlyColors.line),
      ),
      child: ListTile(
        leading: Icon(icon, color: BloomlyColors.greenDark),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
