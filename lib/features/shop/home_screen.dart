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
import '../../data/stories.dart';
import 'product_card.dart';
import 'story_banner.dart';
import 'story_clips.dart';
import 'story_placements.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _tab = 'all';

  @override
  Widget build(BuildContext context) {
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
    final outside =
        city.isNotEmpty &&
        city.trim().toLowerCase() != backend.store.city.trim().toLowerCase();
    final forSale = backend.products.where((product) => product.forSale).toList();
    final now = DateTime.now();
    final promos = backend.store.promotions;
    final festival = _festival(promos, now);
    final look = festival == null ? null : promoLook(festival.themeId);
    final hints = [
      for (final product in forSale) product.name,
    ];
    final tabs = [
      _Tab('all', 'All', BloomIcons.squaresDuo),
      _Tab('vegetables', 'Vegetables', BloomIcons.plantDuo),
      _Tab('fruits', 'Fruits', BloomIcons.orangeDuo),
      _Tab('flowers', 'Flowers', BloomIcons.flowerDuo),
      _Tab('puja', 'Puja', BloomIcons.lotusDuo),
      _Tab('gifting', 'Gifting', BloomIcons.giftDuo),
      if (festival != null)
        _Tab(
          'festival',
          _festivalName(festival.themeId),
          BloomIcons.lampDuo,
        ),
    ];

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
                ground: look?.ground,
                ink: look?.ink,
                initial: backend.currentUser?.name,
                onAddress: () => _openAddress(context, backend.currentUser != null),
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
              child: OfferStrip(
                stories: activeStories(
                  StoryPlacement.offerStrip,
                  now,
                  source: promos,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoryTabs(
                tabs: tabs,
                selected: _tab,
                onSelect: (id) => setState(() => _tab = id),
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
                aspect: 16 / 9,
              ),
            ),
            SliverToBoxAdapter(
              child: StoryTileGrid(
                stories: activeStories(
                  StoryPlacement.tileGrid,
                  now,
                  source: promos,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StoryClipRail(
                stories: activeStories(
                  StoryPlacement.homeClip,
                  now,
                  source: promos,
                ),
              ),
            ),
            if (_tab == 'all') ...[
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Fresh today',
                  onSeeAll: () => context.go('/categories/vegetables'),
                  products: _pick(forSale, freshTodayIds),
                ),
              ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Regional flowers',
                  onSeeAll: () => context.go('/categories/flowers'),
                  products: _pick(forSale, regionalFlowerIds),
                ),
              ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Bestsellers',
                  onSeeAll: () => context.go('/categories/fruits'),
                  products: _pick(forSale, bestsellerIds),
                ),
              ),
            ] else
              SliverToBoxAdapter(
                child: _FilteredShelf(
                  title: tabs.where((tab) => tab.id == _tab).firstOrNull?.label ?? '',
                  products: _filtered(forSale, backend, _tab, festival),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  void _openAddress(BuildContext context, bool signedIn) {
    if (GoRouter.maybeOf(context) == null) return;
    if (signedIn) {
      context.push('/account/addresses');
    } else {
      context.push('/login?next=${Uri.encodeComponent('/account/addresses')}');
    }
  }
}

class _Tab {
  const _Tab(this.id, this.label, this.icon);
  final String id;
  final String label;
  final (IconData, IconData) icon;
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

List<Product> _filtered(
  List<Product> products,
  BloomlyBackend backend,
  String tab,
  Story? festival,
) {
  bool match(Product product) {
    final category = backend.categories
        .where((item) => item.slug == product.categorySlug)
        .firstOrNull;
    if (category == null) return false;
    final group = category.parentSlug ?? category.slug;
    return switch (tab) {
      'vegetables' => group == 'vegetables',
      'fruits' => group == 'fruits',
      'flowers' || 'puja' => group == 'flowers',
      'gifting' =>
        product.categorySlug == 'garlands' || product.categorySlug == 'bunches',
      'festival' => group == 'flowers' || (festival?.route ?? '').contains(group),
      _ => true,
    };
  }

  return products.where(match).toList();
}

Address? _defaultAddress(BloomlyBackend backend) {
  final user = backend.currentUser;
  if (user == null) return null;
  final list = backend.addressesFor(user.id);
  if (list.isEmpty) return null;
  return list.where((address) => address.isDefault).firstOrNull ?? list.first;
}

List<Product> _pick(List<Product> products, List<String> ids) {
  return [
    for (final id in ids)
      if (products.where((product) => product.id == id).firstOrNull != null)
        products.firstWhere((product) => product.id == id),
  ];
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
    required this.initial,
    required this.onAddress,
    required this.onProfile,
    this.ground,
    this.ink,
  });

  final String eta;
  final String title;
  final String subtitle;
  final bool outside;
  final String city;
  final String? initial;
  final VoidCallback onAddress;
  final VoidCallback onProfile;
  final Color? ground;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final fg = ink ?? tokens.text;
    final letter = (initial == null || initial!.isEmpty)
        ? 'B'
        : initial![0].toUpperCase();
    return ColoredBox(
      color: ground ?? tokens.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          style: BloomlyType.display(22, color: fg),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              title,
                              style: BloomlyType.uiText(
                                14,
                                weight: FontWeight.w700,
                                color: fg,
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
                                  color: ink == null ? tokens.textSecondary : fg,
                                ),
                              ),
                            ),
                            Icon(BloomIcons.caretDown, size: 16, color: fg),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  button: true,
                  label: 'Account',
                  child: InkWell(
                    onTap: onProfile,
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: tokens.secondary,
                      child: Text(
                        letter,
                        style: BloomlyType.uiText(
                          14,
                          weight: FontWeight.w800,
                          color: tokens.onSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (outside) ...[
              const SizedBox(height: 8),
              Text(
                'Bloom delivers in $city only.',
                style: BloomlyType.uiText(
                  14,
                  weight: FontWeight.w600,
                  color: tokens.danger,
                ),
              ),
            ],
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
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: context.bloom.canvas,
      elevation: overlapsContent ? 1 : 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.border),
          ),
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
                        style: BloomlyType.uiText(14, color: tokens.textSecondary),
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

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<_Tab> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final active = tab.id == selected;
          final color = active ? tokens.primary : tokens.textSecondary;
          return Semantics(
            button: true,
            selected: active,
            label: tab.label,
            child: InkWell(
              onTap: () => onSelect(tab.id),
              child: SizedBox(
                width: 76,
                child: Column(
                  children: [
                    BloomDuotone(tab.icon, size: 24, color: color),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BloomlyType.uiText(
                        12,
                        weight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: active ? tokens.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilteredShelf extends StatelessWidget {
  const _FilteredShelf({required this.title, required this.products});

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Nothing on this shelf right now.',
          style: BloomlyType.uiText(14, color: context.bloom.textSecondary),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: BloomlyType.display(20, color: context.bloom.text)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              mainAxisExtent: 268,
            ),
            itemBuilder: (context, index) => ProductCard(product: products[index]),
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
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
                  style: BloomlyType.display(20, color: context.bloom.text),
                ),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          SizedBox(
            height: 268,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 148,
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
