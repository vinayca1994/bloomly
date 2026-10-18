import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/backend.dart';
import '../../data/catalog_seed.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final address = _defaultAddress(backend);
    final title = address?.label ?? 'Deliver to';
    final subtitle = address == null
        ? '${backend.store.city} · Set your address'
        : '${address.area}, ${address.city}';
    final forSale = backend.products.where((product) => product.forSale).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BloomlyColors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.spa, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _openAddress(context, backend.currentUser != null),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 20),
                          ],
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BloomlyColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: BloomlyColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    backend.store.etaLabel,
                    style: const TextStyle(
                      color: BloomlyColors.greenDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SearchTap(onTap: () => context.push('/search')),
            const SizedBox(height: 18),
            _IconGrid(categories: backend.categories),
            const SizedBox(height: 8),
            _RowSection(
              title: 'Fresh today',
              onSeeAll: () => context.go('/categories/vegetables'),
              products: _pick(forSale, freshTodayIds),
            ),
            _RowSection(
              title: 'Regional flowers',
              accent: true,
              onSeeAll: () => context.go('/categories/flowers'),
              products: _pick(forSale, regionalFlowerIds),
            ),
            _RowSection(
              title: 'Bestsellers',
              onSeeAll: () => context.go('/categories/fruits'),
              products: _pick(forSale, bestsellerIds),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddress(BuildContext context, bool signedIn) {
    if (signedIn) {
      context.push('/account/addresses');
    } else {
      context.push('/login?next=${Uri.encodeComponent('/account/addresses')}');
    }
  }
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

class _SearchTap extends StatelessWidget {
  const _SearchTap({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BloomlyColors.line),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: BloomlyColors.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search for vegetables, fruits, flowers',
                  style: TextStyle(color: BloomlyColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.categories});

  final List<ShopCategory> categories;

  @override
  Widget build(BuildContext context) {
    const slugs = [
      'vegetables',
      'fruits',
      'flowers',
      'leafy',
      'daily-veg',
      'seasonal-fruit',
      'loose-flowers',
      'citrus',
    ];
    final tiles = [
      for (final slug in slugs)
        if (categories.where((item) => item.slug == slug).firstOrNull != null)
          categories.firstWhere((item) => item.slug == slug),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        final group = tile.parentSlug ?? tile.slug;
        final sub = tile.parentSlug == null ? '' : '&sub=${tile.slug}';
        return InkWell(
          onTap: () => context.go('/categories/$group?from=home$sub'),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tile.kind == 'flower'
                      ? const Color(0xFFFBE6CF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BloomlyColors.line),
                ),
                child: Text(tile.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 6),
              Text(
                tile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RowSection extends StatelessWidget {
  const _RowSection({
    required this.title,
    required this.products,
    required this.onSeeAll,
    this.accent = false,
  });

  final String title;
  final List<Product> products;
  final VoidCallback onSeeAll;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (accent)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.local_florist, color: BloomlyColors.marigold, size: 18),
                ),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              padding: const EdgeInsets.only(right: 4),
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
