import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import 'cart_bar.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

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
            color: BloomlyColors.background,
            child: Column(
              children: [
                Expanded(child: shell),
                if (showCart) const CartBar(),
                NavigationBar(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: (index) => shell.goBranch(
                    index,
                    initialLocation: index == shell.currentIndex,
                  ),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view),
                      label: 'Categories',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: 'Orders',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Account',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
