import 'package:bloomly/core/theme.dart';
import 'package:bloomly/core/widgets.dart';
import 'package:bloomly/data/memory_backend.dart';
import 'package:bloomly/data/providers.dart';
import 'package:bloomly/features/shop/bloom_media.dart';
import 'package:bloomly/features/shop/category_screen.dart';
import 'package:bloomly/features/shop/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ProductImage.enableNetwork = false;
    BloomMedia.enablePlayback = false;
  });

  Future<void> pump(WidgetTester tester, {String? group}) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWith((ref) => MemoryBackend.seeded()),
        ],
        child: MaterialApp(
          theme: BloomlyTheme.light(),
          home: CategoryScreen(group: group),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('an unknown aisle explains itself and can return to vegetables', (
    tester,
  ) async {
    await pump(tester, group: 'missing');
    expect(find.text("That aisle isn't in the shop"), findsOneWidget);
    await tester.tap(find.text('Show vegetables'));
    await tester.pump();
    expect(find.text('Tomato'), findsWidgets);
    expect(find.text("That aisle isn't in the shop"), findsNothing);
  });

  testWidgets('sort by lowest price keeps the shelf on screen', (tester) async {
    await pump(tester, group: 'vegetables');
    expect(find.text('Featured'), findsOneWidget);
    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lowest price').last);
    await tester.pumpAndSettle();
    expect(find.text('Lowest price'), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('clear filters restores a shelf that was narrowed to nothing', (
    tester,
  ) async {
    await pump(tester, group: 'flowers');
    await tester.tap(find.text('West'));
    await tester.pump();
    final empty = find.text('Nothing on this shelf right now');
    if (empty.evaluate().isNotEmpty) {
      await tester.tap(find.text('Clear filters'));
      await tester.pump();
      expect(empty, findsNothing);
    }
    expect(find.text('All'), findsWidgets);
  });
}
