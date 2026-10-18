import 'package:bloomly/core/bill.dart';
import 'package:bloomly/core/theme.dart';
import 'package:bloomly/core/widgets.dart';
import 'package:bloomly/data/cart_controller.dart';
import 'package:bloomly/data/memory_backend.dart';
import 'package:bloomly/data/models.dart';
import 'package:bloomly/data/providers.dart';
import 'package:bloomly/features/cart/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SeedCart extends CartController {
  _SeedCart(this.initial);

  final List<CartLine> initial;

  @override
  List<CartLine> build() => initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProductImage.enableNetwork = false;
  });

  test('delivery is free at the threshold and charged below it', () {
    expect(deliveryFeeFor(0), 0);
    expect(deliveryFeeFor(198), 25);
    expect(deliveryFeeFor(199), 0);
    expect(deliveryFeeFor(240), 0);
    expect(billTotal(198), 223);
    expect(billTotal(199), 199);
  });

  testWidgets('cart shows a delivery fee under ₹199', (tester) async {
    final backend = MemoryBackend.seeded();
    final tomato = backend.productById('tomato')!;
    final variant = tomato.variants.first;
    await backend.setVariantPrice(tomato.id, variant.id, 100);

    await tester.pumpWidget(
      _cartApp(backend, [
        CartLine(productId: tomato.id, variantId: variant.id, qty: 1),
      ]),
    );
    await tester.pump();

    expect(_text(tester, 'delivery-fee'), '₹25');
    expect(_text(tester, 'to-pay'), '₹125');
  });

  testWidgets('cart delivery is free at the threshold', (tester) async {
    final backend = MemoryBackend.seeded();
    final tomato = backend.productById('tomato')!;
    final variant = tomato.variants.first;
    await backend.setVariantPrice(tomato.id, variant.id, 199);

    await tester.pumpWidget(
      _cartApp(backend, [
        CartLine(productId: tomato.id, variantId: variant.id, qty: 1),
      ]),
    );
    await tester.pump();

    expect(_text(tester, 'delivery-fee'), 'Free');
    expect(_text(tester, 'to-pay'), '₹199');
  });

  testWidgets('qty changes and removing the last item empties the cart', (
    tester,
  ) async {
    final backend = MemoryBackend.seeded();
    final tomato = backend.productById('tomato')!;
    final variant = tomato.variants.first;
    await backend.setVariantPrice(tomato.id, variant.id, 40);

    await tester.pumpWidget(
      _cartApp(backend, [
        CartLine(productId: tomato.id, variantId: variant.id, qty: 2),
      ]),
    );
    await tester.pump();
    expect(_text(tester, 'to-pay'), '₹105');

    await tester.tap(find.byKey(Key('minus-${variant.id}')));
    await tester.pump();
    expect(_text(tester, 'to-pay'), '₹65');
    expect(_text(tester, 'delivery-fee'), '₹25');

    await tester.tap(find.byKey(Key('minus-${variant.id}')));
    await tester.pump();
    expect(find.byKey(const Key('cart-empty')), findsOneWidget);
  });
}

String _text(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

Widget _cartApp(MemoryBackend backend, List<CartLine> lines) {
  return ProviderScope(
    overrides: [
      backendProvider.overrideWith((ref) => backend),
      cartProvider.overrideWith(() => _SeedCart(lines)),
    ],
    child: MaterialApp(theme: BloomlyTheme.light(), home: const CartScreen()),
  );
}
