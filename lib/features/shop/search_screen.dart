import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/bloom_icons.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'cart_bar.dart';
import 'product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _recentKey = 'bloom.search.recent';
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _recent = <String>[];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_recentKey) ?? const <String>[];
    if (!mounted) return;
    setState(() => _recent = saved);
  }

  Future<void> _remember(String term) async {
    final clean = term.trim();
    if (clean.isEmpty) return;
    final next = [
      clean,
      ..._recent.where((item) => item.toLowerCase() != clean.toLowerCase()),
    ].take(8).toList();
    setState(() => _recent = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, next);
  }

  Future<void> _clearRecent() async {
    setState(() => _recent = []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }

  Future<void> _dropRecent(String term) async {
    final next = _recent.where((item) => item != term).toList();
    setState(() => _recent = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, next);
  }

  void _apply(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    setState(() {});
    _remember(term);
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final tokens = context.bloom;
    final query = _controller.text.trim();
    final needle = query.toLowerCase();
    final results = backend.products.where((product) {
      if (!product.forSale) return false;
      if (needle.isEmpty) return false;
      final haystack = '${product.name} ${product.description} ${product.region}'.toLowerCase();
      return haystack.contains(needle);
    }).toList();
    final starters = backend.products.where((product) => product.forSale).take(4).toList();
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: tokens.borderStrong),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else if (GoRouter.maybeOf(context) != null) {
                        context.go('/');
                      }
                    },
                    icon: const Icon(BloomIcons.arrowLeft),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _remember,
                      decoration: InputDecoration(
                        hintText: 'Search vegetables, fruits, flowers',
                        prefixIcon: const Icon(BloomIcons.search),
                        isDense: true,
                        filled: true,
                        fillColor: tokens.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: fieldBorder,
                        enabledBorder: fieldBorder,
                        focusedBorder: fieldBorder.copyWith(
                          borderSide: BorderSide(color: tokens.borderFocus),
                        ),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {});
                                },
                                icon: const Icon(BloomIcons.close),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (query.isEmpty) ...[
                    if (_recent.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            'Recent',
                            style: BloomlyType.display(18, color: tokens.text),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _clearRecent,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final term in _recent)
                            InputChip(
                              label: Text(term),
                              onPressed: () => _apply(term),
                              onDeleted: () => _dropRecent(term),
                              deleteButtonTooltipMessage: 'Remove $term',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Start with',
                      style: BloomlyType.display(18, color: tokens.text),
                    ),
                    const SizedBox(height: 12),
                    _productGrid(starters),
                  ] else ...[
                    Text(
                      'Results for “$query”',
                      style: BloomlyType.display(18, color: tokens.text),
                    ),
                    const SizedBox(height: 12),
                    if (results.isEmpty)
                      Text(
                        'No matches',
                        style: TextStyle(color: tokens.textSecondary),
                      )
                    else
                      _productGrid(results),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CartBar(),
    );
  }

  Widget _productGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: productCardExtent,
      ),
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }
}
