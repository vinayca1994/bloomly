import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class ProductEditor extends ConsumerStatefulWidget {
  const ProductEditor({this.productId, super.key});

  final String? productId;

  @override
  ConsumerState<ProductEditor> createState() => _ProductEditorState();
}

class _DraftVariant {
  _DraftVariant({this.id = '', this.label = '', this.price = '', this.mrp = ''});

  String id;
  String label;
  String price;
  String mrp;
}

class _ProductEditorState extends ConsumerState<ProductEditor> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  String _category = 'daily-veg';
  String _region = 'North';
  bool _available = true;
  bool _loaded = false;
  bool _busy = false;
  String? _error;
  Uint8List? _bytes;
  final _variants = <_DraftVariant>[_DraftVariant(label: '1 pc')];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _load(Product product) {
    _name.text = product.name;
    _description.text = product.description;
    _imageUrl.text = product.imageUrl ?? '';
    _category = product.categorySlug;
    _region = product.region.isEmpty ? 'North' : product.region;
    _available = product.isAvailable;
    _variants
      ..clear()
      ..addAll(
        product.variants.map(
          (variant) => _DraftVariant(
            id: variant.id,
            label: variant.label,
            price: '${variant.price}',
            mrp: '${variant.mrp}',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final existing = widget.productId == null ? null : backend.productById(widget.productId!);
    if (!_loaded && existing != null) {
      _loaded = true;
      _load(existing);
    }
    final subs = backend.categories.where((item) => item.parentSlug != null).toList();
    final selected = subs.where((item) => item.slug == _category).firstOrNull;
    final isFlower = selected?.kind == 'flower';

    return Scaffold(
      appBar: AppBar(title: Text(existing == null ? 'Add product' : 'Edit product')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: subs.any((item) => item.slug == _category) ? _category : subs.first.slug,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final category in subs)
                DropdownMenuItem(value: category.slug, child: Text(category.name)),
            ],
            onChanged: (value) => setState(() => _category = value ?? _category),
          ),
          if (isFlower) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: const InputDecoration(labelText: 'Region'),
              items: const [
                DropdownMenuItem(value: 'North', child: Text('North')),
                DropdownMenuItem(value: 'South', child: Text('South')),
                DropdownMenuItem(value: 'East', child: Text('East')),
                DropdownMenuItem(value: 'West', child: Text('West')),
              ],
              onChanged: (value) => setState(() => _region = value ?? _region),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _imageUrl,
            decoration: const InputDecoration(labelText: 'Image URL'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.photo_outlined),
              label: Text(_bytes == null ? 'Upload photo' : 'Photo ready'),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available'),
            value: _available,
            activeThumbColor: BloomlyColors.green,
            onChanged: (value) => setState(() => _available = value),
          ),
          const Text('Variants', style: TextStyle(fontWeight: FontWeight.w800)),
          for (var i = 0; i < _variants.length; i++) _variantFields(i),
          TextButton(
            onPressed: () => setState(() => _variants.add(_DraftVariant())),
            child: const Text('Add variant'),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: BloomlyColors.danger)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : () => _save(existing),
            child: Text(_busy ? 'Saving…' : 'Save product'),
          ),
        ],
      ),
    );
  }

  Widget _variantFields(int index) {
    final draft = _variants[index];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: draft.label,
              decoration: const InputDecoration(labelText: 'Unit'),
              onChanged: (value) => draft.label = value,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: draft.price,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              onChanged: (value) => draft.price = value,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: draft.mrp,
              decoration: const InputDecoration(labelText: 'MRP'),
              keyboardType: TextInputType.number,
              onChanged: (value) => draft.mrp = value,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _bytes = bytes);
  }

  Future<void> _save(Product? existing) async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Add a name.');
      return;
    }
    final variants = <Variant>[];
    for (final draft in _variants) {
      final price = int.tryParse(draft.price.trim());
      final mrp = int.tryParse(draft.mrp.trim());
      if (draft.label.trim().isEmpty || price == null || mrp == null) {
        setState(() => _error = 'Each variant needs a unit, price, and MRP.');
        return;
      }
      variants.add(
        Variant(
          id: draft.id,
          productId: existing?.id ?? '',
          label: draft.label.trim(),
          price: price,
          mrp: mrp,
          isAvailable: true,
        ),
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(backendProvider).upsertProduct(
        Product(
          id: existing?.id ?? '',
          name: _name.text.trim(),
          categorySlug: _category,
          description: _description.text.trim(),
          imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
          isAvailable: _available,
          region: _category.startsWith('loose') ||
                  _category == 'garlands' ||
                  _category == 'bunches'
              ? _region
              : '',
          sort: existing?.sort ?? 0,
          variants: variants,
        ),
        imageBytes: _bytes,
      );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save the product.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
