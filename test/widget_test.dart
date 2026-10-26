import 'package:bloomly/core/bloom_icons.dart';
import 'package:bloomly/core/theme.dart';
import 'package:bloomly/core/widgets.dart';
import 'package:bloomly/data/memory_backend.dart';
import 'package:bloomly/data/providers.dart';
import 'package:bloomly/data/stories.dart';
import 'package:bloomly/features/shop/bloom_media.dart';
import 'package:bloomly/features/shop/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProductImage.enableNetwork = false;
    BloomMedia.enablePlayback = false;
  });

  testWidgets('home opens on the shop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWith((ref) => MemoryBackend.seeded()),
        ],
        child: MaterialApp(
          theme: BloomlyTheme.light(),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Deliver to'), findsOneWidget);
    final icons = tester.widgetList<Icon>(find.byType(Icon));
    expect(icons, isNotEmpty);
    expect(
      icons.every((icon) => icon.icon?.fontFamily == 'MaterialIcons'),
      isTrue,
    );
    expect(icons.any((icon) => icon.icon == BloomIcons.vegetables), isTrue);
    expect(find.text('Free delivery'), findsNothing);
    expect(find.text('Morning vegetables'), findsNothing);
    expect(find.text('Tomato'), findsWidgets);
    expect(find.text('Fresh today'), findsOneWidget);
    expect(find.text('Regional flowers'), findsOneWidget);
  });

  testWidgets('a published banner shows on home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final backend = MemoryBackend.seeded();
    await backend.updateStore(
      backend.store.copyWith(
        promotions: const [
          Story(
            id: 'diwali',
            placement: StoryPlacement.homeBanner,
            title: 'Diwali marigolds',
            subtitle: 'Flowers for the festival',
            tone: StoryTone.marigold,
            sort: 0,
            route: '/categories/flowers',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWith((ref) => backend)],
        child: MaterialApp(
          theme: BloomlyTheme.light(),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Diwali marigolds'), findsOneWidget);
    expect(find.text('Morning vegetables'), findsNothing);
  });
}
