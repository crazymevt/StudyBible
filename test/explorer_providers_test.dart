import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';

/// Exercises the Explorer's cross-dataset joins: events↔places and
/// people↔places are linked through shared verses, the passage overview
/// aggregates every dataset for one chapter, and the trail notifier drives
/// breadcrumb navigation.
void main() {
  late ContentStore store;
  late ProviderContainer container;

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());

    // People: David (3 verses), Saul (1 verse).
    Future<void> person(int id, String name, int verseCount) =>
        store.into(store.biblePeople).insert(BiblePeopleCompanion(
              id: Value(id),
              slug: Value(name.toLowerCase()),
              name: Value(name),
              displayTitle: Value(name),
              verseCount: Value(verseCount),
            ));
    await person(1, 'David', 3);
    await person(2, 'Saul', 1);

    Future<void> personVerse(int id, int p, String book, int ch, int v) =>
        store.into(store.personVerses).insert(PersonVersesCompanion(
              id: Value(id),
              personId: Value(p),
              bookName: Value(book),
              chapter: Value(ch),
              verse: Value(v),
            ));
    await personVerse(1, 1, '1 Samuel', 24, 1);
    await personVerse(2, 1, '1 Samuel', 24, 2);
    await personVerse(3, 1, 'Psalms', 57, 1);
    await personVerse(4, 2, '1 Samuel', 24, 2);

    // Places: En Gedi is in 1 Samuel 24, Ziph is not.
    Future<void> place(int id, String name) =>
        store.into(store.places).insert(PlacesCompanion(
              id: Value(id),
              name: Value(name),
              lat: const Value(31.46),
              lng: const Value(35.38),
            ));
    await place(1, 'En Gedi');
    await place(2, 'Ziph');

    Future<void> placeVerse(int id, int p, String book, int ch, int v) =>
        store.into(store.placeVerses).insert(PlaceVersesCompanion(
              id: Value(id),
              placeId: Value(p),
              bookName: Value(book),
              chapter: Value(ch),
              verse: Value(v),
            ));
    await placeVerse(1, 1, '1 Samuel', 24, 1);
    await placeVerse(2, 2, '1 Samuel', 23, 14);

    // Events: one in 1 Samuel 24 (both people participate), one elsewhere.
    Future<void> event(int id, String title, double sortKey, int year) =>
        store.into(store.timelineEvents).insert(TimelineEventsCompanion(
              id: Value(id),
              title: Value(title),
              sortKey: Value(sortKey),
              startYear: Value(year),
            ));
    await event(1, 'David spares Saul', 1.0, -1060);
    await event(2, 'Creation', 0.0, -4003);

    Future<void> participant(int id, int e, int p) =>
        store.into(store.eventParticipants).insert(EventParticipantsCompanion(
              id: Value(id),
              eventId: Value(e),
              personId: Value(p),
            ));
    await participant(1, 1, 2); // Saul inserted first on purpose:
    await participant(2, 1, 1); // participants sort by verse count, not id.

    Future<void> eventVerse(int id, int e, int ord, String book, int ch, int v) =>
        store.into(store.eventVerses).insert(EventVersesCompanion(
              id: Value(id),
              eventId: Value(e),
              ord: Value(ord),
              bookName: Value(book),
              chapter: Value(ch),
              verse: Value(v),
            ));
    await eventVerse(1, 1, 0, '1 Samuel', 24, 1);
    await eventVerse(2, 1, 1, '1 Samuel', 24, 2);
    await eventVerse(3, 2, 0, 'Genesis', 1, 1);

    // Topics: one referencing 1 Samuel 24.
    await store.into(store.topics).insert(const TopicsCompanion(
        id: Value(1), name: Value('CAVES'), section: Value('C')));
    await store.into(store.topicEntries).insert(const TopicEntriesCompanion(
        id: Value(1),
        topicId: Value(1),
        ordinal: Value(0),
        description: Value('As refuges')));
    await store.into(store.topicReferences).insert(const TopicReferencesCompanion(
        id: Value(1),
        topicId: Value(1),
        entryId: Value(1),
        bookName: Value('1 Samuel'),
        chapter: Value(24),
        verse: Value(3)));

    // Commentaries: Henry has entries in 1 Samuel 24, Scofield doesn't.
    await store.into(store.commentaries).insert(const CommentariesCompanion(
        id: Value(1), abbreviation: Value('MHC'), name: Value('Matthew Henry')));
    await store.into(store.commentaries).insert(const CommentariesCompanion(
        id: Value(2), abbreviation: Value('SCO'), name: Value('Scofield')));
    Future<void> commentaryEntry(
            int id, int commentary, String book, int ch, int v, String text) =>
        store.into(store.commentaryEntries).insert(CommentaryEntriesCompanion(
              id: Value(id),
              commentaryId: Value(commentary),
              bookName: Value(book),
              chapter: Value(ch),
              verse: Value(v),
              textContent: Value(text),
            ));
    await commentaryEntry(1, 1, '1 Samuel', 24, 2, 'On verse two');
    await commentaryEntry(2, 1, '1 Samuel', 24, 1, 'On verse one');
    await commentaryEntry(3, 2, 'Genesis', 1, 1, 'Elsewhere');

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(overrides: [
      contentStoreProvider.overrideWithValue(store),
      sharedPreferencesProvider.overrideWithValue(prefs),
      peopleReadyProvider.overrideWith((ref) async => true),
      placesReadyProvider.overrideWith((ref) async => true),
      topicalIndexReadyProvider.overrideWith((ref) async => true),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

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
    test('joins participants, ordered verses, and places via shared verses',
        () async {
      final d = await container.read(explorerEventDetailProvider(1).future);
      expect(d, isNotNull);
      // Most-mentioned participant first, regardless of insert order.
      expect(d!.participants.map((p) => p.name).toList(), ['David', 'Saul']);
      expect(d.verses.map((v) => v.verse).toList(), [1, 2]);
      // En Gedi shares 1 Samuel 24:1 with the event; Ziph doesn't.
      expect(d.places.map((p) => p.name).toList(), ['En Gedi']);
    });

    test('unknown event resolves to null', () async {
      expect(await container.read(explorerEventDetailProvider(99).future),
          isNull);
    });
  });

  group('place detail', () {
    test('reverse-joins events and people through the place\'s verses',
        () async {
      final d = await container.read(explorerPlaceDetailProvider(1).future);
      expect(d, isNotNull);
      expect(d!.verses.length, 1);
      expect(d.events.map((e) => e.title).toList(), ['David spares Saul']);
      // Only David is tagged in 1 Samuel 24:1 (Saul appears in v2).
      expect(d.people.map((p) => p.name).toList(), ['David']);
    });
  });

  group('person places', () {
    test('finds places co-mentioned in the person\'s verses', () async {
      final places =
          await container.read(explorerPersonPlacesProvider(1).future);
      expect(places.map((p) => p.name).toList(), ['En Gedi']);
    });

    test('no shared verses means no places', () async {
      final places =
          await container.read(explorerPersonPlacesProvider(2).future);
      expect(places, isEmpty);
    });
  });

  group('passage overview', () {
    test('aggregates people, places, events, and topics for a chapter',
        () async {
      final d = await container.read(
          explorerPassageOverviewProvider((book: '1 Samuel', chapter: 24))
              .future);
      expect(d.people.map((p) => p.displayTitle).toList(), ['David', 'Saul']);
      expect(d.places.map((p) => p.name).toList(), ['En Gedi']);
      expect(d.events.map((e) => e.title).toList(), ['David spares Saul']);
      expect(d.topics.map((t) => t.name).toList(), ['CAVES']);
    });

    test('untagged chapter is empty', () async {
      final d = await container.read(
          explorerPassageOverviewProvider((book: 'Obadiah', chapter: 1))
              .future);
      expect(d.isEmpty, isTrue);
    });
  });

  group('passage commentaries', () {
    test('groups chapter entries by module, verse-ordered, skipping modules '
        'with nothing for the chapter', () async {
      final sections = await container.read(
          explorerPassageCommentariesProvider((book: '1 Samuel', chapter: 24))
              .future);
      expect(sections.length, 1);
      expect(sections.single.commentary.name, 'Matthew Henry');
      expect(sections.single.entries.map((e) => e.verse).toList(), [1, 2]);
    });

    test('chapter without entries returns empty', () async {
      final sections = await container.read(
          explorerPassageCommentariesProvider((book: 'Obadiah', chapter: 1))
              .future);
      expect(sections, isEmpty);
    });
  });

  group('universal search', () {
    Future<ExplorerSearchResults> search(String q) {
      container.read(explorerSearchQueryProvider.notifier).setQuery(q);
      return container.read(explorerSearchResultsProvider.future);
    }

    test('finds each entity kind by name', () async {
      final people = await search('David');
      expect(people.people.map((i) => i.ref.label), contains('David'));
      // "David spares Saul" also matches the event search.
      expect(people.events.map((i) => i.ref.label),
          contains('David spares Saul'));

      final places = await search('En Gedi');
      expect(places.places.single.ref.label, 'En Gedi');
      expect(places.places.single.ref.type, ExplorerEntityType.place);

      final topics = await search('cave');
      expect(topics.topics.single.ref.label, 'CAVES');
    });

    test('short queries return nothing', () async {
      expect((await search('d')).isEmpty, isTrue);
    });
  });
}
