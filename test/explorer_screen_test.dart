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
import 'package:study_bible/app/app_state.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/explorer/explorer_screen.dart';

/// Drives the Explorer screen end to end on seeded data: home renders, a
/// search drills into an entity page, and the breadcrumb trail navigates
/// back. Pages with embedded maps are avoided here (network tiles don't load
/// under flutter_test); the map-free person and topic pages cover the flow.
void main() {
  late ContentStore store;
  late UserStore userStore;

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());

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
    await store.into(store.commentaries).insert(const CommentariesCompanion(
        id: Value(1),
        abbreviation: Value('MHC'),
        name: Value('Matthew Henry')));
    await store
        .into(store.commentaryEntries)
        .insert(const CommentaryEntriesCompanion(
          id: Value(1),
          commentaryId: Value(1),
          bookName: Value('1 Samuel'),
          chapter: Value(24),
          verse: Value(1),
          textContent: Value('<p>David in the wilderness of En Gedi.</p>'),
        ));

    await userStore.into(userStore.notes).insert(const NotesCompanion(
          id: Value('note-1'),
          updatedAt: Value(0),
          deviceId: Value('test-device'),
          bookName: Value('1 Samuel'),
          chapter: Value(24),
          verse: Value(2),
          content: Value('Saul chooses three thousand men.'),
        ));

    // A tag on 1 Samuel 24:2, with the Bible text behind it so the tag page
    // can hydrate the tagged verse.
    await store.into(store.versions).insert(const VersionsCompanion(
        id: Value('KJV'), abbreviation: Value('KJV'), name: Value('KJV')));
    await store.into(store.books).insert(const BooksCompanion(
          id: Value(1),
          versionId: Value('KJV'),
          name: Value('1 Samuel'),
          bookOrder: Value(9),
          testament: Value('OT'),
        ));
    await store.into(store.verses).insert(const VersesCompanion(
          id: Value(1),
          bookId: Value(1),
          chapter: Value(24),
          verse: Value(2),
          textContent: Value('Then Saul took three thousand chosen men.'),
          segments: Value('[]'),
        ));
    await userStore.into(userStore.tags).insert(const TagsCompanion(
          id: Value('tag-battles'),
          updatedAt: Value(0),
          deviceId: Value('test-device'),
          name: Value('battles'),
          colorHex: Value('#E53935'),
        ));
    await userStore.into(userStore.entityTags).insert(const EntityTagsCompanion(
          id: Value('link-1'),
          updatedAt: Value(0),
          deviceId: Value('test-device'),
          tagId: Value('tag-battles'),
          entityId: Value('Verse:1 Samuel|24|2'),
          entityType: Value('verse'),
        ));
  });

  tearDown(() async {
    await store.close();
    await userStore.close();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    // Land the current-chapter shortcut on the seeded chapter.
    SharedPreferences.setMockInitialValues({
      'selectedBookName': '1 Samuel',
      'selectedChapter': 24,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      contentStoreProvider.overrideWithValue(store),
      userStoreProvider.overrideWithValue(userStore),
      sharedPreferencesProvider.overrideWithValue(prefs),
      peopleReadyProvider.overrideWith((ref) async => true),
      placesReadyProvider.overrideWith((ref) async => true),
      topicalIndexReadyProvider.overrideWith((ref) async => true),
      // recordHistory reads this; the real one touches the filesystem.
      deviceIdProvider.overrideWith((ref) async => 'test-device'),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExplorerScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
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

  testWidgets('passage page shows commentary and user-note cards',
      (tester) async {
    // Tall viewport so every facet card is on screen (the page and the
    // breadcrumb bar are both scrollables, which confuses scrollUntilVisible).
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pump(tester);

    await tester.tap(find.textContaining('Explore 1 Samuel 24'));
    await tester.pumpAndSettle();

    // Commentary card, collapsed behind the module name until expanded.
    expect(find.text('Commentaries (1)'), findsOneWidget);
    await tester.tap(find.text('Matthew Henry'));
    await tester.pumpAndSettle();
    // HtmlWidget renders prose as RichText.
    expect(
        find.textContaining('David in the wilderness', findRichText: true),
        findsOneWidget);

    // The user's note for the chapter, anchored to its verse.
    expect(find.text('Your notes (1)'), findsOneWidget);
    expect(find.text('Verse 2'), findsOneWidget);
    expect(
        find.text('Saul chooses three thousand men.'), findsOneWidget);
  });

  testWidgets(
      'tapping a verse switches the shell module back to the reader '
      '(regression: Explorer opened from the dashboard)', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final container = await pump(tester);
    container.read(appModuleProvider.notifier).setModule(AppModule.dashboard);

    // Note tile on the passage page is verse-anchored — tap it.
    await tester.tap(find.textContaining('Explore 1 Samuel 24'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saul chooses three thousand men.'));
    await tester.pumpAndSettle();

    expect(container.read(appModuleProvider), AppModule.reader);
    expect(container.read(selectedBookNameProvider), '1 Samuel');
    expect(container.read(selectedChapterProvider), 24);
  });

  testWidgets('searching finds your tags and the tag page links back into '
      'the knowledge web', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'batt');
    await tester.pumpAndSettle();
    expect(find.text('YOUR TAGS'), findsOneWidget);

    await tester.tap(find.text('#battles'));
    await tester.pumpAndSettle();

    // Page title plus the breadcrumb crumb.
    expect(find.text('#battles'), findsNWidgets(2));
    expect(find.text('Tagged verses (1)'), findsOneWidget);
    expect(find.text('1 Samuel 24:2'), findsOneWidget);
    expect(find.text('Then Saul took three thousand chosen men.'),
        findsOneWidget);
    // The hop back into the knowledge web: the tagged verse's chapter.
    expect(find.text('Explore their chapters'), findsOneWidget);
    expect(find.text('1 Samuel 24'), findsOneWidget);
  });

  testWidgets('passage and person pages show the Your-tags card',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pump(tester);

    await tester.tap(find.textContaining('Explore 1 Samuel 24'));
    await tester.pumpAndSettle();
    expect(find.text('Your tags (1)'), findsOneWidget);
    expect(find.textContaining('#battles', findRichText: true),
        findsOneWidget);

    // Saul appears in 24:2, the tagged verse, so his page carries the tag
    // too — tap through the People facet chip.
    await tester.tap(find.textContaining('Saul', findRichText: true).first);
    await tester.pumpAndSettle();
    expect(find.text('Your tags'), findsOneWidget);
    expect(find.textContaining('#battles', findRichText: true),
        findsOneWidget);
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
