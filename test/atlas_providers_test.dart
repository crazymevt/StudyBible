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
/// named in a multi-place account wins, and undated/unmapped events are
/// excluded from the path but counted rather than silently dropped.
void main() {
  late ContentStore store;
  late ProviderContainer container;

  Future<void> place(int id, String name, double lat, double lng) =>
      store.into(store.places).insert(PlacesCompanion(
            id: Value(id),
            name: Value(name),
            lat: Value(lat),
            lng: Value(lng),
          ));

  Future<void> placeVerse(
          int id, int placeId, String book, int chapter, int verse) =>
      store.into(store.placeVerses).insert(PlaceVersesCompanion(
            id: Value(id),
            placeId: Value(placeId),
            bookName: Value(book),
            chapter: Value(chapter),
            verse: Value(verse),
          ));

  Future<void> person(int id, String name) =>
      store.into(store.biblePeople).insert(BiblePeopleCompanion(
            id: Value(id),
            slug: Value(name.toLowerCase()),
            name: Value(name),
            displayTitle: Value(name),
            verseCount: const Value(0),
          ));

  Future<void> event(int id, String title,
          {double? sortKey, int? startYear}) =>
      store.into(store.timelineEvents).insert(TimelineEventsCompanion(
            id: Value(id),
            title: Value(title),
            sortKey: Value(sortKey),
            startYear: Value(startYear),
          ));

  Future<void> eventVerse(
          int id, int eventId, int ord, String book, int chapter, int verse) =>
      store.into(store.eventVerses).insert(EventVersesCompanion(
            id: Value(id),
            eventId: Value(eventId),
            ord: Value(ord),
            bookName: Value(book),
            chapter: Value(chapter),
            verse: Value(verse),
          ));

  Future<void> participant(int id, int eventId, int personId) => store
      .into(store.eventParticipants)
      .insert(EventParticipantsCompanion(
        id: Value(id),
        eventId: Value(eventId),
        personId: Value(personId),
      ));

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());

    await person(1, 'Paul');
    await person(2, 'Barnabas'); // no events at all

    await place(1, 'Damascus', 33.5, 36.3);
    await place(2, 'Antioch', 36.2, 36.15);
    await place(3, 'Iconium', 37.85, 32.48);

    // Event 1: resolves to a single place (Damascus).
    await event(1, 'Conversion on the road to Damascus',
        sortKey: 35.0, startYear: 35);
    await eventVerse(1, 1, 0, 'Acts', 9, 3);
    await placeVerse(1, 1, 'Acts', 9, 3);

    // Event 2: account mentions two places — Antioch (ord 0) then Iconium
    // (ord 1). The ord-0 place should win as the waypoint.
    await event(2, 'Sent out from Antioch, passing through Iconium',
        sortKey: 46.0, startYear: 46);
    await eventVerse(2, 2, 0, 'Acts', 13, 14);
    await eventVerse(3, 2, 1, 'Acts', 13, 51);
    await placeVerse(2, 2, 'Acts', 13, 14);
    await placeVerse(3, 3, 'Acts', 13, 51);

    // Event 3: dated, but its verse isn't geocoded to any place.
    await event(3, 'An unmapped dated event', sortKey: 50.0, startYear: 50);
    await eventVerse(4, 3, 0, 'Acts', 20, 1);

    // Event 4: no start year at all.
    await event(4, 'An undated event', sortKey: 1.0);

    for (final eventId in [1, 2, 3, 4]) {
      await participant(eventId, eventId, 1);
    }

    container = ProviderContainer(overrides: [
      contentStoreProvider.overrideWithValue(store),
      peopleReadyProvider.overrideWith((ref) async => true),
      placesReadyProvider.overrideWith((ref) async => true),
      topicalIndexReadyProvider.overrideWith((ref) async => true),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  test('waypoints follow chronological order and the first-mentioned place',
      () async {
    final journey =
        await container.read(personJourneyProvider(1).future);
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName),
        ['Damascus', 'Antioch']);
    expect(journey.waypoints[1].eventId, 2);
  });

  test('dated-but-unmapped and undated events are counted, not silent',
      () async {
    final journey =
        await container.read(personJourneyProvider(1).future);
    expect(journey!.unmappedEventCount, 1);
    expect(journey.undatedEventCount, 1);
  });

  test('a person with no events resolves to an empty journey', () async {
    final journey =
        await container.read(personJourneyProvider(2).future);
    expect(journey, isNotNull);
    expect(journey!.waypoints, isEmpty);
    expect(journey.unmappedEventCount, 0);
    expect(journey.undatedEventCount, 0);
  });

  test('an unknown person id resolves to null', () async {
    final journey =
        await container.read(personJourneyProvider(999).future);
    expect(journey, isNull);
  });

  test('allPlacesProvider returns every place, name-ordered', () async {
    final places = await container.read(allPlacesProvider.future);
    expect(places.map((p) => p.name), ['Antioch', 'Damascus', 'Iconium']);
  });
}
