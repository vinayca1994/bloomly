import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class CartController extends Notifier<List<CartLine>> {
  static const _key = 'bloomly.cart';

  @override
  List<CartLine> build() {
    _restore();
    return [];
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || state.isNotEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      state = [
        for (final item in decoded)
          if (item is Map)
            CartLine.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode([for (final line in state) line.toJson()]),
      );
    } catch (_) {}
  }

  int qtyOf(String productId, String variantId) {
    for (final line in state) {
      if (line.productId == productId && line.variantId == variantId) {
        return line.qty;
      }
    }
    return 0;
  }

  int qtyOfProduct(String productId) {
    var total = 0;
    for (final line in state) {
      if (line.productId == productId) total += line.qty;
    }
    return total;
  }

  void setQty(String productId, String variantId, int qty) {
    if (qty <= 0) {
      state = [
        for (final line in state)
          if (!(line.productId == productId && line.variantId == variantId))
            line,
      ];
    } else {
      final exists = state.any(
        (line) => line.productId == productId && line.variantId == variantId,
      );
      if (!exists) {
        state = [
          ...state,
          CartLine(productId: productId, variantId: variantId, qty: qty),
        ];
      } else {
        state = [
          for (final line in state)
            if (line.productId == productId && line.variantId == variantId)
              line.copyWith(qty: qty)
            else
              line,
        ];
      }
    }
    _persist();
  }

  void addOne(String productId, String variantId) {
    setQty(productId, variantId, qtyOf(productId, variantId) + 1);
  }

  void clear() {
    state = [];
    _persist();
  }
}

final cartProvider = NotifierProvider<CartController, List<CartLine>>(
  CartController.new,
);
