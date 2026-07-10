import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/notebook_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/sermon_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/app_state.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';
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

    await store
        .into(store.biblePeople)
        .insert(
          const BiblePeopleCompanion(
            id: Value(1),
            slug: Value('saul'),
            name: Value('Saul'),
            displayTitle: Value('Saul'),
            verseCount: Value(1),
          ),
        );
    await store
        .into(store.personVerses)
        .insert(
          const PersonVersesCompanion(
            id: Value(1),
            personId: Value(1),
            bookName: Value('1 Samuel'),
            chapter: Value(24),
            verse: Value(2),
          ),
        );
    await store
        .into(store.timelineEvents)
        .insert(
          const TimelineEventsCompanion(
            id: Value(1),
            title: Value('David spares Saul'),
            sortKey: Value(1.0),
            startYear: Value(-1060),
          ),
        );
    await store
        .into(store.eventParticipants)
        .insert(
          const EventParticipantsCompanion(
            id: Value(1),
            eventId: Value(1),
            personId: Value(1),
          ),
        );
    await store
        .into(store.eventVerses)
        .insert(
          const EventVersesCompanion(
            id: Value(1),
            eventId: Value(1),
            ord: Value(0),
            bookName: Value('1 Samuel'),
            chapter: Value(24),
            verse: Value(1),
          ),
        );

    await store
        .into(store.topics)
        .insert(
          const TopicsCompanion(
            id: Value(1),
            name: Value('CAVES'),
            section: Value('C'),
          ),
        );
    await store
        .into(store.topicEntries)
        .insert(
          const TopicEntriesCompanion(
            id: Value(1),
            topicId: Value(1),
            ordinal: Value(0),
            description: Value('As refuges'),
          ),
        );
    await store
        .into(store.topicReferences)
        .insert(
          const TopicReferencesCompanion(
            id: Value(1),
            topicId: Value(1),
            entryId: Value(1),
            bookName: Value('1 Samuel'),
            chapter: Value(24),
            verse: Value(3),
          ),
        );
    // A named-group-style curated topic, standing in for the real
    // CuratedTopicsImporter output this test's `curatedTopicsReadyProvider`
    // override skips — just enough to exercise the person-link facet.
    await store
        .into(store.topics)
        .insert(
          const TopicsCompanion(
            id: Value(2),
            name: Value('REUBEN'),
            section: Value('R'),
            category: Value('tribe'),
          ),
        );
    await store
        .into(store.commentaries)
        .insert(
          const CommentariesCompanion(
            id: Value(1),
            abbreviation: Value('MHC'),
            name: Value('Matthew Henry'),
          ),
        );
    await store
        .into(store.commentaryEntries)
        .insert(
          const CommentaryEntriesCompanion(
            id: Value(1),
            commentaryId: Value(1),
            bookName: Value('1 Samuel'),
            chapter: Value(24),
            verse: Value(1),
            textContent: Value('<p>David in the wilderness of En Gedi.</p>'),
          ),
        );

    await userStore
        .into(userStore.notes)
        .insert(
          const NotesCompanion(
            id: Value('note-1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            bookName: Value('1 Samuel'),
            chapter: Value(24),
            verse: Value(2),
            content: Value('Saul chooses three thousand men.'),
          ),
        );

    // A tag on 1 Samuel 24:2, with the Bible text behind it so the tag page
    // can hydrate the tagged verse.
    await store
        .into(store.versions)
        .insert(
          const VersionsCompanion(
            id: Value('KJV'),
            abbreviation: Value('KJV'),
            name: Value('KJV'),
          ),
        );
    await store
        .into(store.books)
        .insert(
          const BooksCompanion(
            id: Value(1),
            versionId: Value('KJV'),
            name: Value('1 Samuel'),
            bookOrder: Value(9),
            testament: Value('OT'),
          ),
        );
    await store
        .into(store.verses)
        .insert(
          const VersesCompanion(
            id: Value(1),
            bookId: Value(1),
            chapter: Value(24),
            verse: Value(2),
            textContent: Value('Then Saul took three thousand chosen men.'),
            segments: Value('[]'),
          ),
        );
    await userStore
        .into(userStore.tags)
        .insert(
          const TagsCompanion(
            id: Value('tag-battles'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            name: Value('battles'),
            colorHex: Value('#E53935'),
          ),
        );
    await userStore
        .into(userStore.entityTags)
        .insert(
          const EntityTagsCompanion(
            id: Value('link-1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            tagId: Value('tag-battles'),
            entityId: Value('Verse:1 Samuel|24|2'),
            entityType: Value('verse'),
          ),
        );

    // A tag scoped to 24:1 instead of 24:2, so its page's Topics/
    // Commentaries/Cross-references cards (parity with the passage page)
    // have real matches without disturbing tag-battles' existing assertions
    // (the commentary, cross-references, and this second topic reference are
    // all seeded on verse 1 above).
    await store
        .into(store.verses)
        .insert(
          const VersesCompanion(
            id: Value(2),
            bookId: Value(1),
            chapter: Value(24),
            verse: Value(1),
            textContent: Value('David hid in the cave.'),
            segments: Value('[]'),
          ),
        );
    await store
        .into(store.topicReferences)
        .insert(
          const TopicReferencesCompanion(
            id: Value(2),
            topicId: Value(1),
            entryId: Value(1),
            bookName: Value('1 Samuel'),
            chapter: Value(24),
            verse: Value(1),
          ),
        );
    await userStore
        .into(userStore.tags)
        .insert(
          const TagsCompanion(
            id: Value('tag-verse1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            name: Value('verse1'),
          ),
        );
    await userStore
        .into(userStore.entityTags)
        .insert(
          const EntityTagsCompanion(
            id: Value('link-verse1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            tagId: Value('tag-verse1'),
            entityId: Value('Verse:1 Samuel|24|1'),
            entityType: Value('verse'),
          ),
        );

    // A media attachment filed under the same tag, so the tag page's Media
    // card has something to render.
    await userStore
        .into(userStore.mediaAttachments)
        .insert(
          const MediaAttachmentsCompanion(
            id: Value('media-1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            title: Value('En Gedi photo'),
            filename: Value('engedi.jpg'),
            mimeType: Value('image/jpeg'),
            sizeBytes: Value(2048),
            createdAt: Value(0),
          ),
        );
    await userStore
        .into(userStore.entityTags)
        .insert(
          const EntityTagsCompanion(
            id: Value('link-media'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            tagId: Value('tag-battles'),
            entityId: Value('media-1'),
            entityType: Value('media_attachment'),
          ),
        );
    // ...and anchored to 1 Samuel 24 so the passage page's "Your media" card
    // has something to render.
    await userStore
        .into(userStore.attachmentReferences)
        .insert(
          const AttachmentReferencesCompanion(
            id: Value('ref-media-1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            attachmentId: Value('media-1'),
            bookName: Value('1 Samuel'),
            chapter: Value(24),
            createdAt: Value(0),
          ),
        );

    // Two cross-references from 1 Samuel 24:1, votes-descending, for the
    // passage page's Cross-references card.
    await store
        .into(store.crossReferences)
        .insert(
          const CrossReferencesCompanion(
            id: Value(1),
            sourceBookName: Value('1 Samuel'),
            sourceChapter: Value(24),
            sourceVerse: Value(1),
            targetBookName: Value('Genesis'),
            targetChapter: Value(1),
            targetVerse: Value(1),
            votes: Value(3),
          ),
        );
    await store
        .into(store.crossReferences)
        .insert(
          const CrossReferencesCompanion(
            id: Value(2),
            sourceBookName: Value('1 Samuel'),
            sourceChapter: Value(24),
            sourceVerse: Value(1),
            targetBookName: Value('Psalms'),
            targetChapter: Value(57),
            targetVerse: Value(1),
            votes: Value(1),
          ),
        );

    // A sermon citing the chapter, for the passage page's Your-sermons card.
    await userStore
        .into(userStore.sermons)
        .insert(
          const SermonsCompanion(
            id: Value('sermon-1'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            title: Value('Sparing an Enemy'),
            content: Value(''),
            contentPlain: Value(
              'Turn with me to 1 Samuel 24:1, David and Saul.',
            ),
          ),
        );

    // A second sermon explicitly linked to Saul ("Link to Explorer"), for the
    // "Your sermons" card on his person page.
    await userStore
        .into(userStore.sermons)
        .insert(
          SermonsCompanion(
            id: const Value('sermon-2'),
            createdAt: const Value(0),
            updatedAt: const Value(0),
            deviceId: const Value('test-device'),
            title: const Value('The Reluctant King'),
            content: Value(
              jsonEncode([
                {
                  'insert': 'Saul',
                  'attributes': {'link': 'sbent:person|1'},
                },
                {'insert': ' hides among the baggage.\n'},
              ]),
            ),
          ),
        );

    // A notebook page explicitly linked to Saul ("Link to Explorer") and
    // separately citing the chapter in prose, for the "Your notebooks" cards
    // on both the person page and the passage page.
    await userStore
        .into(userStore.notebooks)
        .insert(
          const NotebooksCompanion(
            id: Value('notebook-1'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            title: Value('Study Notes'),
          ),
        );
    await userStore
        .into(userStore.notebookPages)
        .insert(
          NotebookPagesCompanion(
            id: const Value('page-1'),
            createdAt: const Value(0),
            updatedAt: const Value(0),
            deviceId: const Value('test-device'),
            notebookId: const Value('notebook-1'),
            title: const Value('On Saul'),
            content: Value(
              jsonEncode([
                {
                  'insert': 'Saul',
                  'attributes': {'link': 'sbent:person|1'},
                },
                {'insert': ' hides from David in 1 Samuel 24.\n'},
              ]),
            ),
            contentPlain: const Value('Saul hides from David in 1 Samuel 24.'),
          ),
        );
    // A second page citing the same chapter in prose (no explicit entity
    // link), so the passage page's Your-notebooks card has two distinct
    // pages to switch between.
    await userStore
        .into(userStore.notebookPages)
        .insert(
          const NotebookPagesCompanion(
            id: Value('page-2'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            notebookId: Value('notebook-1'),
            title: Value('On the Wilderness'),
            content: Value(
              '[{"insert":"Reflections on 1 Samuel 24 today.\\n"}]',
            ),
            contentPlain: Value('Reflections on 1 Samuel 24 today.'),
          ),
        );
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
      // Matches the seeded KJV/1-Samuel book so the passage-sermons provider
      // (which scans sermon text against booksForVersionProvider) resolves
      // without waiting on the active-versions self-heal correction.
      'activeVersions': ['KJV'],
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
        peopleReadyProvider.overrideWith((ref) async => true),
        placesReadyProvider.overrideWith((ref) async => true),
        topicalIndexReadyProvider.overrideWith((ref) async => true),
        // Skips the real CuratedTopicsImporter, which would otherwise insert
        // every curated feast/story into this test's minimal seeded store
        // and throw off the "N topics" stat chip below.
        curatedTopicsReadyProvider.overrideWith((ref) async => true),
        // recordHistory reads this; the real one touches the filesystem.
        deviceIdProvider.overrideWith((ref) async => 'test-device'),
        // Points the seeded 'REUBEN' tribe topic at the seeded Saul person
        // (id 1) rather than a real production BiblePeople id.
        namedGroupPersonIdsProvider.overrideWith((ref) => {'tribe|REUBEN': 1}),
      ],
    );
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

  testWidgets('home shows the search box and current-chapter shortcut', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Explorer'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Explore '), findsOneWidget);
    // Dataset stat chips reflect the seeded store.
    expect(find.text('1 people'), findsOneWidget);
    expect(find.text('1 topics'), findsOneWidget);
  });

  testWidgets('searching drills into a person page with its facets', (
    tester,
  ) async {
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

  testWidgets('passage page shows commentary and user-note cards', (
    tester,
  ) async {
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
      findsOneWidget,
    );

    // The user's note for the chapter, anchored to its verse.
    expect(find.text('Your notes (1)'), findsOneWidget);
    expect(find.text('Verse 2'), findsOneWidget);
    expect(find.text('Saul chooses three thousand men.'), findsOneWidget);
  });

  testWidgets(
    'passage page shows cross-references and sermons citing the chapter',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final container = await pump(tester);

      await tester.tap(find.textContaining('Explore 1 Samuel 24'));
      await tester.pumpAndSettle();

      // Cross-references card, collapsed by default; expanding it reveals
      // every group, grouped under their source verse and votes-ordered.
      expect(find.text('Cross-references (2)'), findsOneWidget);
      await tester.tap(find.text('Cross-references (2)'));
      await tester.pumpAndSettle();
      expect(find.text('v. 1'), findsOneWidget);
      expect(find.text('Genesis 1:1'), findsOneWidget);
      expect(find.text('Psalms 57:1'), findsOneWidget);

      // The sermon citing this chapter.
      expect(find.text('Your sermons (1)'), findsOneWidget);
      expect(find.text('Sparing an Enemy'), findsOneWidget);

      // Tapping a cross-reference chip jumps the reader to its target (this
      // pops the Explorer route back to the shell, per explorerOpenVerseInReader,
      // so it runs last).
      await tester.tap(find.text('Genesis 1:1'));
      await tester.pumpAndSettle();
      expect(container.read(selectedBookNameProvider), 'Genesis');
      expect(container.read(selectedChapterProvider), 1);
    },
  );

  testWidgets('tapping a sermon on the passage page opens it in the reader', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final container = await pump(tester);

    await tester.tap(find.textContaining('Explore 1 Samuel 24'));
    await tester.pumpAndSettle();

    // Tapping it opens the sermon in the reader's sermon tool (desktop path).
    await tester.tap(find.text('Sparing an Enemy'));
    await tester.pumpAndSettle();
    expect(container.read(appModuleProvider), AppModule.reader);
    expect(container.read(activeToolProvider), ActiveTool.sermons);
    expect(container.read(selectedSermonIdProvider), 'sermon-1');
  });

  testWidgets(
    'tapping a sermon from Explorer keeps the sermons panel open even if '
    'it was already open (regression: setTool toggled it closed)',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final container = await pump(tester);
      // Simulate the sermons panel already being open before jumping in from
      // Explorer — this is the state that used to trigger the bug.
      container.read(activeToolProvider.notifier).openTool(ActiveTool.sermons);

      await tester.tap(find.textContaining('Explore 1 Samuel 24'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sparing an Enemy'));
      await tester.pumpAndSettle();

      expect(container.read(activeToolProvider), ActiveTool.sermons);
      expect(container.read(selectedSermonIdProvider), 'sermon-1');
    },
  );

  testWidgets(
    'passage and person pages show the Your-notebooks card, linked back '
    'to the reader-side notebook editor',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final container = await pump(tester);

      await tester.tap(find.textContaining('Explore 1 Samuel 24'));
      await tester.pumpAndSettle();
      // Both pages cite the chapter; only "On Saul" explicitly links to him.
      expect(find.text('Your notebooks (2)'), findsOneWidget);
      expect(find.text('On Saul'), findsOneWidget);
      expect(find.text('On the Wilderness'), findsOneWidget);

      // Saul's own page carries the backlink too, since the notebook page
      // explicitly links to him (not just cites the chapter in prose).
      await tester.tap(find.textContaining('Saul', findRichText: true).first);
      await tester.pumpAndSettle();
      expect(find.text('Your notebooks (1)'), findsOneWidget);

      // Tapping it opens the page in the reader's notebooks tool (desktop path).
      await tester.tap(find.text('On Saul'));
      await tester.pumpAndSettle();
      expect(container.read(appModuleProvider), AppModule.reader);
      expect(container.read(activeToolProvider), ActiveTool.notebooks);
      expect(container.read(selectedNotebookPageIdProvider), 'page-1');
    },
  );

  testWidgets('person page shows the Your-sermons card, linked back to the '
      'reader-side sermon editor', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final container = await pump(tester);

    await tester.enterText(find.byType(TextField), 'Saul');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Saul'));
    await tester.pumpAndSettle();

    // Only "The Reluctant King" explicitly links to Saul; "Sparing an Enemy"
    // merely mentions him in prose and must not show up here.
    expect(find.text('Your sermons (1)'), findsOneWidget);
    expect(find.text('The Reluctant King'), findsOneWidget);
    expect(find.text('Sparing an Enemy'), findsNothing);

    // Tapping it opens the sermon in the reader's sermon tool (desktop path).
    await tester.tap(find.text('The Reluctant King'));
    await tester.pumpAndSettle();
    expect(container.read(appModuleProvider), AppModule.reader);
    expect(container.read(activeToolProvider), ActiveTool.sermons);
    expect(container.read(selectedSermonIdProvider), 'sermon-2');
  });

  testWidgets(
    'tapping a notebook page from Explorer keeps the notebooks panel open '
    'even if it was already open (regression: setTool toggled it closed)',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final container = await pump(tester);
      // Simulate the notebooks panel already being open before jumping in from
      // Explorer — this is the state that used to trigger the bug.
      container
          .read(activeToolProvider.notifier)
          .openTool(ActiveTool.notebooks);

      await tester.tap(find.textContaining('Explore 1 Samuel 24'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('On Saul'));
      await tester.pumpAndSettle();

      expect(container.read(activeToolProvider), ActiveTool.notebooks);
      expect(container.read(selectedNotebookPageIdProvider), 'page-1');
    },
  );

  testWidgets('tapping a verse switches the shell module back to the reader '
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
    expect(
      find.text('Then Saul took three thousand chosen men.'),
      findsOneWidget,
    );
    // The hop back into the knowledge web: the tagged verse's chapter.
    expect(find.text('Explore their chapters'), findsOneWidget);
    expect(find.text('1 Samuel 24'), findsOneWidget);
    // The tag's verses are cross-referenced into the datasets: Saul is named
    // in 1 Samuel 24:2 (the tagged verse), so he surfaces on a People card.
    expect(find.text('People in these verses (1)'), findsOneWidget);
    // Tagged media is filed under its own card.
    expect(find.text('Media (1)'), findsOneWidget);
    expect(find.text('En Gedi photo'), findsOneWidget);
  });

  testWidgets(
    'tag page shows Topics/Commentaries/Cross-references, matching the '
    'passage page (Expand Tags card in Explorer)',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'verse1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('#verse1'));
      await tester.pumpAndSettle();

      expect(find.text('Topics in these verses (1)'), findsOneWidget);
      expect(find.textContaining('CAVES', findRichText: true), findsOneWidget);

      expect(find.text('Commentaries (1)'), findsOneWidget);
      await tester.tap(find.text('Matthew Henry'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('David in the wilderness', findRichText: true),
        findsOneWidget,
      );

      expect(find.text('Cross-references (2)'), findsOneWidget);
      await tester.tap(find.text('Cross-references (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Genesis 1:1'), findsOneWidget);
      expect(find.text('Psalms 57:1'), findsOneWidget);
    },
  );

  testWidgets('passage and person pages show the Your-tags card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pump(tester);

    await tester.tap(find.textContaining('Explore 1 Samuel 24'));
    await tester.pumpAndSettle();
    // #battles (24:2) and #verse1 (24:1) both land in this chapter.
    expect(find.text('Your tags (2)'), findsOneWidget);
    expect(find.textContaining('#battles', findRichText: true), findsOneWidget);
    // User-uploaded media anchored to this chapter shows on the passage page.
    expect(find.text('Your media (1)'), findsOneWidget);
    expect(find.text('En Gedi photo'), findsOneWidget);

    // Saul appears in 24:2, the tagged verse, so his page carries the tag
    // too — tap through the People facet chip.
    await tester.tap(find.textContaining('Saul', findRichText: true).first);
    await tester.pumpAndSettle();
    expect(find.text('Your tags'), findsOneWidget);
    expect(find.textContaining('#battles', findRichText: true), findsOneWidget);
  });

  testWidgets('breadcrumb home returns to search; topic page renders entries', (
    tester,
  ) async {
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

  testWidgets(
      'a named-group topic with a hand-verified person link shows a '
      'tappable Person facet', (tester) async {
    final container = await pump(tester);

    container
        .read(explorerTrailProvider.notifier)
        .open(const ExplorerRef.topic(2, 'REUBEN'));
    await tester.pumpAndSettle();

    expect(find.text('One of the 12 Tribes of Israel'), findsOneWidget);
    expect(find.text('Person'), findsOneWidget);
    // The chip's label mirrors the topic's own name (REUBEN); the seeded
    // link points it at the seeded person (id 1, "Saul") to avoid needing a
    // second person fixture — tapping through proves it's a real id lookup,
    // not just an inert label.
    expect(find.textContaining('REUBEN', findRichText: true), findsWidgets);

    await tester.tap(find.textContaining('REUBEN', findRichText: true).last);
    await tester.pumpAndSettle();

    // Landed on Saul's own person page, not just a chip with his name.
    expect(find.text('Saul'), findsOneWidget);
    expect(find.text('Your tags'), findsOneWidget);
  });
}
