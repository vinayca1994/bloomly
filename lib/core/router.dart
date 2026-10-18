import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/account/account_screen.dart';
import '../features/account/addresses_screen.dart';
import '../features/account/login_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/cart/checkout_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/orders/tracking_screen.dart';
import '../features/owner/catalog_screen.dart';
import '../features/owner/owner_orders_screen.dart';
import '../features/owner/owner_shell.dart';
import '../features/owner/product_editor.dart';
import '../features/owner/today_screen.dart';
import '../features/shop/category_screen.dart';
import '../features/shop/home_screen.dart';
import '../features/shop/search_screen.dart';
import '../features/shop/shop_shell.dart';
import 'widgets.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  final backend = ref.read(backendProvider);
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/',
    refreshListenable: backend,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!path.startsWith('/owner')) return null;
      final user = backend.currentUser;
      if (user == null) {
        return '/login?next=${Uri.encodeComponent(path)}';
      }
      if (!user.isOwner) return '/account';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => CustomerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoryScreen(),
                routes: [
                  GoRoute(
                    path: ':group',
                    builder: (context, state) =>
                        CategoryScreen(group: state.pathParameters['group']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => PhoneFrame(
                      child: TrackingScreen(orderId: state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountScreen(),
                routes: [
                  GoRoute(
                    path: 'addresses',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) =>
                        const PhoneFrame(child: AddressesScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const PhoneFrame(child: SearchScreen()),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const PhoneFrame(child: CartScreen()),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const PhoneFrame(child: CheckoutScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PhoneFrame(child: LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => OwnerShell(child: child),
        routes: [
          GoRoute(path: '/owner', builder: (context, state) => const TodayScreen()),
          GoRoute(
            path: '/owner/orders',
            builder: (context, state) => const OwnerOrdersScreen(),
          ),
          GoRoute(
            path: '/owner/catalog',
            builder: (context, state) => const CatalogScreen(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: rootKey,
                builder: (context, state) => const ProductEditor(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootKey,
                builder: (context, state) =>
                    ProductEditor(productId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
