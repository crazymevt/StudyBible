import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/search_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';

/// Exercises the Explorer's cross-dataset joins: events↔places and
/// people↔places are linked through shared verses, the passage overview
/// aggregates every dataset for one chapter, the user's tags join in through
/// verse refs, and the trail notifier drives breadcrumb navigation.
void main() {
  // One test spins up a second in-memory ContentStore (the "no dictionary
  // installed" case), which drift otherwise warns about.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ContentStore store;
  late UserStore userStore;
  late ProviderContainer container;

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());

    // People: David (3 verses), Saul (1 verse).
    Future<void> person(int id, String name, int verseCount) => store
        .into(store.biblePeople)
        .insert(
          BiblePeopleCompanion(
            id: Value(id),
            slug: Value(name.toLowerCase()),
            name: Value(name),
            displayTitle: Value(name),
            verseCount: Value(verseCount),
          ),
        );
    await person(1, 'David', 3);
    await person(2, 'Saul', 1);

    Future<void> personVerse(int id, int p, String book, int ch, int v) => store
        .into(store.personVerses)
        .insert(
          PersonVersesCompanion(
            id: Value(id),
            personId: Value(p),
            bookName: Value(book),
            chapter: Value(ch),
            verse: Value(v),
          ),
        );
    await personVerse(1, 1, '1 Samuel', 24, 1);
    await personVerse(2, 1, '1 Samuel', 24, 2);
    await personVerse(3, 1, 'Psalms', 57, 1);
    await personVerse(4, 2, '1 Samuel', 24, 2);

    // Places: En Gedi is in 1 Samuel 24, Ziph is not.
    Future<void> place(int id, String name) => store
        .into(store.places)
        .insert(
          PlacesCompanion(
            id: Value(id),
            name: Value(name),
            lat: const Value(31.46),
            lng: const Value(35.38),
          ),
        );
    await place(1, 'En Gedi');
    await place(2, 'Ziph');

    Future<void> placeVerse(int id, int p, String book, int ch, int v) => store
        .into(store.placeVerses)
        .insert(
          PlaceVersesCompanion(
            id: Value(id),
            placeId: Value(p),
            bookName: Value(book),
            chapter: Value(ch),
            verse: Value(v),
          ),
        );
    await placeVerse(1, 1, '1 Samuel', 24, 1);
    await placeVerse(2, 2, '1 Samuel', 23, 14);

    // Events: one in 1 Samuel 24 (both people participate), one elsewhere.
    Future<void> event(int id, String title, double sortKey, int year) => store
        .into(store.timelineEvents)
        .insert(
          TimelineEventsCompanion(
            id: Value(id),
            title: Value(title),
            sortKey: Value(sortKey),
            startYear: Value(year),
          ),
        );
    await event(1, 'David spares Saul', 1.0, -1060);
    await event(2, 'Creation', 0.0, -4003);

    Future<void> participant(int id, int e, int p) => store
        .into(store.eventParticipants)
        .insert(
          EventParticipantsCompanion(
            id: Value(id),
            eventId: Value(e),
            personId: Value(p),
          ),
        );
    await participant(1, 1, 2); // Saul inserted first on purpose:
    await participant(2, 1, 1); // participants sort by verse count, not id.

    Future<void> eventVerse(
      int id,
      int e,
      int ord,
      String book,
      int ch,
      int v,
    ) => store
        .into(store.eventVerses)
        .insert(
          EventVersesCompanion(
            id: Value(id),
            eventId: Value(e),
            ord: Value(ord),
            bookName: Value(book),
            chapter: Value(ch),
            verse: Value(v),
          ),
        );
    await eventVerse(1, 1, 0, '1 Samuel', 24, 1);
    await eventVerse(2, 1, 1, '1 Samuel', 24, 2);
    await eventVerse(3, 2, 0, 'Genesis', 1, 1);

    // Topics: one referencing 1 Samuel 24.
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
    // A second reference to the same topic, on a verse tag-david/tag-caves
    // actually tag (24:1) — for the tag page's topic cross-reference card.
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

    // Commentaries: Henry has entries in 1 Samuel 24, Scofield doesn't.
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
        .into(store.commentaries)
        .insert(
          const CommentariesCompanion(
            id: Value(2),
            abbreviation: Value('SCO'),
            name: Value('Scofield'),
          ),
        );
    Future<void> commentaryEntry(
      int id,
      int commentary,
      String book,
      int ch,
      int v,
      String text,
    ) => store
        .into(store.commentaryEntries)
        .insert(
          CommentaryEntriesCompanion(
            id: Value(id),
            commentaryId: Value(commentary),
            bookName: Value(book),
            chapter: Value(ch),
            verse: Value(v),
            textContent: Value(text),
          ),
        );
    await commentaryEntry(1, 1, '1 Samuel', 24, 2, 'On verse two');
    await commentaryEntry(2, 1, '1 Samuel', 24, 1, 'On verse one');
    await commentaryEntry(3, 2, 'Genesis', 1, 1, 'Elsewhere');

    // Cross-references: two from 1 Samuel 24:1 (vote-ordered), one from
    // 24:2, one from an unrelated chapter (scoping check).
    Future<void> xref(
      int id,
      String srcBook,
      int srcCh,
      int srcV,
      String tgtBook,
      int tgtCh,
      int tgtV,
      int? votes,
    ) => store
        .into(store.crossReferences)
        .insert(
          CrossReferencesCompanion(
            id: Value(id),
            sourceBookName: Value(srcBook),
            sourceChapter: Value(srcCh),
            sourceVerse: Value(srcV),
            targetBookName: Value(tgtBook),
            targetChapter: Value(tgtCh),
            targetVerse: Value(tgtV),
            votes: Value(votes),
          ),
        );
    await xref(1, '1 Samuel', 24, 1, 'Psalms', 57, 1, 2);
    await xref(2, '1 Samuel', 24, 1, 'Genesis', 1, 1, 5);
    await xref(3, '1 Samuel', 24, 2, 'Psalms', 57, 1, null);
    await xref(4, 'Genesis', 1, 1, '1 Samuel', 24, 1, null);

    // Dictionary: Easton's, keyed by headword. Powers the place/topic
    // dictionary card. "Caves" matches the CAVES topic case-insensitively;
    // "Ziph" tests parenthetical-qualifier stripping.
    await store
        .into(store.dictionaries)
        .insert(
          const DictionariesCompanion(
            id: Value(1),
            abbreviation: Value('EBD'),
            name: Value("Easton's Bible Dictionary"),
          ),
        );
    Future<void> dictEntry(int id, int dict, String word, String def) => store
        .into(store.dictionaryEntries)
        .insert(
          DictionaryEntriesCompanion(
            id: Value(id),
            dictionaryId: Value(dict),
            word: Value(word),
            definition: Value(def),
          ),
        );
    await dictEntry(1, 1, 'Caves', '<p>Hollow places.</p>');
    await dictEntry(2, 1, 'En Gedi', '<p>Spring of the goat.</p>');
    await dictEntry(3, 1, 'Ziph', '<p>A city of Judah.</p>');

    // Bible text, so tagged-verse entity ids resolve to real verses (the tag
    // page hydrates them through entitiesForTagProvider).
    await store
        .into(store.versions)
        .insert(
          const VersionsCompanion(
            id: Value('KJV'),
            abbreviation: Value('KJV'),
            name: Value('KJV'),
          ),
        );
    Future<void> book(int id, String name, int order) => store
        .into(store.books)
        .insert(
          BooksCompanion(
            id: Value(id),
            versionId: const Value('KJV'),
            name: Value(name),
            bookOrder: Value(order),
            testament: const Value('OT'),
          ),
        );
    await book(1, '1 Samuel', 9);
    await book(2, 'Psalms', 19);
    Future<void> bibleVerse(int id, int bookId, int ch, int v, String text) =>
        store
            .into(store.verses)
            .insert(
              VersesCompanion(
                id: Value(id),
                bookId: Value(bookId),
                chapter: Value(ch),
                verse: Value(v),
                textContent: Value(text),
                segments: const Value('[]'),
              ),
            );
    await bibleVerse(1, 1, 24, 1, 'David is in the wilderness of En Gedi.');
    await bibleVerse(2, 1, 24, 2, 'Saul took three thousand chosen men.');
    await bibleVerse(3, 2, 57, 1, 'Be merciful unto me, O God.');

    // The user's tags. 'david' spans two verses plus one item of every other
    // kind; 'caves' co-occurs with it on 1 Samuel 24:1. A deleted tag and a
    // deleted link prove soft-deletes stay invisible.
    Future<void> tag(
      String id,
      String name, {
      String? color,
      bool deleted = false,
    }) => userStore
        .into(userStore.tags)
        .insert(
          TagsCompanion(
            id: Value(id),
            updatedAt: const Value(0),
            deviceId: const Value('test-device'),
            name: Value(name),
            colorHex: Value(color),
            deleted: Value(deleted),
          ),
        );
    await tag('tag-david', 'david', color: '#1E88E5');
    await tag('tag-caves', 'caves');
    await tag('tag-gone', 'gone', deleted: true);

    var linkId = 0;
    Future<void> link(
      String tagId,
      String entityId,
      String entityType, {
      bool deleted = false,
    }) => userStore
        .into(userStore.entityTags)
        .insert(
          EntityTagsCompanion(
            id: Value('link-${linkId++}'),
            updatedAt: const Value(0),
            deviceId: const Value('test-device'),
            tagId: Value(tagId),
            entityId: Value(entityId),
            entityType: Value(entityType),
            deleted: Value(deleted),
          ),
        );
    await link('tag-david', 'Verse:1 Samuel|24|1', 'verse');
    await link('tag-david', 'Verse:Psalms|57|1', 'verse');
    await link('tag-david', 'note-1', 'note');
    await link('tag-david', 'sermon-1', 'sermon');
    await link('tag-david', 'journal-1', 'journal');
    await link('tag-david', 'prayer-1', 'prayer');
    await link('tag-caves', 'Verse:1 Samuel|24|1', 'verse');
    await link('tag-david', 'Verse:1 Samuel|24|2', 'verse', deleted: true);
    await link('tag-gone', 'Verse:1 Samuel|24|1', 'verse');

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
            content: Value('Saul chooses his men.'),
          ),
        );
    await userStore
        .into(userStore.sermons)
        .insert(
          const SermonsCompanion(
            id: Value('sermon-1'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            title: Value('On Caves'),
            content: Value(''),
          ),
        );
    // Cites 1 Samuel 24 — should show up on that chapter's passage page.
    await userStore
        .into(userStore.sermons)
        .insert(
          const SermonsCompanion(
            id: Value('sermon-2'),
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
    // Cites Psalms 57 only — proves passage-sermon matching is chapter-scoped.
    await userStore
        .into(userStore.sermons)
        .insert(
          const SermonsCompanion(
            id: Value('sermon-3'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            title: Value('A Psalm of Refuge'),
            content: Value(''),
            contentPlain: Value("Let's look at Psalms 57 today."),
          ),
        );
    // Explicitly links David (via "Link to Explorer"), for the person
    // backlink card — mirrors notebook page-1 below.
    await userStore
        .into(userStore.sermons)
        .insert(
          SermonsCompanion(
            id: const Value('sermon-4'),
            createdAt: const Value(0),
            updatedAt: const Value(0),
            deviceId: const Value('test-device'),
            title: const Value('David\'s Restraint'),
            content: Value(
              jsonEncode([
                {
                  'insert': 'David',
                  'attributes': {'link': 'sbent:person|1'},
                },
                {'insert': ' shows restraint.\n'},
              ]),
            ),
          ),
        );
    await userStore
        .into(userStore.journals)
        .insert(
          const JournalsCompanion(
            id: Value('journal-1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            title: Value('Wilderness thoughts'),
            content: Value(''),
            contentPlain: Value('Thinking about En Gedi.'),
          ),
        );
    await userStore
        .into(userStore.prayers)
        .insert(
          const PrayersCompanion(
            id: Value('prayer-1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            name: Value('For refuge'),
            description: Value('Psalm 57 prayer'),
            createdAt: Value(0),
          ),
        );

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
    // Explicitly links David (via "Link to Explorer") and separately cites
    // 1 Samuel 24 in prose, for the person/passage backlink cards.
    await userStore
        .into(userStore.notebookPages)
        .insert(
          NotebookPagesCompanion(
            id: const Value('page-1'),
            createdAt: const Value(0),
            updatedAt: const Value(0),
            deviceId: const Value('test-device'),
            notebookId: const Value('notebook-1'),
            title: const Value('On David'),
            content: Value(
              jsonEncode([
                {
                  'insert': 'David',
                  'attributes': {'link': 'sbent:person|1'},
                },
                {'insert': ' hid in 1 Samuel 24:1.\n'},
              ]),
            ),
            contentPlain: const Value('David hid in 1 Samuel 24:1.'),
          ),
        );
    // Cites Psalms 57 only, and links no entity — proves both matchers are
    // scoped correctly (chapter for passages, exact id for entities).
    await userStore
        .into(userStore.notebookPages)
        .insert(
          const NotebookPagesCompanion(
            id: Value('page-2'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            notebookId: Value('notebook-1'),
            title: Value('On Refuge'),
            content: Value('[{"insert":"Let\'s look at Psalms 57 today.\\n"}]'),
            contentPlain: Value("Let's look at Psalms 57 today."),
          ),
        );
    // Tags "On David" directly, for the tag page's own Notebooks card
    // (distinct from the entity-link backlink tested above).
    await link('tag-david', 'page-1', 'notebookPage');

    // Pins the reader's active version to the one seeded above so the
    // passage-sermons provider (which resolves references against
    // booksForVersionProvider(activeVersionsProvider.first)) doesn't have to
    // wait on the self-heal listener that otherwise corrects a mismatched
    // default (see the "universal search" group below for the same gotcha).
    SharedPreferences.setMockInitialValues({
      'activeVersions': ['KJV'],
    });
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
        peopleReadyProvider.overrideWith((ref) async => true),
        placesReadyProvider.overrideWith((ref) async => true),
        topicalIndexReadyProvider.overrideWith((ref) async => true),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
    await userStore.close();
  });

  /// First data emission of a stream-backed provider. Reading its `.future`
  /// directly races the container teardown (see ribbons_test), so listen and
  /// complete on the first [AsyncData] instead.
  Future<T> firstData<T>(StreamProvider<T> provider) {
    final completer = Completer<T>();
    final sub = container.listen<AsyncValue<T>>(provider, (_, next) {
      if (next is AsyncData<T> && !completer.isCompleted) {
        completer.complete(next.value);
      }
    }, fireImmediately: true);
    return completer.future.whenComplete(sub.close);
  }

  group('trail notifier', () {
    test('open appends, dedupes consecutive repeats, truncate and pop', () {
      final trail = container.read(explorerTrailProvider.notifier);
      final david = const ExplorerRef.person(1, 'David');
      final enGedi = const ExplorerRef.place(1, 'En Gedi');

      trail.open(david);
      trail.open(david); // same destination — no duplicate crumb
      trail.open(enGedi);
      expect(container.read(explorerTrailProvider), [david, enGedi]);

      trail.truncateTo(0);
      expect(container.read(explorerTrailProvider), [david]);

      trail.open(enGedi);
      trail.pop();
      expect(container.read(explorerTrailProvider), [david]);

      trail.clear();
      expect(container.read(explorerTrailProvider), isEmpty);
    });
  });

  group('event detail', () {
    test(
      'joins participants, ordered verses, and places via shared verses',
      () async {
        final d = await container.read(explorerEventDetailProvider(1).future);
        expect(d, isNotNull);
        // Most-mentioned participant first, regardless of insert order.
        expect(d!.participants.map((p) => p.name).toList(), ['David', 'Saul']);
        expect(d.verses.map((v) => v.verse).toList(), [1, 2]);
        // En Gedi shares 1 Samuel 24:1 with the event; Ziph doesn't.
        expect(d.places.map((p) => p.name).toList(), ['En Gedi']);
      },
    );

    test('unknown event resolves to null', () async {
      expect(
        await container.read(explorerEventDetailProvider(99).future),
        isNull,
      );
    });
  });

  group('place detail', () {
    test(
      'reverse-joins events and people through the place\'s verses',
      () async {
        final d = await container.read(explorerPlaceDetailProvider(1).future);
        expect(d, isNotNull);
        expect(d!.verses.length, 1);
        expect(d.events.map((e) => e.title).toList(), ['David spares Saul']);
        // Only David is tagged in 1 Samuel 24:1 (Saul appears in v2).
        expect(d.people.map((p) => p.name).toList(), ['David']);
      },
    );
  });

  group('person places', () {
    test('finds places co-mentioned in the person\'s verses', () async {
      final places = await container.read(
        explorerPersonPlacesProvider(1).future,
      );
      expect(places.map((p) => p.name).toList(), ['En Gedi']);
    });

    test('no shared verses means no places', () async {
      final places = await container.read(
        explorerPersonPlacesProvider(2).future,
      );
      expect(places, isEmpty);
    });
  });

  group('passage overview', () {
    test(
      'aggregates people, places, events, and topics for a chapter',
      () async {
        final d = await container.read(
          explorerPassageOverviewProvider((
            book: '1 Samuel',
            chapter: 24,
          )).future,
        );
        expect(d.people.map((p) => p.displayTitle).toList(), ['David', 'Saul']);
        expect(d.places.map((p) => p.name).toList(), ['En Gedi']);
        expect(d.events.map((e) => e.title).toList(), ['David spares Saul']);
        expect(d.topics.map((t) => t.name).toList(), ['CAVES']);
      },
    );

    test('untagged chapter is empty', () async {
      final d = await container.read(
        explorerPassageOverviewProvider((book: 'Obadiah', chapter: 1)).future,
      );
      expect(d.isEmpty, isTrue);
    });
  });

  group('passage commentaries', () {
    test('groups chapter entries by module, verse-ordered, skipping modules '
        'with nothing for the chapter', () async {
      final sections = await container.read(
        explorerPassageCommentariesProvider((
          book: '1 Samuel',
          chapter: 24,
        )).future,
      );
      expect(sections.length, 1);
      expect(sections.single.commentary.name, 'Matthew Henry');
      expect(sections.single.entries.map((e) => e.verse).toList(), [1, 2]);
    });

    test('chapter without entries returns empty', () async {
      final sections = await container.read(
        explorerPassageCommentariesProvider((
          book: 'Obadiah',
          chapter: 1,
        )).future,
      );
      expect(sections, isEmpty);
    });
  });

  group('passage cross-references', () {
    test('groups by source verse, votes-descending within a verse, '
        'scoped to the chapter', () async {
      final groups = await container.read(
        explorerPassageCrossReferencesProvider((
          book: '1 Samuel',
          chapter: 24,
        )).future,
      );
      expect(groups.map((g) => g.verse).toList(), [1, 2]);
      expect(
        groups[0].refs.map((r) => '${r.targetBookName} ${r.votes}').toList(),
        ['Genesis 5', 'Psalms 2'],
      );
      expect(groups[1].refs.single.targetBookName, 'Psalms');
    });

    test('chapter without cross-references returns empty', () async {
      final groups = await container.read(
        explorerPassageCrossReferencesProvider((
          book: 'Obadiah',
          chapter: 1,
        )).future,
      );
      expect(groups, isEmpty);
    });
  });

  group('passage sermons', () {
    // explorerSermonsProvider watches allSermonsProvider, a plain
    // StreamProvider backed by a Drift .watch() query — reading its .future
    // cold (no active listener) never resolves, so every test in this group
    // holds a throwaway listen for the duration of the read (same fix as the
    // "universal search" group above).
    Future<List<SearchResult>> sermonsFor(String book, int chapter) async {
      final provider = explorerSermonsProvider(
        ExplorerRef.passage(book, chapter),
      );
      final sub = container.listen(provider, (_, _) {});
      try {
        return await container.read(provider.future);
      } finally {
        sub.close();
      }
    }

    test('sermon citing the chapter is included', () async {
      final results = await sermonsFor('1 Samuel', 24);
      expect(results.map((r) => r.title).toList(), ['Sparing an Enemy']);
      expect(results.single.type, 'sermon');
      expect(results.single.referenceId, 'sermon-2');
    });

    test('sermon citing a different chapter is excluded', () async {
      final results = await sermonsFor('Psalms', 57);
      expect(results.map((r) => r.title).toList(), ['A Psalm of Refuge']);
    });

    test('chapter with no citing sermon returns empty', () async {
      expect(await sermonsFor('Obadiah', 1), isEmpty);
    });
  });

  group('sermon entity backlinks', () {
    // Same cold-read gotcha as the group above.
    Future<List<SearchResult>> sermonsFor(ExplorerRef target) async {
      final provider = explorerSermonsProvider(target);
      final sub = container.listen(provider, (_, _) {});
      try {
        return await container.read(provider.future);
      } finally {
        sub.close();
      }
    }

    test(
      'person match requires an explicit Link-to-Explorer, not prose',
      () async {
        final results = await sermonsFor(const ExplorerRef.person(1, 'David'));
        expect(results.map((r) => r.title).toList(), ['David\'s Restraint']);
        expect(results.single.type, 'sermon');
        expect(results.single.referenceId, 'sermon-4');

        // Saul is mentioned nowhere via an explicit link.
        expect(await sermonsFor(const ExplorerRef.person(2, 'Saul')), isEmpty);
      },
    );

    test('place/event/topic with no linked sermon returns empty', () async {
      expect(await sermonsFor(const ExplorerRef.place(1, 'En Gedi')), isEmpty);
      expect(
        await sermonsFor(const ExplorerRef.event(1, 'Some event')),
        isEmpty,
      );
      expect(
        await sermonsFor(const ExplorerRef.topic(1, 'Some topic')),
        isEmpty,
      );
    });
  });

  group('notebook backlinks', () {
    // explorerNotebookPagesProvider watches allNotebookPagesProvider, a plain
    // StreamProvider backed by a Drift .watch() query — same cold-read gotcha
    // as the sermons group above.
    Future<List<SearchResult>> notebooksFor(ExplorerRef target) async {
      final provider = explorerNotebookPagesProvider(target);
      final sub = container.listen(provider, (_, _) {});
      try {
        return await container.read(provider.future);
      } finally {
        sub.close();
      }
    }

    test('passage match scans prose like sermons, chapter-scoped', () async {
      final results = await notebooksFor(ExplorerRef.passage('1 Samuel', 24));
      expect(results.map((r) => r.title).toList(), ['On David']);
      expect(results.single.type, 'notebookPage');
      expect(results.single.referenceId, 'page-1');

      expect(
        (await notebooksFor(
          ExplorerRef.passage('Psalms', 57),
        )).map((r) => r.title),
        ['On Refuge'],
      );
      expect(await notebooksFor(ExplorerRef.passage('Obadiah', 1)), isEmpty);
    });

    test(
      'person match requires an explicit Link-to-Explorer, not prose',
      () async {
        final results = await notebooksFor(
          const ExplorerRef.person(1, 'David'),
        );
        expect(results.map((r) => r.title).toList(), ['On David']);

        // Saul is mentioned nowhere via an explicit link.
        expect(
          await notebooksFor(const ExplorerRef.person(2, 'Saul')),
          isEmpty,
        );
      },
    );

    test('place/event/topic with no linked page returns empty', () async {
      expect(
        await notebooksFor(const ExplorerRef.place(1, 'En Gedi')),
        isEmpty,
      );
      expect(
        await notebooksFor(const ExplorerRef.event(1, 'Some event')),
        isEmpty,
      );
      expect(
        await notebooksFor(const ExplorerRef.topic(1, 'Some topic')),
        isEmpty,
      );
    });
  });

  group('entity dictionary lookup', () {
    test('matches a topic headword case-insensitively', () async {
      final entries = await container.read(
        explorerEntryDictionaryProvider('CAVES').future,
      );
      expect(entries.map((e) => e.entry.word).toList(), ['Caves']);
      expect(entries.single.dictionary.name, "Easton's Bible Dictionary");
    });

    test('matches a place name', () async {
      final entries = await container.read(
        explorerEntryDictionaryProvider('En Gedi').future,
      );
      expect(entries.single.entry.word, 'En Gedi');
    });

    test('strips a trailing parenthetical qualifier', () async {
      final entries = await container.read(
        explorerEntryDictionaryProvider('Ziph (2)').future,
      );
      expect(entries.single.entry.word, 'Ziph');
    });

    test('no headword match returns empty', () async {
      expect(
        await container.read(explorerEntryDictionaryProvider('Nowhere').future),
        isEmpty,
      );
    });

    test('no installed dictionary returns empty', () async {
      final bare = ContentStore(NativeDatabase.memory());
      addTearDown(bare.close);
      final c = ProviderContainer(
        overrides: [contentStoreProvider.overrideWithValue(bare)],
      );
      addTearDown(c.dispose);
      expect(
        await c.read(explorerEntryDictionaryProvider('Caves').future),
        isEmpty,
      );
    });
  });

  group('universal search', () {
    // Holds a subscription while awaiting: without a listener, Riverpod 3
    // pauses the provider if a dependency invalidates it mid-computation
    // (the active-versions self-heal does exactly that on the first search),
    // and the pending future never completes.
    Future<ExplorerSearchResults> search(String q) async {
      final sub = container.listen(explorerSearchResultsProvider, (_, _) {});
      container.read(explorerSearchQueryProvider.notifier).setQuery(q);
      try {
        return await container.read(explorerSearchResultsProvider.future);
      } finally {
        sub.close();
      }
    }

    test('finds each entity kind by name', () async {
      final people = await search('David');
      expect(people.people.map((i) => i.ref.label), contains('David'));
      // "David spares Saul" also matches the event search.
      expect(
        people.events.map((i) => i.ref.label),
        contains('David spares Saul'),
      );

      final places = await search('En Gedi');
      expect(places.places.single.ref.label, 'En Gedi');
      expect(places.places.single.ref.type, ExplorerEntityType.place);

      final topics = await search('cave');
      expect(topics.topics.single.ref.label, 'CAVES');
    });

    test('short queries return nothing', () async {
      expect((await search('d')).isEmpty, isTrue);
    });

    test('finds your tags, with and without the # prefix, counting live '
        'links only', () async {
      final plain = await search('dav');
      expect(plain.tags.single.tag.name, 'david');
      expect(plain.tags.single.tag.colorHex, '#1E88E5');
      // Seven live links; the deleted verse link doesn't count.
      expect(plain.tags.single.itemCount, 7);

      final hashed = await search('#dav');
      expect(hashed.tags.single.tag.name, 'david');
    });

    test('deleted tags never surface', () async {
      expect((await search('gone')).tags, isEmpty);
    });
  });

  group('tag detail', () {
    test('splits items by kind, verses in canonical order, with the distinct '
        'chapters as passages', () async {
      final d = await container.read(
        explorerTagDetailProvider('tag-david').future,
      );
      expect(d, isNotNull);
      expect(d!.tag.name, 'david');

      // 1 Samuel (book order 9) sorts before Psalms (19); the deleted
      // verse link (24:2) is gone.
      expect(d.verses.map((v) => v.title).toList(), [
        '1 Samuel 24:1',
        'Psalms 57:1',
      ]);
      expect(d.notes.single.textContent, 'Saul chooses his men.');
      expect(d.sermons.single.title, 'Sermon: On Caves');
      expect(d.journals.single.textContent, 'Thinking about En Gedi.');
      expect(d.prayers.single.title, 'Prayer: For refuge');
      expect(d.notebooks.single.title, 'Notebook: On David');
      expect(d.isEmpty, isFalse);

      expect(d.passages, [
        (book: '1 Samuel', chapter: 24),
        (book: 'Psalms', chapter: 57),
      ]);
    });

    test('finds related tags through shared items', () async {
      final d = await container.read(
        explorerTagDetailProvider('tag-david').future,
      );
      // 'caves' shares 1 Samuel 24:1; the deleted 'gone' tag does not appear.
      expect(d!.related.single.tag.name, 'caves');
      expect(d.related.single.itemCount, 1);
    });

    test('unknown and deleted tags resolve to null', () async {
      expect(
        await container.read(explorerTagDetailProvider('nope').future),
        isNull,
      );
      expect(
        await container.read(explorerTagDetailProvider('tag-gone').future),
        isNull,
      );
    });
  });

  group('tag cross-references (parity with the passage page)', () {
    test('topics: counts only the tagged verse a reference touches, not '
        'every reference to that topic in the chapter', () async {
      final crossRefs = await container.read(
        explorerTagCrossRefsProvider('tag-david').future,
      );
      // CAVES references both 24:1 (tagged) and 24:3 (not tagged) — only the
      // tagged one should count.
      expect(crossRefs.topics.single.label, 'CAVES');
      expect(crossRefs.topics.single.verseCount, 1);
    });

    test(
      'untagged verses on a chapter-wide topic reference are excluded',
      () async {
        // tag-caves also tags 24:1 but not 24:3, so it sees the same single
        // match — proves the scoping isn't accidentally chapter-wide.
        final crossRefs = await container.read(
          explorerTagCrossRefsProvider('tag-caves').future,
        );
        expect(crossRefs.topics.single.verseCount, 1);
      },
    );

    test('commentaries: only entries on a tagged verse', () async {
      final sections = await container.read(
        explorerTagCommentariesProvider('tag-david').future,
      );
      // Matthew Henry has entries on both 24:1 (tagged) and 24:2 (not);
      // Scofield has none in this chapter at all.
      expect(sections.single.commentary.name, 'Matthew Henry');
      expect(sections.single.entries.single.textContent, 'On verse one');
    });

    test('cross-references: only rows sourced from a tagged verse, '
        'votes-descending', () async {
      final groups = await container.read(
        explorerTagCrossReferencesProvider('tag-david').future,
      );
      // Sourced from 24:1 (tagged); the 24:2-sourced row is excluded (that
      // verse link is soft-deleted).
      expect(groups.single.verse, 1);
      expect(groups.single.refs.map((r) => r.targetBookName).toList(), [
        'Genesis',
        'Psalms',
      ]); // votes 5, then 2
    });

    test('a tag with no tagged verses returns empty for all three', () async {
      expect(
        (await container.read(
          explorerTagCrossRefsProvider('tag-gone').future,
        )).isEmpty,
        isTrue,
      );
      expect(
        await container.read(
          explorerTagCommentariesProvider('tag-gone').future,
        ),
        isEmpty,
      );
      expect(
        await container.read(
          explorerTagCrossReferencesProvider('tag-gone').future,
        ),
        isEmpty,
      );
    });
  });

  group('passage tags', () {
    test('groups a chapter\'s tags with their verse numbers, skipping '
        'deleted tags and links', () async {
      final tags = await firstData(
        explorerPassageTagsProvider((book: '1 Samuel', chapter: 24)),
      );
      // Both tags sit on verse 1 (david's verse-2 link is deleted, the
      // 'gone' tag is deleted), so they tie on verse and sort by name.
      expect(tags.map((t) => t.tag.name).toList(), ['caves', 'david']);
      expect(tags.first.verses, [1]);
      expect(tags.last.verses, [1]);
    });

    test('untagged chapter is empty', () async {
      final tags = await firstData(
        explorerPassageTagsProvider((book: 'Obadiah', chapter: 1)),
      );
      expect(tags, isEmpty);
    });
  });

  group('entity tags', () {
    test('person: intersects tagged verses with the person\'s verses, most '
        'shared first', () async {
      // David appears in 1 Sam 24:1-2 and Ps 57:1; 'david' tags two of
      // those verses, 'caves' one.
      final tags = await firstData(explorerPersonTagsProvider(1));
      expect(tags.map((t) => t.tag.name).toList(), ['david', 'caves']);
      expect(tags.first.refs, [
        (book: '1 Samuel', chapter: 24, verse: 1),
        (book: 'Psalms', chapter: 57, verse: 1),
      ]);
      expect(tags.last.refs, [(book: '1 Samuel', chapter: 24, verse: 1)]);
    });

    test('person with no tagged verses has no tags', () async {
      // Saul's only verse (24:2) carries just the deleted link.
      expect(await firstData(explorerPersonTagsProvider(2)), isEmpty);
    });

    test('place and event intersect through their own verse lists', () async {
      // En Gedi's verse (24:1) carries both tags — ties sort by name.
      final placeTags = await firstData(explorerPlaceTagsProvider(1));
      expect(placeTags.map((t) => t.tag.name).toList(), ['caves', 'david']);

      // The event's account is 24:1-2; only 24:1 is live-tagged.
      final eventTags = await firstData(explorerEventTagsProvider(1));
      expect(eventTags.map((t) => t.tag.name).toList(), ['caves', 'david']);
      expect(eventTags.first.refs, [(book: '1 Samuel', chapter: 24, verse: 1)]);
    });
  });
}
