import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import 'cart_bar.dart';
import '../../core/bloom_icons.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const destinations = <(IconData, IconData, String)>[
    (BloomIcons.house, BloomIcons.houseFill, 'Home'),
    (BloomIcons.squares, BloomIcons.squaresFill, 'Categories'),
    (BloomIcons.receipt, BloomIcons.receiptFill, 'Orders'),
    (BloomIcons.user, BloomIcons.userFill, 'Account'),
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
                    border: Border(
                      top: BorderSide(color: tokens.border, width: 0.5),
                    ),
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
  const _CompactNav({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (
                var index = 0;
                index < CustomerShell.destinations.length;
                index++
              )
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
  const _NavItem({
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
    final color = selected ? tokens.primary : tokens.textSecondary;
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
            Icon(selected ? selectedIcon : icon, size: 24, color: color),
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
