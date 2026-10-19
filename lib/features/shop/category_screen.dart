import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import 'product_card.dart';

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
    final subs = backend.categories
        .where((item) => item.parentSlug == _group)
        .toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    final title = groups.where((item) => item.slug == _group).firstOrNull?.name ??
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title),
      ),
      body: Column(
        children: [
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
                      label: Text(
                        '${group.emoji} ${group.name}',
                        style: TextStyle(
                          color: group.slug == _group ? Colors.white : BloomlyColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: group.slug == _group,
                      selectedColor: BloomlyColors.ink,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BloomlyDecor.card(radius: 999),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: BloomlyColors.muted, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Search in Bloomly',
                        style: TextStyle(color: BloomlyColors.muted),
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
                          style: const TextStyle(
                            color: BloomlyColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: _region == region,
                        selectedColor: BloomlyColors.marigold,
                        checkmarkColor: BloomlyColors.ink,
                        onSelected: (_) => setState(() => _region = region),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: ColoredBox(
                    color: BloomlyColors.canvas,
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
                      ? const Center(
                          child: Text(
                            'Nothing on this shelf right now.',
                            style: TextStyle(color: BloomlyColors.muted),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? BloomlyColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? BloomlyDecor.shadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: BloomlyColors.ink,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
