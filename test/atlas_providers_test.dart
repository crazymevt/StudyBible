import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/app/atlas_providers.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/data/content_store.dart';

/// Exercises the Atlas's journey derivation: a person's dated events become
/// waypoints resolved through the event↔place verse bridge, the first place
/// named in a multi-place account wins, undated/unmapped events are excluded
/// from the path but counted rather than silently dropped, curated
/// no-reliable-place titles are always treated as unmapped, and curated
/// place overrides win over whatever the default heuristic would pick.
void main() {
  late ContentStore store;
  late ProviderContainer container;

  Future<void> place(int id, String name, double lat, double lng) => store
      .into(store.places)
      .insert(
        PlacesCompanion(
          id: Value(id),
          name: Value(name),
          lat: Value(lat),
          lng: Value(lng),
        ),
      );

  Future<void> placeVerse(
    int id,
    int placeId,
    String book,
    int chapter,
    int verse,
  ) => store
      .into(store.placeVerses)
      .insert(
        PlaceVersesCompanion(
          id: Value(id),
          placeId: Value(placeId),
          bookName: Value(book),
          chapter: Value(chapter),
          verse: Value(verse),
        ),
      );

  Future<void> person(int id, String name) => store
      .into(store.biblePeople)
      .insert(
        BiblePeopleCompanion(
          id: Value(id),
          slug: Value(name.toLowerCase()),
          name: Value(name),
          displayTitle: Value(name),
          verseCount: const Value(0),
        ),
      );

  Future<void> event(int id, String title, {double? sortKey, int? startYear}) =>
      store
          .into(store.timelineEvents)
          .insert(
            TimelineEventsCompanion(
              id: Value(id),
              title: Value(title),
              sortKey: Value(sortKey),
              startYear: Value(startYear),
            ),
          );

  Future<void> eventVerse(
    int id,
    int eventId,
    int ord,
    String book,
    int chapter,
    int verse,
  ) => store
      .into(store.eventVerses)
      .insert(
        EventVersesCompanion(
          id: Value(id),
          eventId: Value(eventId),
          ord: Value(ord),
          bookName: Value(book),
          chapter: Value(chapter),
          verse: Value(verse),
        ),
      );

  Future<void> participant(int id, int eventId, int personId) => store
      .into(store.eventParticipants)
      .insert(
        EventParticipantsCompanion(
          id: Value(id),
          eventId: Value(eventId),
          personId: Value(personId),
        ),
      );

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());

    await person(1, 'Paul');
    await person(2, 'Barnabas'); // no events at all

    await place(1, 'Damascus', 33.5, 36.3);
    await place(2, 'Antioch', 36.2, 36.15);
    await place(3, 'Iconium', 37.85, 32.48);

    // Event 1: resolves to a single place (Damascus).
    await event(
      1,
      'Conversion on the road to Damascus',
      sortKey: 35.0,
      startYear: 35,
    );
    await eventVerse(1, 1, 0, 'Acts', 9, 3);
    await placeVerse(1, 1, 'Acts', 9, 3);

    // Event 2: account mentions two places — Antioch (ord 0) then Iconium
    // (ord 1). The ord-0 place should win as the waypoint.
    await event(
      2,
      'Sent out from Antioch, passing through Iconium',
      sortKey: 46.0,
      startYear: 46,
    );
    await eventVerse(2, 2, 0, 'Acts', 13, 14);
    await eventVerse(3, 2, 1, 'Acts', 13, 51);
    await placeVerse(2, 2, 'Acts', 13, 14);
    await placeVerse(3, 3, 'Acts', 13, 51);

    // Event 3: dated, but its verse isn't geocoded to any place.
    await event(3, 'An unmapped dated event', sortKey: 50.0, startYear: 50);
    await eventVerse(4, 3, 0, 'Acts', 20, 1);

    // Event 4: no start year at all.
    await event(4, 'An undated event', sortKey: 1.0);

    // Event 5: matches the curated no-reliable-place exclusion by title —
    // every place its account names (Nineveh, the Queen of the South,
    // Jerusalem) is a rhetorical aside, not the event's setting, so it
    // should fall through to unmapped rather than plotting any of them.
    await place(4, 'Nineveh', 36.36, 43.15);
    await event(
      5,
      'Blind and Dumb Demoniac and Following Discourse',
      sortKey: 28.0,
      startYear: 28,
    );
    await eventVerse(5, 5, 0, 'Matthew', 12, 41);
    await placeVerse(4, 4, 'Matthew', 12, 41);

    // Event 6: matches a curated place override by title — Syria (ord 0, the
    // governor mentioned in the census) would normally win, but the account's
    // real setting, Bethlehem (ord 1), is the curated override for this
    // title so it should win instead.
    await place(5, 'Syria', 34.8, 38.9);
    await place(6, 'Bethlehem 1', 31.7, 35.2);
    await event(6, 'Birth of Jesus', sortKey: -3.0, startYear: -3);
    await eventVerse(6, 6, 0, 'Luke', 2, 2);
    await eventVerse(7, 6, 1, 'Luke', 2, 4);
    await placeVerse(5, 5, 'Luke', 2, 2);
    await placeVerse(6, 6, 'Luke', 2, 4);

    // Event 7: a second override case — Jerusalem (ord 0) is a retrospective
    // mention ("made havoc in Jerusalem"), not where this account is set;
    // the curated override picks Capernaum (ord 1, an existing place) instead.
    await place(7, 'Jerusalem', 31.78, 35.22);
    await place(9, 'Capernaum', 32.88, 35.57);
    await event(7, 'Bread of Life Sermon', sortKey: 38.0, startYear: 38);
    await eventVerse(8, 7, 0, 'John', 6, 1);
    await eventVerse(9, 7, 1, 'John', 6, 24);
    await placeVerse(7, 7, 'John', 6, 1);
    await placeVerse(8, 9, 'John', 6, 24); // Capernaum (place 9)

    // Event 8: a second no-reliable-place exclusion — its only place mention
    // (Thyatira) is a person's hometown, not the event's setting, and no
    // correct place is linked to this event at all, so it should fall
    // through to unmapped rather than plotting Thyatira.
    await place(8, 'Thyatira', 38.9, 27.8);
    await event(8, "Sermon on the Mount", sortKey: 47.5, startYear: 47);
    await eventVerse(10, 8, 0, 'Acts', 16, 14);
    await placeVerse(9, 8, 'Acts', 16, 14);

    for (final eventId in [1, 2, 3, 4, 5, 6, 7, 8]) {
      await participant(eventId, eventId, 1);
    }

    container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        peopleReadyProvider.overrideWith((ref) async => true),
        placesReadyProvider.overrideWith((ref) async => true),
        topicalIndexReadyProvider.overrideWith((ref) async => true),
        // This suite's synthetic DB has no Elijah/Elisha rows for the real
        // curated importer to find — it's exercised for real in
        // curated_journeys_importer_test.dart instead.
        curatedJourneysReadyProvider.overrideWith((ref) async => true),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  test(
    'waypoints follow chronological order and the first-mentioned place',
    () async {
      final journey = await container.read(personJourneyProvider(1).future);
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Bethlehem 1',
        'Damascus',
        'Capernaum',
        'Antioch',
      ]);
      expect(journey.waypoints[3].eventId, 2);
    },
  );

  test(
    'a curated place override wins over the earlier-mentioned place',
    () async {
      final journey = await container.read(personJourneyProvider(1).future);
      final birth = journey!.waypoints.firstWhere((w) => w.eventId == 6);
      expect(birth.placeName, 'Bethlehem 1');
      expect(
        journey.waypoints.map((w) => w.placeName),
        isNot(contains('Syria')),
      );
    },
  );

  test(
    'a second curated override wins over an earlier retrospective mention',
    () async {
      final journey = await container.read(personJourneyProvider(1).future);
      final proclaims = journey!.waypoints.firstWhere((w) => w.eventId == 7);
      expect(proclaims.placeName, 'Capernaum');
    },
  );

  test(
    'dated-but-unmapped and undated events are counted, not silent',
    () async {
      final journey = await container.read(personJourneyProvider(1).future);
      expect(journey!.unmappedEventCount, 3);
      expect(journey.undatedEventCount, 1);
    },
  );

  test(
    'an event on the no-reliable-place list is treated as unmapped',
    () async {
      final journey = await container.read(personJourneyProvider(1).future);
      expect(
        journey!.waypoints.map((w) => w.placeName),
        isNot(contains('Nineveh')),
      );
      expect(journey.waypoints.map((w) => w.eventId), isNot(contains(5)));
    },
  );

  test('a second no-reliable-place event (no correct candidate in its own '
      'verses) is treated as unmapped', () async {
    final journey = await container.read(personJourneyProvider(1).future);
    expect(
      journey!.waypoints.map((w) => w.placeName),
      isNot(contains('Thyatira')),
    );
    expect(journey.waypoints.map((w) => w.eventId), isNot(contains(8)));
  });

  test('a person with no events resolves to an empty journey', () async {
    final journey = await container.read(personJourneyProvider(2).future);
    expect(journey, isNotNull);
    expect(journey!.waypoints, isEmpty);
    expect(journey.unmappedEventCount, 0);
    expect(journey.undatedEventCount, 0);
  });

  test('an unknown person id resolves to null', () async {
    final journey = await container.read(personJourneyProvider(999).future);
    expect(journey, isNull);
  });

  test('allPlacesProvider returns every place, name-ordered', () async {
    final places = await container.read(allPlacesProvider.future);
    expect(places.map((p) => p.name), [
      'Antioch',
      'Bethlehem 1',
      'Capernaum',
      'Damascus',
      'Iconium',
      'Jerusalem',
      'Nineveh',
      'Syria',
      'Thyatira',
    ]);
  });
}
