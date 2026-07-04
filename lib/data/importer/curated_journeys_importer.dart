import 'package:drift/drift.dart';
import '../content_store.dart';
import 'curated_journeys_data.dart';

/// Inserts the hand-curated waypoints from `curated_journeys_data.dart` into
/// the same `timeline_events` / `event_participants` / `event_verses` tables
/// the Theographic import already populates — [PersonJourney] doesn't care
/// where its rows came from, so no new query logic is needed, just more data.
///
/// Runs after [TheographicImporter] and `PlacesImporter` (both referenced by
/// slug/name here, not by hardcoded id), and relies on the same trick both of
/// those use: inserted rows omit an explicit `id`, so SQLite's
/// AUTOINCREMENT continues past whatever ids they already used.
class CuratedJourneysImporter {
  CuratedJourneysImporter(this.store);

  final ContentStore store;

  Future<bool> _alreadyLoaded() async {
    if (curatedPersonJourneys.isEmpty) return true;
    final sentinelTitle = curatedPersonJourneys.first.waypoints.first.title;
    final row = await (store.select(store.timelineEvents)
          ..where((e) => e.title.equals(sentinelTitle))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Idempotent: inserts each curated journey's waypoints once, then no-ops
  /// on later calls.
  Future<void> ensureLoaded() async {
    if (await _alreadyLoaded()) return;

    for (final journey in curatedPersonJourneys) {
      final person = await (store.select(store.biblePeople)
            ..where((p) => p.slug.equals(journey.personSlug)))
          .getSingleOrNull();
      if (person == null) {
        throw StateError(
            'CuratedJourneysImporter: no bible_people row with slug '
            '"${journey.personSlug}" — check curated_journeys_data.dart');
      }

      for (final waypoint in journey.waypoints) {
        final place = await (store.select(store.places)
              ..where((pl) => pl.name.equals(waypoint.placeName)))
            .getSingleOrNull();
        if (place == null) {
          throw StateError(
              'CuratedJourneysImporter: no places row named '
              '"${waypoint.placeName}" (waypoint "${waypoint.title}")');
        }

        final eventId = await store.into(store.timelineEvents).insert(
              TimelineEventsCompanion.insert(
                title: waypoint.title,
                sortKey: Value(waypoint.year.toDouble()),
                startYear: Value(waypoint.year),
              ),
            );
        await store.into(store.eventParticipants).insert(
              EventParticipantsCompanion.insert(
                eventId: eventId,
                personId: person.id,
              ),
            );
        await store.into(store.eventVerses).insert(
              EventVersesCompanion.insert(
                eventId: eventId,
                ord: 0,
                bookName: waypoint.bookName,
                chapter: waypoint.chapter,
                verse: waypoint.verse,
              ),
            );

        // Backfill the place↔verse link if the bundled gazetteer doesn't
        // already have it (e.g. Abel-meholah isn't linked to 1 Kings 19:19,
        // only to 19:16, which merely names it as Elisha's hometown).
        final linkExists = await (store.select(store.placeVerses)
              ..where((pv) =>
                  pv.placeId.equals(place.id) &
                  pv.bookName.equals(waypoint.bookName) &
                  pv.chapter.equals(waypoint.chapter) &
                  pv.verse.equals(waypoint.verse))
              ..limit(1))
            .getSingleOrNull();
        if (linkExists == null) {
          await store.into(store.placeVerses).insert(
                PlaceVersesCompanion.insert(
                  placeId: place.id,
                  bookName: waypoint.bookName,
                  chapter: waypoint.chapter,
                  verse: waypoint.verse,
                ),
              );
        }
      }
    }
  }
}
