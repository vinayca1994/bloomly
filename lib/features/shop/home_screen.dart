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
    final detected = ref.watch(placeProvider).place;
    final address = _defaultAddress(backend);
    final title = address?.label ?? 'Deliver to';
    final subtitle = address != null
        ? '${address.area}, ${address.city}'
        : (detected != null && detected.city.isNotEmpty)
        ? (detected.area.isEmpty ? detected.city : '${detected.area}, ${detected.city}')
        : '${backend.store.city} · Set your address';
    final city = address?.city ?? detected?.city ?? '';
    final outside = city.isNotEmpty &&
        city.trim().toLowerCase() != backend.store.city.trim().toLowerCase();
    final forSale = backend.products.where((product) => product.forSale).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const _LocationProbe(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('bloomly', style: BloomlyType.display(34)),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: BloomlyColors.marigold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    backend.store.etaLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => _openAddress(context, backend.currentUser != null),
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: BloomlyColors.muted, fontSize: 13),
            ),
            if (outside) ...[
              const SizedBox(height: 10),
              Text(
                'Bloomly delivers in ${backend.store.city} only.',
                style: const TextStyle(color: BloomlyColors.danger, fontWeight: FontWeight.w600),
              ),
            ],
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

class _SearchTap extends StatelessWidget {
  const _SearchTap({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BloomlyColors.card,
      borderRadius: BorderRadius.circular(999),
      elevation: 0,
      shadowColor: BloomlyColors.ink.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BloomlyDecor.card(radius: 999),
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
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: switch (tile.kind) {
                    'flower' => BloomlyColors.peach,
                    'fruit' => BloomlyColors.fruitWash,
                    _ => BloomlyColors.leafWash,
                  },
                  shape: BoxShape.circle,
                  boxShadow: BloomlyDecor.shadow,
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
    final body = Padding(
      padding: EdgeInsets.only(top: accent ? 0 : 18),
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
                  style: BloomlyType.display(22),
                ),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          SizedBox(
            height: 248,
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
    if (!accent) return body;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BloomlyColors.peach,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: body,
        ),
      ),
    );
  }
}
