import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../data/stories.dart';
import 'product_card.dart';
import 'promo_card.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({this.group, super.key});

  final String? group;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  static const _regions = ['All', 'North', 'South', 'East', 'West'];
  String _sub = '';
  String _region = 'All';
  bool _syncedRoute = false;

  String get _group => widget.group ?? 'vegetables';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedRoute) return;
    _syncedRoute = true;
    _sub = GoRouterState.of(context).uri.queryParameters['sub'] ?? '';
  }

  @override
  void didUpdateWidget(CategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group) {
      _sub = GoRouterState.of(context).uri.queryParameters['sub'] ?? '';
      _region = 'All';
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
    }).toList()..sort((a, b) => a.sort.compareTo(b.sort));

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
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                      onSelected: (_) => context.go('/categories/${group.slug}'),
                    ),
                  ),
              ],
            ),
          ),
          if (promos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: SizedBox(
                height: 112,
                width: double.infinity,
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
          const SizedBox(height: 12),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Text(
                      'Nothing on this shelf right now.',
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 248,
                    ),
                    itemBuilder: (context, index) => ProductCard(product: products[index]),
                  ),
          ),
        ],
      ),
    );
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
