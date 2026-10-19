import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final query = _controller.text.trim().toLowerCase();
    final results = backend.products.where((product) {
      if (!product.forSale) return false;
      if (query.isEmpty) return false;
      final haystack = '${product.name} ${product.description} ${product.region}'
          .toLowerCase();
      return haystack.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search vegetables, fruits, flowers',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _controller.clear();
                setState(() {});
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: query.isEmpty
          ? const Center(
              child: Text(
                'Try tomato, mango, or jasmine',
                style: TextStyle(color: BloomlyColors.muted),
              ),
            )
          : results.isEmpty
          ? Center(
              child: Text(
                'No matches for “$query”',
                style: const TextStyle(color: BloomlyColors.muted),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 248,
              ),
              itemBuilder: (context, index) => ProductCard(product: results[index]),
            ),
      bottomNavigationBar: const CartBar(),
    );
  }
}
