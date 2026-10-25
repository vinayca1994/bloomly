import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
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
    final popular = backend.products.where((product) => product.forSale).take(6).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: _remember,
            decoration: InputDecoration(
              hintText: 'Search vegetables, fruits, flowers',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          if (query.isEmpty) ...[
            if (_recent.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Recent', style: BloomlyType.display(20, color: tokens.text)),
                  const Spacer(),
                  TextButton(onPressed: _clearRecent, child: const Text('Clear')),
                ],
              ),
              for (final term in _recent)
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 20, color: tokens.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _apply(term),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(term, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove $term',
                        onPressed: () => _dropRecent(term),
                        icon: Icon(Icons.close, size: 18, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Text('Popular now', style: BloomlyType.display(20, color: tokens.text)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final product in popular)
                  ActionChip(
                    label: Text(product.name),
                    onPressed: () => _apply(product.name),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 20),
            Text('Results for “$query”', style: BloomlyType.display(20, color: tokens.text)),
            const SizedBox(height: 12),
            if (results.isEmpty)
              Text('No matches', style: TextStyle(color: tokens.textSecondary))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 248,
                ),
                itemBuilder: (context, index) => ProductCard(product: results[index]),
              ),
          ],
        ],
      ),
      bottomNavigationBar: const CartBar(),
    );
  }
}
