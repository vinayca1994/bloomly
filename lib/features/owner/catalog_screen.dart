import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

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

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BloomlyColors.green,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/owner/catalog/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search catalog',
                prefixIcon: Icon(Icons.search),
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
                  ('fruit', 'Fruits'),
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];
                return Material(
                  color: product.isAvailable ? Colors.white : const Color(0xFFF3F3F1),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push('/owner/catalog/${product.id}'),
                                child: Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                              ),
                            ),
                            Switch(
                              value: product.isAvailable,
                              activeThumbColor: BloomlyColors.green,
                              onChanged: (value) => backend.setProductAvailable(product.id, value),
                            ),
                          ],
                        ),
                        for (final variant in product.variants)
                          _PriceEditor(
                            key: ValueKey(variant.id),
                            variant: variant,
                            onSave: (price) => backend.setVariantPrice(product.id, variant.id, price),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceEditor extends StatefulWidget {
  const _PriceEditor({required this.variant, required this.onSave, super.key});

  final Variant variant;
  final ValueChanged<int> onSave;

  @override
  State<_PriceEditor> createState() => _PriceEditorState();
}

class _PriceEditorState extends State<_PriceEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.variant.price}');
  }

  @override
  void didUpdateWidget(_PriceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variant.price != widget.variant.price &&
        _controller.text != '${widget.variant.price}') {
      _controller.text = '${widget.variant.price}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(widget.variant.label, style: const TextStyle(color: BloomlyColors.muted)),
          ),
          const Text('₹'),
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true),
              onSubmitted: (_) => _save(),
            ),
          ),
          IconButton(onPressed: _save, icon: const Icon(Icons.check, color: BloomlyColors.green)),
          Text(
            money(widget.variant.mrp),
            style: const TextStyle(
              color: BloomlyColors.muted,
              decoration: TextDecoration.lineThrough,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final price = int.tryParse(_controller.text.trim());
    if (price == null || price < 0) return;
    widget.onSave(price);
  }
}
