import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloom_icons.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/stories.dart';
import 'aisle_circle.dart';
import 'product_card.dart';
import 'promo_card.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({this.group, super.key});

  final String? group;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

enum _Sort { featured, priceLow, priceHigh, name }

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  static const _regions = ['All', 'North', 'South', 'East', 'West'];
  String _sub = '';
  String _region = 'All';
  String? _groupOverride;
  _Sort _sort = _Sort.featured;
  bool _syncedRoute = false;
  String? _routeSub;

  String get _group => _groupOverride ?? widget.group ?? 'vegetables';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final sub = GoRouterState.of(context).uri.queryParameters['sub'] ?? '';
    if (_syncedRoute && sub == _routeSub) return;
    _syncedRoute = true;
    _routeSub = sub;
    _sub = sub;
    _groupOverride = null;
  }

  @override
  void didUpdateWidget(CategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group) {
      final router = GoRouter.maybeOf(context);
      final sub = router == null
          ? ''
          : GoRouterState.of(context).uri.queryParameters['sub'] ?? '';
      _sub = sub;
      _routeSub = sub;
      _region = 'All';
      _groupOverride = null;
      _syncedRoute = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final tokens = context.bloom;
    final groups = backend.categories.where((item) => item.isGroup).toList();
    final subs =
        backend.categories.where((item) => item.parentSlug == _group).toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));
    final title =
        groups.where((item) => item.slug == _group).firstOrNull?.name ??
        'Categories';
    final products = backend.products.where((product) {
      final category = backend.categories
          .where((item) => item.slug == product.categorySlug)
          .firstOrNull;
      if (category == null || !product.forSale) return false;
      final inGroup = category.slug == _group || category.parentSlug == _group;
      if (!inGroup) return false;
      if (_sub.isNotEmpty && product.categorySlug != _sub) return false;
      if (_group == 'flowers' &&
          _region != 'All' &&
          product.region != _region) {
        return false;
      }
      return true;
    }).toList();
    switch (_sort) {
      case _Sort.featured:
        products.sort((a, b) => a.sort.compareTo(b.sort));
      case _Sort.priceLow:
        products.sort((a, b) => a.lead.price.compareTo(b.lead.price));
      case _Sort.priceHigh:
        products.sort((a, b) => b.lead.price.compareTo(a.lead.price));
      case _Sort.name:
        products.sort((a, b) => a.name.compareTo(b.name));
    }
    final known = groups.any((item) => item.slug == _group);
    final shelves = _shelves(title, subs, products);

    final promos =
        activeStories(
          StoryPlacement.category,
          DateTime.now(),
          source: backend.store.promotions,
        ).where((story) {
          final route = story.route ?? '';
          return route.isEmpty || route.contains('/categories/$_group');
        }).toList();

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              if (GoRouter.maybeOf(context) == null) return;
              context.push('/search');
            },
            icon: const Icon(BloomIcons.search),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: tokens.sunken,
            child: SizedBox(
              width: 72,
              child: ListView.builder(
                itemCount: _aisles.length,
                itemBuilder: (context, index) {
                  final aisle = _aisles[index];
                  return AisleCircle(
                    label: aisle.label,
                    emoji: aisleEmoji(aisle.id),
                    icon: BloomIcons.festival,
                    rail: true,
                    selected: _aisleSelected(aisle.id),
                    onTap: () => _openAisle(context, aisle),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_group == 'flowers')
                  SizedBox(
                    height: 44,
                    child: ListView(
                      key: const Key('region-filters'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      children: [
                        for (final region in _regions)
                          _regionChip(
                            context,
                            region,
                            _region == region,
                            () => setState(() => _region = region),
                          ),
                      ],
                    ),
                  ),
                if (_group == 'vegetables' ||
                    _group == 'fruits' ||
                    _group == 'flowers')
                  SizedBox(
                    height: 128,
                    child: ListView(
                      key: const Key('subcategory-filters'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      children: [
                        AisleCircle(
                          label: 'All',
                          emoji: groups
                              .where((item) => item.slug == _group)
                              .firstOrNull
                              ?.emoji,
                          selected: _sub.isEmpty,
                          onTap: () => _openSub(context, ''),
                        ),
                        for (final sub in subs)
                          AisleCircle(
                            label: sub.name,
                            emoji: sub.emoji,
                            selected: _sub == sub.slug,
                            onTap: () => _openSub(context, sub.slug),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
                  child: Row(
                    children: [
                      Text(
                        _sortLabel(_sort),
                        style: BloomlyType.uiText(
                          13,
                          weight: FontWeight.w700,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<_Sort>(
                        tooltip: 'Sort',
                        initialValue: _sort,
                        onSelected: (value) => setState(() => _sort = value),
                        itemBuilder: (context) => [
                          for (final sort in _Sort.values)
                            PopupMenuItem(
                              value: sort,
                              child: Text(_sortLabel(sort)),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Icon(BloomIcons.sort, color: tokens.text),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: !backend.ready
                      ? const Center(child: CircularProgressIndicator())
                      : !known
                      ? _CategoryMessage(
                          icon: BloomIcons.search,
                          title: "That aisle isn't in the shop",
                          body: 'Pick vegetables, fruit, or flowers.',
                          action: 'Show vegetables',
                          onAction: () => _openGroup(context, 'vegetables'),
                        )
                      : products.isEmpty
                      ? _CategoryMessage(
                          icon: BloomIcons.basket,
                          title: 'Nothing on this shelf right now',
                          body: 'Clear the filter to see the rest of the aisle.',
                          action: _sub.isNotEmpty || _region != 'All'
                              ? 'Clear filters'
                              : null,
                          onAction: () => setState(() {
                            _sub = '';
                            _region = 'All';
                          }),
                        )
                      : CustomScrollView(
                          slivers: [
                            if (promos.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    4,
                                    8,
                                    0,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 2,
                                    child: PromoCard(
                                      story: promos.first,
                                      dense: true,
                                    ),
                                  ),
                                ),
                              ),
                            for (final shelf in shelves) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    8,
                                  ),
                                  child: Text(
                                    shelf.name,
                                    style: BloomlyType.display(
                                      16,
                                      color: tokens.text,
                                    ),
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 8,
                                        mainAxisExtent: productCardExtent,
                                      ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) =>
                                        ProductCard(product: shelf.products[index]),
                                    childCount: shelf.products.length,
                                  ),
                                ),
                              ),
                            ],
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_Shelf> _shelves(
    String title,
    List<ShopCategory> subs,
    List<Product> products,
  ) {
    if (products.isEmpty) return const [];
    if (_sub.isNotEmpty) {
      final name =
          subs.where((item) => item.slug == _sub).firstOrNull?.name ?? title;
      return [_Shelf(name, products)];
    }
    final shelves = <_Shelf>[];
    final grouped = subs.map((item) => item.slug).toSet();
    for (final sub in subs) {
      final items = products
          .where((product) => product.categorySlug == sub.slug)
          .toList();
      if (items.isNotEmpty) shelves.add(_Shelf(sub.name, items));
    }
    final rest = products
        .where((product) => !grouped.contains(product.categorySlug))
        .toList();
    if (rest.isNotEmpty) shelves.add(_Shelf(title, rest));
    if (shelves.isEmpty) return [_Shelf(title, products)];
    return shelves;
  }

  bool _aisleSelected(String id) {
    return switch (id) {
      'vegetables' => _group == 'vegetables',
      'fruits' => _group == 'fruits',
      'flowers' => _group == 'flowers' && _sub.isEmpty,
      'gifting' => _group == 'flowers' && _sub == 'garlands',
      _ => false,
    };
  }

  void _openAisle(BuildContext context, _Aisle aisle) {
    if (GoRouter.maybeOf(context) != null) {
      context.go(aisle.route);
      return;
    }
    setState(() {
      _groupOverride = aisle.group;
      _sub = aisle.sub;
      _region = 'All';
    });
  }

  void _openSub(BuildContext context, String slug) {
    setState(() {
      _sub = slug;
      _routeSub = slug;
      _syncedRoute = true;
    });
    if (GoRouter.maybeOf(context) == null) return;
    context.go(
      slug.isEmpty ? '/categories/$_group' : '/categories/$_group?sub=$slug',
    );
  }

  void _openGroup(BuildContext context, String slug) {
    if (GoRouter.maybeOf(context) != null) {
      context.go('/categories/$slug');
      return;
    }
    setState(() {
      _groupOverride = slug;
      _sub = '';
      _region = 'All';
    });
  }

  Widget _regionChip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final tokens = context.bloom;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        label: Text(label),
        selected: selected,
        selectedColor: tokens.secondary,
        backgroundColor: tokens.surface,
        labelStyle: BloomlyType.uiText(
          13,
          weight: FontWeight.w800,
          color: selected ? tokens.onSecondary : tokens.text,
        ),
        side: BorderSide(color: selected ? tokens.secondary : tokens.border),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Shelf {
  const _Shelf(this.name, this.products);

  final String name;
  final List<Product> products;
}

class _Aisle {
  const _Aisle(this.id, this.label, this.group, this.route, [this.sub = '']);

  final String id;
  final String label;
  final String group;
  final String route;
  final String sub;
}

const _aisles = <_Aisle>[
  _Aisle('vegetables', 'Vegetables', 'vegetables', '/categories/vegetables'),
  _Aisle('fruits', 'Fruits', 'fruits', '/categories/fruits'),
  _Aisle('flowers', 'Flowers', 'flowers', '/categories/flowers'),
  _Aisle('puja', 'Puja', 'flowers', '/categories/flowers'),
  _Aisle(
    'gifting',
    'Gifting',
    'flowers',
    '/categories/flowers?sub=garlands',
    'garlands',
  ),
  _Aisle('diwali', 'Diwali', 'flowers', '/categories/flowers'),
];

String _sortLabel(_Sort sort) {
  return switch (sort) {
    _Sort.featured => 'Featured',
    _Sort.priceLow => 'Lowest price',
    _Sort.priceHigh => 'Highest price',
    _Sort.name => 'Name',
  };
}

class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: tokens.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BloomlyType.display(20, color: tokens.text),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: BloomlyType.uiText(14, color: tokens.textSecondary),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
