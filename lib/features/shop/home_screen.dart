import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloom_icons.dart';
import '../../core/theme.dart';
import '../../data/backend.dart';
import '../../data/catalog_seed.dart';
import '../../data/demo_promos.dart';
import '../../data/models.dart';
import '../../data/promo_templates.dart';
import '../../data/providers.dart';
import '../../data/service_area.dart';
import '../../data/stories.dart';
import 'aisle_circle.dart';
import 'product_card.dart';
import 'story_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final detected = ref.watch(placeProvider).place;
    final address = _defaultAddress(backend);
    final title = address?.label ?? 'Deliver to';
    final subtitle = address != null
        ? '${address.area}, ${address.city}'
        : (detected != null && detected.city.isNotEmpty)
        ? (detected.area.isEmpty
              ? detected.city
              : '${detected.area}, ${detected.city}')
        : '${backend.store.city} · Set your address';
    final city = address?.city ?? detected?.city ?? '';
    final pin = address?.pincode ?? detected?.pincode ?? '';
    final outside = outsideDelivery(
      city: city,
      pincode: pin,
      storeCity: backend.store.city,
      storePincode: backend.store.pincode,
    );
    final forSale = backend.products
        .where((product) => product.forSale)
        .toList();
    final now = DateTime.now();
    final promos = backend.store.promotions;
    final festival = _festival(promos, now);
    final hints = [for (final product in forSale) product.name];
    final aisles = [
      const _Aisle('vegetables', 'Vegetables', '/categories/vegetables'),
      const _Aisle('fruits', 'Fruits', '/categories/fruits'),
      const _Aisle('flowers', 'Flowers', '/categories/flowers'),
      const _Aisle('puja', 'Puja', '/categories/flowers'),
      const _Aisle(
        'gifting',
        'Gifting',
        '/categories/flowers?sub=garlands',
      ),
      if (festival != null)
        _Aisle(
          festival.themeId.isEmpty ? 'festival' : festival.themeId,
          _festivalName(festival.themeId),
          _festivalRoute(festival),
        ),
    ];
    final again = _orderAgain(backend, forSale);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _LocationProbe()),
            SliverToBoxAdapter(
              child: _Header(
                eta: backend.store.etaLabel,
                title: title,
                subtitle: subtitle,
                outside: outside,
                city: backend.store.city,
                pincode: backend.store.pincode,
                initial: backend.currentUser?.name,
                onAddress: () =>
                    _openAddress(context, backend.currentUser != null),
                onProfile: () {
                  if (GoRouter.maybeOf(context) == null) return;
                  context.go('/account');
                },
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeader(
                child: _RotatingSearch(
                  hints: hints.isEmpty
                      ? const ['Search vegetables, fruits, flowers']
                      : hints,
                  onTap: () => context.push('/search'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _AisleGrid(
                aisles: aisles,
                onOpen: (route) {
                  if (GoRouter.maybeOf(context) == null) return;
                  context.go(route);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: StoryBanner(
                stories: activeStories(
                  StoryPlacement.homeBanner,
                  now,
                  source: promos,
                ),
                bleed: true,
                aspect: 2.4,
              ),
            ),
            if (!backend.ready)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (forSale.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyShelf(
                  title: 'The shop is empty',
                  body:
                      'New crates show up here when the store publishes them.',
                ),
              )
            else ...[
              if (again.isNotEmpty)
                SliverToBoxAdapter(
                  child: _RowSection(
                    title: 'Order again',
                    onSeeAll: () {
                      if (GoRouter.maybeOf(context) == null) return;
                      context.go('/orders');
                    },
                    products: again,
                  ),
                ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Fresh today',
                  onSeeAll: () {
                    if (GoRouter.maybeOf(context) == null) return;
                    context.go('/categories/vegetables');
                  },
                  products: _pick(forSale, freshTodayIds),
                ),
              ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Regional flowers',
                  onSeeAll: () {
                    if (GoRouter.maybeOf(context) == null) return;
                    context.go('/categories/flowers');
                  },
                  products: _pick(forSale, regionalFlowerIds),
                ),
              ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Bestsellers',
                  onSeeAll: () {
                    if (GoRouter.maybeOf(context) == null) return;
                    context.go('/categories/fruits');
                  },
                  products: _pick(forSale, bestsellerIds),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

class _Aisle {
  const _Aisle(this.id, this.label, this.route);

  final String id;
  final String label;
  final String route;
}

Story? _festival(List<Story> source, DateTime now) {
  for (final id in festivalThemeIds) {
    for (final story in source) {
      if (story.themeId == id && story.isActiveAt(now)) return story;
    }
  }
  return null;
}

String _festivalName(String themeId) {
  for (final template in promoTemplates) {
    if (template.id == themeId) return template.name;
  }
  if (themeId.isEmpty) return 'Festival';
  return themeId[0].toUpperCase() + themeId.substring(1);
}

String _festivalRoute(Story festival) {
  final route = festival.route ?? '';
  if (route.startsWith('/categories')) return route;
  return '/categories/flowers';
}

Address? _defaultAddress(BloomlyBackend backend) {
  final user = backend.currentUser;
  if (user == null) return null;
  final list = backend.addressesFor(user.id);
  if (list.isEmpty) return null;
  return list.where((address) => address.isDefault).firstOrNull ?? list.first;
}

List<Product> _orderAgain(BloomlyBackend backend, List<Product> forSale) {
  final user = backend.currentUser;
  if (user == null) return const [];
  final delivered =
      backend.orders
          .where(
            (order) =>
                order.userId == user.id &&
                order.status == OrderStatus.delivered,
          )
          .toList()
        ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
  final ids = <String>[];
  for (final order in delivered) {
    for (final item in order.items) {
      if (!ids.contains(item.productId)) ids.add(item.productId);
    }
  }
  return _pick(forSale, ids);
}

List<Product> _pick(List<Product> products, List<String> ids) {
  return [
    for (final id in ids)
      if (products.where((product) => product.id == id).firstOrNull != null)
        products.firstWhere((product) => product.id == id),
  ];
}

void _openAddress(BuildContext context, bool signedIn) {
  if (GoRouter.maybeOf(context) == null) return;
  if (signedIn) {
    context.push('/account/addresses');
  } else {
    context.push('/login?next=${Uri.encodeComponent('/account/addresses')}');
  }
}

class _LocationProbe extends ConsumerStatefulWidget {
  const _LocationProbe();

  @override
  ConsumerState<_LocationProbe> createState() => _LocationProbeState();
}

class _LocationProbeState extends ConsumerState<_LocationProbe> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(placeProvider).detect());
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Header extends StatelessWidget {
  const _Header({
    required this.eta,
    required this.title,
    required this.subtitle,
    required this.outside,
    required this.city,
    required this.pincode,
    required this.initial,
    required this.onAddress,
    required this.onProfile,
  });

  final String eta;
  final String title;
  final String subtitle;
  final bool outside;
  final String city;
  final String pincode;
  final String? initial;
  final VoidCallback onAddress;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return ColoredBox(
      color: tokens.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: onAddress,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eta,
                      style: BloomlyType.display(26, color: tokens.primary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          style: BloomlyType.uiText(
                            14,
                            weight: FontWeight.w700,
                            color: tokens.text,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ' · $subtitle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BloomlyType.uiText(
                              14,
                              weight: FontWeight.w600,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        Icon(
                          BloomIcons.caretDown,
                          size: 16,
                          color: tokens.text,
                        ),
                      ],
                    ),
                    if (outside) ...[
                      const SizedBox(height: 6),
                      Text(
                        deliveryAreaMessage(city, pincode: pincode),
                        style: BloomlyType.uiText(
                          13,
                          weight: FontWeight.w600,
                          color: tokens.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Semantics(
              button: true,
              label: initial == null || initial!.isEmpty
                  ? 'Account'
                  : 'Account, $initial',
              child: InkWell(
                onTap: onProfile,
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: tokens.sunken,
                  child: Icon(
                    BloomIcons.userFill,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends SliverPersistentHeaderDelegate {
  _SearchHeader({required this.child});

  final Widget child;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: context.bloom.canvas,
      elevation: overlapsContent ? 1 : 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchHeader oldDelegate) => child != oldDelegate.child;
}

class _RotatingSearch extends StatefulWidget {
  const _RotatingSearch({required this.hints, required this.onTap});

  final List<String> hints;
  final VoidCallback onTap;

  @override
  State<_RotatingSearch> createState() => _RotatingSearchState();
}

class _RotatingSearchState extends State<_RotatingSearch> {
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
    } else {
      _arm();
    }
  }

  @override
  void didUpdateWidget(_RotatingSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hints.length != oldWidget.hints.length) _index = 0;
  }

  void _arm() {
    _timer?.cancel();
    if (widget.hints.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      setState(() => _index = (_index + 1) % widget.hints.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final hint = widget.hints[_index % widget.hints.length];
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderStrong),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(BloomIcons.search, color: tokens.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: reduce
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, 0.8),
                        end: Offset.zero,
                      ).animate(animation);
                      return ClipRect(
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: Align(
                      key: ValueKey(reduce ? widget.hints.first : hint),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        reduce ? widget.hints.first : hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BloomlyType.uiText(
                          14,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
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

class _AisleGrid extends StatelessWidget {
  const _AisleGrid({required this.aisles, required this.onOpen});

  final List<_Aisle> aisles;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final aisle in aisles)
            AisleCircle(
              label: aisle.label,
              emoji: aisleEmoji(aisle.id),
              icon: BloomIcons.festival,
              selected: false,
              onTap: () => onOpen(aisle.route),
            ),
        ],
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(BloomIcons.basket, size: 36, color: tokens.textSecondary),
          const SizedBox(height: 12),
          Text(title, style: BloomlyType.display(22, color: tokens.text)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: BloomlyType.uiText(14, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RowSection extends StatelessWidget {
  const _RowSection({
    required this.title,
    required this.products,
    required this.onSeeAll,
  });

  final String title;
  final List<Product> products;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BloomlyType.display(18, color: context.bloom.text),
                ),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          SizedBox(
            height: productCardExtent,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 132,
                  child: ProductCard(product: products[index], compact: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
