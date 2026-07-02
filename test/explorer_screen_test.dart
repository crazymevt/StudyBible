import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/ui/explorer/explorer_screen.dart';

/// Drives the Explorer screen end to end on seeded data: home renders, a
/// search drills into an entity page, and the breadcrumb trail navigates
/// back. Pages with embedded maps are avoided here (network tiles don't load
/// under flutter_test); the map-free person and topic pages cover the flow.
void main() {
  late ContentStore store;

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());

    await store.into(store.biblePeople).insert(const BiblePeopleCompanion(
          id: Value(1),
          slug: Value('saul'),
          name: Value('Saul'),
          displayTitle: Value('Saul'),
          verseCount: Value(1),
        ));
    await store.into(store.personVerses).insert(const PersonVersesCompanion(
          id: Value(1),
          personId: Value(1),
          bookName: Value('1 Samuel'),
          chapter: Value(24),
          verse: Value(2),
        ));
    await store.into(store.timelineEvents).insert(const TimelineEventsCompanion(
        id: Value(1),
        title: Value('David spares Saul'),
        sortKey: Value(1.0),
        startYear: Value(-1060)));
    await store.into(store.eventParticipants).insert(
        const EventParticipantsCompanion(
            id: Value(1), eventId: Value(1), personId: Value(1)));
    await store.into(store.eventVerses).insert(const EventVersesCompanion(
        id: Value(1),
        eventId: Value(1),
        ord: Value(0),
        bookName: Value('1 Samuel'),
        chapter: Value(24),
        verse: Value(1)));

    await store.into(store.topics).insert(const TopicsCompanion(
        id: Value(1), name: Value('CAVES'), section: Value('C')));
    await store.into(store.topicEntries).insert(const TopicEntriesCompanion(
        id: Value(1),
        topicId: Value(1),
        ordinal: Value(0),
        description: Value('As refuges')));
    await store.into(store.topicReferences).insert(
        const TopicReferencesCompanion(
            id: Value(1),
            topicId: Value(1),
            entryId: Value(1),
            bookName: Value('1 Samuel'),
            chapter: Value(24),
            verse: Value(3)));
  });

  tearDown(() async {
    await store.close();
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentStoreProvider.overrideWithValue(store),
          sharedPreferencesProvider.overrideWithValue(prefs),
          peopleReadyProvider.overrideWith((ref) async => true),
          placesReadyProvider.overrideWith((ref) async => true),
          topicalIndexReadyProvider.overrideWith((ref) async => true),
        ],
        child: const MaterialApp(home: ExplorerScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home shows the search box and current-chapter shortcut',
      (tester) async {
    await pump(tester);

    expect(find.text('Explorer'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Explore '), findsOneWidget);
    // Dataset stat chips reflect the seeded store.
    expect(find.text('1 people'), findsOneWidget);
    expect(find.text('1 topics'), findsOneWidget);
  });

  testWidgets('searching drills into a person page with its facets',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Saul');
    await tester.pumpAndSettle();
    expect(find.text('PEOPLE'), findsOneWidget);

    // The query text field also matches "Saul" — tap the result tile.
    await tester.tap(find.widgetWithText(ListTile, 'Saul'));
    await tester.pumpAndSettle();

    // Page title plus the breadcrumb crumb.
    expect(find.text('Saul'), findsNWidgets(2));
    expect(find.text('Events (1)'), findsOneWidget);
    expect(find.text('David spares Saul'), findsOneWidget);
    expect(find.text('Appears in 1 verse'), findsOneWidget);
  });

  testWidgets('breadcrumb home returns to search; topic page renders entries',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'cave');
    await tester.pumpAndSettle();
    await tester.tap(find.text('CAVES'));
    await tester.pumpAndSettle();

    expect(find.text('As refuges'), findsOneWidget);
    expect(find.text('1 Samuel 24:3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    // Back on home with the previous query still in the box.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('TOPICS'), findsOneWidget);
  });
}
