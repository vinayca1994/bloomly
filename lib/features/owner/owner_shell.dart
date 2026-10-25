import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/cart_controller.dart';
import '../../data/providers.dart';
import '../../core/bloom_icons.dart';

class OwnerShell extends StatelessWidget {
  const OwnerShell({required this.child, super.key});

  final Widget child;

  static const _wide = 900.0;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final wide = MediaQuery.sizeOf(context).width >= _wide;
    final tokens = context.bloom;
    if (wide) {
      return Scaffold(
        backgroundColor: tokens.canvas,
        body: Row(
          children: [
            SizedBox(
              width: 248,
              child: Material(
                color: tokens.surface,
                child: _Side(path: path),
              ),
            ),
            VerticalDivider(width: 1, color: tokens.border),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(title: Text(_title(path))),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _phoneIndex(path),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/owner');
            case 1:
              context.go('/owner/orders');
            case 2:
              context.go('/owner/promotions');
            default:
              _more(context);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(BloomIcons.sun), label: 'Today'),
          NavigationDestination(icon: Icon(BloomIcons.receipt), label: 'Orders'),
          NavigationDestination(icon: Icon(BloomIcons.megaphone), label: 'Promos'),
          NavigationDestination(icon: Icon(BloomIcons.more), label: 'More'),
        ],
      ),
    );
  }

  int _phoneIndex(String path) {
    if (path.startsWith('/owner/orders')) return 1;
    if (path.startsWith('/owner/promotions')) return 2;
    if (path == '/owner') return 0;
    return 3;
  }

  String _title(String path) {
    if (path.startsWith('/owner/catalog')) return 'Catalog';
    if (path.startsWith('/owner/promotions')) return 'Promotions';
    if (path.startsWith('/owner/orders')) return 'Orders';
    if (path.startsWith('/owner/riders')) return 'Riders';
    if (path.startsWith('/owner/settings')) return 'Settings';
    return 'Today';
  }

  void _more(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const SafeArea(child: _MoreSheet()),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 16, 20),
          child: Text('bloom', style: BloomlyType.display(26, color: tokens.link)),
        ),
        _item(context, '/owner', 'Today', BloomIcons.sun),
        _item(context, '/owner/orders', 'Orders', BloomIcons.receipt),
        _item(context, '/owner/promotions', 'Promotions', BloomIcons.megaphone),
        _item(context, '/owner/catalog', 'Catalog', BloomIcons.package),
        _item(context, '/owner/riders', 'Riders', BloomIcons.moped),
        _item(context, '/owner/settings', 'Settings', BloomIcons.gear),
        const Spacer(),
        const _SignOutTile(),
        ListTile(
          leading: const Icon(BloomIcons.storefront),
          title: const Text('Back to shop'),
          onTap: () => context.go('/'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _item(BuildContext context, String route, String label, IconData icon) {
    final tokens = context.bloom;
    final selected = route == '/owner' ? path == '/owner' : path.startsWith(route);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: tokens.secondary,
        selectedColor: tokens.onSecondary,
        iconColor: selected ? tokens.onSecondary : tokens.textSecondary,
        textColor: selected ? tokens.onSecondary : tokens.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        onTap: () => context.go(route),
      ),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(BloomIcons.package),
          title: const Text('Catalog'),
          onTap: () => _go(context, '/owner/catalog'),
        ),
        ListTile(
          leading: const Icon(BloomIcons.moped),
          title: const Text('Riders'),
          onTap: () => _go(context, '/owner/riders'),
        ),
        ListTile(
          leading: const Icon(BloomIcons.gear),
          title: const Text('Settings'),
          onTap: () => _go(context, '/owner/settings'),
        ),
        ListTile(
          leading: const Icon(BloomIcons.storefront),
          title: const Text('Back to shop'),
          onTap: () => _go(context, '/'),
        ),
        const _SignOutTile(),
      ],
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }
}

class _SignOutTile extends ConsumerWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(BloomIcons.signOut, color: context.bloom.danger),
      title: Text('Sign out', style: TextStyle(color: context.bloom.danger)),
      onTap: () async {
        final nav = Navigator.of(context);
        final router = GoRouter.of(context);
        if (nav.canPop()) nav.pop();
        final error = await ref.read(backendProvider).signOut();
        if (error == null) {
          ref.read(cartProvider.notifier).clear();
          router.go('/');
        }
      },
    );
  }
}
