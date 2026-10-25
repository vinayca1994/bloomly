import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
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
    }).toList()..sort((a, b) => a.sort.compareTo(b.sort));

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
      backgroundColor: context.bloom.canvas,
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(title)),
      body: Column(
        children: [
          if (promos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: SizedBox(
                height: 112,
                width: double.infinity,
                child: PromoCard(story: promos.first, dense: true),
              ),
            ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final group in groups)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BloomEmoji(group.emoji, size: 16),
                          SizedBox(width: 6),
                          Text(
                            group.name,
                            style: BloomlyType.label.copyWith(
                              color: group.slug == _group
                                  ? context.bloom.onPrimary
                                  : context.bloom.text,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      selected: group.slug == _group,
                      selectedColor: context.bloom.primary,
                      onSelected: (_) {
                        context.go('/categories/${group.slug}');
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.push('/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BloomlyDecor.card(context.bloom, radius: 999),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: context.bloom.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Search in Bloom',
                        style: TextStyle(color: context.bloom.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_group == 'flowers')
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final region in _regions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          region,
                          style: TextStyle(
                            color: context.bloom.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: _region == region,
                        selectedColor: context.bloom.star,
                        checkmarkColor: context.bloom.text,
                        onSelected: (_) => setState(() => _region = region),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: ColoredBox(
                    color: context.bloom.canvas,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _RailItem(
                          label: 'All',
                          selected: _sub.isEmpty,
                          onTap: () => setState(() => _sub = ''),
                        ),
                        for (final sub in subs)
                          _RailItem(
                            label: sub.name,
                            selected: _sub == sub.slug,
                            onTap: () => setState(() => _sub = sub.slug),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            'Nothing on this shelf right now.',
                            style: TextStyle(color: context.bloom.textSecondary),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                          itemCount: products.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                mainAxisExtent: 248,
                              ),
                          itemBuilder: (context, index) =>
                              ProductCard(product: products[index]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? context.bloom.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? context.bloom.cardShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: context.bloom.text,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
