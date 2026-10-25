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
    return ColoredBox(
      color: BloomlyColors.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ColoredBox(
            color: Colors.white,
            child: Theme(
              data: Theme.of(context).copyWith(
                scaffoldBackgroundColor: Colors.white,
                appBarTheme: Theme.of(context).appBarTheme
                    .copyWith(backgroundColor: Colors.white),
              ),
              child: Column(
                children: [
                  Expanded(child: shell),
                  if (showCart) const CartBar(),
                  const Divider(height: 1),
                  _CompactNav(shell: shell),
                ],
              ),
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
      color: Colors.white,
      child: SizedBox(
        height: 56,
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
    final color = selected ? BloomlyColors.amber : BloomlyColors.muted;
    return Semantics(
      button: true,
      selected: selected ? true : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, size: 18, color: color),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                inherit: false,
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
