import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class OwnerShell extends StatelessWidget {
  const OwnerShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final nav = _Nav(path: path, onSelect: (route) => context.go(route));
    if (wide) {
      return Scaffold(
        backgroundColor: BloomlyColors.background,
        body: Row(
          children: [
            SizedBox(width: 240, child: Material(color: Colors.white, child: nav)),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_title(path))),
      drawer: Drawer(child: SafeArea(child: nav)),
      body: child,
    );
  }

  String _title(String path) {
    if (path.startsWith('/owner/catalog')) return 'Catalog';
    if (path.startsWith('/owner/orders')) return 'Orders';
    return 'Today';
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.path, required this.onSelect});

  final String path;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(
            'bloomly',
            style: TextStyle(
              color: BloomlyColors.green,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _item(context, '/owner', 'Today', Icons.today_outlined),
        _item(context, '/owner/orders', 'Orders', Icons.receipt_long_outlined),
        _item(context, '/owner/catalog', 'Catalog', Icons.inventory_2_outlined),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: const Text('Back to shop'),
          onTap: () => onSelect('/'),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, String route, String label, IconData icon) {
    final selected = route == '/owner'
        ? path == '/owner'
        : path.startsWith(route);
    return ListTile(
      selected: selected,
      selectedColor: BloomlyColors.greenDark,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: () => onSelect(route),
    );
  }
}
