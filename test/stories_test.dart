import 'package:bloomly/data/models.dart';
import 'package:bloomly/data/promo_templates.dart';
import 'package:bloomly/data/providers.dart';
import 'package:bloomly/data/stories.dart';
import 'package:bloomly/data/unconfigured_backend.dart';
import 'package:bloomly/features/brand/about_screen.dart';
import 'package:bloomly/features/brand/launch_screen.dart';
import 'package:bloomly/features/shop/promo_card.dart';
import 'package:bloomly/features/shop/story_banner.dart';
import 'package:bloomly/features/shop/story_clips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);

  Story story({
    required String id,
    StoryPlacement placement = StoryPlacement.homeBanner,
    int sort = 0,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return Story(
      id: id,
      placement: placement,
      title: id,
      subtitle: 'Offer',
      tone: StoryTone.leaf,
      sort: sort,
      startsAt: startsAt,
      endsAt: endsAt,
    );
  }

  test('expired and future stories drop out', () {
    final source = [
      story(id: 'live', sort: 2),
      story(
        id: 'future',
        sort: 0,
        startsAt: now.add(const Duration(minutes: 1)),
      ),
      story(
        id: 'expired',
        sort: 1,
        endsAt: now.subtract(const Duration(minutes: 1)),
      ),
      story(id: 'ends-now', sort: 4, endsAt: now),
      story(id: 'clip', placement: StoryPlacement.homeClip, sort: 0),
      story(id: 'opens-now', sort: 3, startsAt: now),
    ];

    expect(
      activeStories(
        StoryPlacement.homeBanner,
        now,
        source: source,
      ).map((item) => item.id),
      ['live', 'opens-now'],
    );
    expect(
      activeStories(
        StoryPlacement.homeClip,
        now,
        source: source,
      ).map((item) => item.id),
      ['clip'],
    );
  });

  testWidgets('an empty placement renders nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StoryBanner(stories: []),
              StoryClipRail(stories: []),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(PageView), findsNothing);
    expect(find.text('Free delivery'), findsNothing);
    expect(find.text('Morning vegetables'), findsNothing);
  });

  test('hidden banners stay off the shop', () {
    final hidden = Story(
      id: 'hidden',
      placement: StoryPlacement.homeBanner,
      title: 'Hidden',
      subtitle: 'Off',
      tone: StoryTone.leaf,
      sort: 1,
      hidden: true,
    );
    expect(
      activeStories(
        StoryPlacement.homeBanner,
        now,
        source: [
          story(id: 'shown'),
          hidden,
        ],
      ).map((item) => item.id),
      ['shown'],
    );
  });

  test('a saved banner round-trips through the store field', () {
    final banner = Story(
      id: 'ugadi',
      placement: StoryPlacement.homeBanner,
      title: 'Ugadi greens',
      subtitle: 'The new-year basket',
      tone: StoryTone.leaf,
      sort: 0,
      route: '/categories/vegetables',
      startsAt: DateTime.utc(2026, 3, 19),
      endsAt: DateTime.utc(2026, 3, 20),
    );
    final raw = StoreSettings.fallback
        .copyWith(promotions: [banner])
        .toMap()['promotions'];
    final back = decodePromotions(raw as String).single;
    expect(back.id, 'ugadi');
    expect(back.title, 'Ugadi greens');
    expect(back.hidden, isFalse);
    expect(back.startsAt, banner.startsAt);
    expect(back.endsAt, banner.endsAt);
    expect(decodePromotions('not json'), isEmpty);
  });

  test('about copy uses the open store', () {
    final where = aboutBlocks(StoreSettings.fallback)
        .firstWhere((block) => block.heading == 'Where and how fast');
    expect(where.body, contains('Bengaluru'));
    expect(where.body, contains('15–30 min'));
    expect(where.body, contains('₹25'));
    expect(where.body, contains('₹199'));
  });

  testWidgets('the offer banner moves to the next card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryBanner(
            stories: [
              story(id: 'First offer', sort: 0),
              story(id: 'Second offer', sort: 1),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    expect(tester.getTopLeft(find.text('Second offer')).dx, lessThan(40));
  });

  test('the splash leaves once the catalog is ready, or after 1 second', () {
    expect(leaveSplash(ready: false, timedOut: false, failed: false), isFalse);
    expect(leaveSplash(ready: true, timedOut: false, failed: false), isTrue);
    expect(leaveSplash(ready: false, timedOut: true, failed: false), isTrue);
    expect(leaveSplash(ready: true, timedOut: true, failed: true), isFalse);
  });

  testWidgets('a themed banner fits the home slot', (tester) async {
    final ugadi = promoTemplates.firstWhere((item) => item.id == 'ugadi');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 156,
            child: PromoCard(story: ugadi.story(id: 'ugadi', sort: 0)),
          ),
        ),
      ),
    );
    expect(find.text('Neem, jaggery, and flowers'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final style in promoStyles('ugadi')) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              height: 156,
              child: PromoCard(
                story: ugadi
                    .story(id: 'ugadi', sort: 0)
                    .copyWith(styleId: style.id, motif: style.motif),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: style.name);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 112,
            child: PromoCard(
              story: ugadi.story(id: 'ugadi', sort: 0),
              dense: true,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a load error stays on the wordmark', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWith((ref) => UnconfiguredBackend()),
        ],
        child: const MaterialApp(home: LaunchGate(child: Text('shop'))),
      ),
    );
    await tester.pump();

    expect(find.text('bloom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('shop'), findsNothing);
  });
}
