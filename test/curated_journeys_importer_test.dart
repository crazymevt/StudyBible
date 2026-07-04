import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/app/atlas_providers.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/curated_journeys_data.dart';
import 'package:study_bible/data/importer/curated_journeys_importer.dart';

/// Runs the real curated importer against the real bundled people/places
/// data, then exercises the real [personJourneyProvider] end to end — the
/// exact path the Atlas takes for a hand-curated journey, not a synthetic
/// stand-in for it (see atlas_providers_test.dart for that).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentStore store;
  late ProviderContainer container;

  setUp(() {
    store = ContentStore(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      contentStoreProvider.overrideWithValue(store),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  test('inserts every curated waypoint exactly once, idempotently', () async {
    final importer = CuratedJourneysImporter(store);
    // Depends on people/places already being loaded, same as production.
    await container.read(curatedJourneysReadyProvider.future);

    final totalWaypoints =
        curatedPersonJourneys.fold<int>(0, (sum, j) => sum + j.waypoints.length);
    final events = await store.select(store.timelineEvents).get();
    final curatedTitles = {
      for (final j in curatedPersonJourneys)
        for (final w in j.waypoints) w.title,
    };
    final curatedEvents =
        events.where((e) => curatedTitles.contains(e.title)).toList();
    expect(curatedEvents.length, totalWaypoints);

    // Re-running (directly, bypassing the cached provider) must not duplicate.
    await importer.ensureLoaded();
    final recount = await store.select(store.timelineEvents).get();
    expect(recount.length, events.length);
  });

  test("Elijah's journey has all 14 real stops in chronological order",
      () async {
    await container.read(curatedJourneysReadyProvider.future);
    final elijah = await (store.select(store.biblePeople)
          ..where((p) => p.slug.equals('elijah_1131')))
        .getSingle();

    final journey =
        await container.read(personJourneyProvider(elijah.id).future);
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Tishbe',
      'Cherith',
      'Zarephath',
      'Mount Carmel',
      'Jezreel 2',
      'Beersheba 1',
      'Mount Horeb',
      'Abel-meholah',
      'Jezreel 2',
      'Samaria 1',
      'Gilgal 2',
      'Bethel 1',
      'Jericho 1',
      'Jordan',
    ]);
    // The bundled dataset's own "Prophecies of Elijah" (superseded by these
    // curated stops) and "Transfiguation" appearance (excluded — see
    // _eventsWithNoReliablePlace) both count here instead of contributing
    // a waypoint.
    expect(journey.unmappedEventCount, 2);
  });

  test("Elisha's journey has all 10 real stops in chronological order",
      () async {
    await container.read(curatedJourneysReadyProvider.future);
    final elisha = await (store.select(store.biblePeople)
          ..where((p) => p.slug.equals('elisha_1153')))
        .getSingle();

    final journey =
        await container.read(personJourneyProvider(elisha.id).future);
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Jordan',
      'Jericho 1',
      'Bethel 1',
      'Mount Carmel',
      'Samaria 1',
      'Shunem',
      'Gilgal 2',
      'Dothan',
      'Samaria 1',
      'Damascus',
    ]);
    // "Prophecies of Elisha" is superseded by these curated stops.
    expect(journey.unmappedEventCount, 1);
  });

  test('backfills the Abel-meholah / 1 Kings 19:19 place-verse link',
      () async {
    await container.read(curatedJourneysReadyProvider.future);
    final abelMeholah = await (store.select(store.places)
          ..where((p) => p.name.equals('Abel-meholah')))
        .getSingle();
    final link = await (store.select(store.placeVerses)
          ..where((pv) =>
              pv.placeId.equals(abelMeholah.id) &
              pv.bookName.equals('1 Kings') &
              pv.chapter.equals(19) &
              pv.verse.equals(19)))
        .getSingleOrNull();
    expect(link, isNotNull);
  });
}
