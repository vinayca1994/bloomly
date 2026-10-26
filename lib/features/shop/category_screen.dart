import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../data/stories.dart';
import 'product_card.dart';
import 'promo_card.dart';
import '../../core/bloom_icons.dart';

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

  String get _group => _groupOverride ?? widget.group ?? 'vegetables';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedRoute) return;
    _syncedRoute = true;
    final router = GoRouter.maybeOf(context);
    _sub = router == null
        ? ''
        : GoRouterState.of(context).uri.queryParameters['sub'] ?? '';
  }

  @override
  void didUpdateWidget(CategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group) {
      final router = GoRouter.maybeOf(context);
      _sub = router == null
          ? ''
          : GoRouterState.of(context).uri.queryParameters['sub'] ?? '';
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
      if (_group == 'flowers' && _region != 'All' && product.region != _region) {
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

    final promos = activeStories(
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
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                for (final group in groups)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(group.name),
                      selected: group.slug == _group,
                      selectedColor: tokens.primary,
                      backgroundColor: tokens.surface,
                      labelStyle: BloomlyType.uiText(
                        14,
                        weight: FontWeight.w800,
                        color: group.slug == _group ? tokens.onPrimary : tokens.text,
                      ),
                      side: BorderSide(
                        color: group.slug == _group ? tokens.primary : tokens.border,
                      ),
                      avatar: Icon(
                        _iconFor(group.slug),
                        size: 18,
                        color: group.slug == _group ? tokens.onPrimary : tokens.text,
                      ),
                      onSelected: (_) => _openGroup(context, group.slug),
                    ),
                  ),
              ],
            ),
          ),
          if (promos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: AspectRatio(
                aspectRatio: 2,
                child: PromoCard(story: promos.first, dense: true),
              ),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                _subChip(context, 'All', _sub.isEmpty, () => setState(() => _sub = '')),
                for (final sub in subs)
                  _subChip(
                    context,
                    sub.name,
                    _sub == sub.slug,
                    () => setState(() => _sub = sub.slug),
                  ),
              ],
            ),
          ),
          if (_group == 'flowers')
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                children: [
                  for (final region in _regions)
                    _subChip(
                      context,
                      region,
                      _region == region,
                      () => setState(() => _region = region),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Text(
                  _sortLabel(_sort),
                  style: BloomlyType.uiText(13, weight: FontWeight.w700, color: tokens.textSecondary),
                ),
                const Spacer(),
                PopupMenuButton<_Sort>(
                  tooltip: 'Sort',
                  initialValue: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (context) => [
                    for (final sort in _Sort.values)
                      PopupMenuItem(value: sort, child: Text(_sortLabel(sort))),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Icon(BloomIcons.sort, color: tokens.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
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
                    action: _sub.isNotEmpty || _region != 'All' ? 'Clear filters' : null,
                    onAction: () => setState(() {
                      _sub = '';
                      _region = 'All';
                    }),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 280,
                    ),
                    itemBuilder: (context, index) => ProductCard(product: products[index]),
                  ),
          ),
        ],
      ),
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

  Widget _subChip(BuildContext context, String label, bool selected, VoidCallback onTap) {
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

IconData _iconFor(String slug) {
  return switch (slug) {
    'fruits' => BloomIcons.fruits,
    'flowers' => BloomIcons.flowers,
    'puja' => BloomIcons.puja,
    'gifting' => BloomIcons.gifting,
    _ => BloomIcons.vegetables,
  };
}

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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: tokens.textSecondary),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: BloomlyType.display(22, color: tokens.text)),
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
