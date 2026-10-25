import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import 'cart_bar.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const destinations = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.grid_view_outlined, Icons.grid_view, 'Categories'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
    (Icons.person_outline, Icons.person, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final showCart = path == '/' || path.startsWith('/categories');
    final tokens = context.bloom;
    return ColoredBox(
      color: tokens.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ColoredBox(
            color: tokens.canvas,
            child: Column(
              children: [
                Expanded(child: shell),
                if (showCart) const CartBar(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    border: Border(top: BorderSide(color: tokens.border)),
                  ),
                  child: _CompactNav(shell: shell),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNav extends StatelessWidget {
  _CompactNav({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.bloom.surface,
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Row(
            children: [
              for (var index = 0; index < CustomerShell.destinations.length; index++)
                Expanded(
                  child: _NavItem(
                    selected: shell.currentIndex == index,
                    icon: CustomerShell.destinations[index].$1,
                    selectedIcon: CustomerShell.destinations[index].$2,
                    label: CustomerShell.destinations[index].$3,
                    onTap: () => shell.goBranch(
                      index,
                      initialLocation: index == shell.currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final color = selected ? tokens.link : tokens.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? tokens.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(selected ? selectedIcon : icon, size: 22, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BloomlyType.uiText(
                11,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
