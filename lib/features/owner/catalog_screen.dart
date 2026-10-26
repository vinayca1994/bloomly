import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/backend.dart';
import '../../data/catalog_seed.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../core/bloom_icons.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _CatalogBody();
  }
}

class _CatalogBody extends ConsumerStatefulWidget {
  const _CatalogBody();

  @override
  ConsumerState<_CatalogBody> createState() => _CatalogBodyState();
}

class _CatalogBodyState extends ConsumerState<_CatalogBody> {
  final _search = TextEditingController();
  String _kind = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final query = _search.text.trim().toLowerCase();
    final products = backend.products.where((product) {
      final category = backend.categories
          .where((item) => item.slug == product.categorySlug)
          .firstOrNull;
      if (_kind != 'all' && category?.kind != _kind) return false;
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    final tokens = context.bloom;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        tooltip: 'Add product',
        onPressed: () => context.push('/owner/catalog/new'),
        child: const Icon(BloomIcons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search ${backend.products.length} products',
                prefixIcon: const Icon(BloomIcons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final entry in const [
                  ('all', 'All'),
                  ('vegetable', 'Vegetables'),
                  ('fruit', 'Fruit'),
                  ('flower', 'Flowers'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.$2),
                      selected: _kind == entry.$1,
                      onSelected: (_) => setState(() => _kind = entry.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              children: [
                DecoratedBox(
                  decoration: BloomlyDecor.card(tokens),
                  child: products.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No products match',
                            style: TextStyle(color: tokens.textSecondary),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < products.length; i++)
                              _CatalogRow(
                                product: products[i],
                                emoji: _emoji(backend, products[i]),
                                kind: kindFor(products[i], backend.categories),
                                showDivider: i != products.length - 1,
                                onOpen: () => context.push('/owner/catalog/${products[i].id}'),
                                onAvailable: (value) =>
                                    backend.setProductAvailable(products[i].id, value),
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
}

String _emoji(BloomlyBackend backend, Product product) {
  final category = backend.categories
      .where((item) => item.slug == product.categorySlug)
      .firstOrNull;
  return category?.emoji ?? '🥬';
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.product,
    required this.emoji,
    required this.kind,
    required this.showDivider,
    required this.onOpen,
    required this.onAvailable,
  });

  final Product product;
  final String emoji;
  final ColorKind kind;
  final bool showDivider;
  final VoidCallback onOpen;
  final ValueChanged<bool> onAvailable;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    final lead = product.variants.isEmpty ? null : product.lead;
    final caption = lead == null ? 'No price' : '${lead.label} · ${money(lead.price)}';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: tokens.border)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 48,
                height: 48,
                child: ProductImage(emoji: emoji, kind: kind, url: product.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(caption, style: TextStyle(color: tokens.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            Switch(
              value: product.isAvailable,
              onChanged: onAvailable,
            ),
          ],
        ),
      ),
    );
  }
}
