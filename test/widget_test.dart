import 'package:bloomly/core/theme.dart';
import 'package:bloomly/core/widgets.dart';
import 'package:bloomly/data/memory_backend.dart';
import 'package:bloomly/data/providers.dart';
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
  });

  testWidgets('home opens on the shop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWith((ref) => MemoryBackend.seeded()),
        ],
        child: MaterialApp(theme: BloomlyTheme.light(), home: const HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Deliver to'), findsOneWidget);
    expect(find.text('Tomato'), findsWidgets);
    expect(find.text('Fresh today'), findsOneWidget);
    expect(find.text('Regional flowers'), findsOneWidget);
  });
}
