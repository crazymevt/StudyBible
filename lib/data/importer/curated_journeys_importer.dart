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

  /// Idempotent per waypoint (not just on the first call): each waypoint is
  /// only inserted if no `timeline_events` row with its exact title exists
  /// yet, so adding new entries to curated_journeys_data.dart is picked up on
  /// a persistent on-device database that already ran an earlier version of
  /// this importer — not just on a fresh in-memory one. A single "have we
  /// ever run this importer" sentinel used to gate the whole method instead,
  /// which meant every waypoint added after the first real run silently
  /// never reached any device that had already loaded at least one.
  Future<void> ensureLoaded() async {
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
        final alreadyInserted = await (store.select(store.timelineEvents)
              ..where((e) => e.title.equals(waypoint.title))
              ..limit(1))
            .getSingleOrNull();
        if (alreadyInserted != null) continue;

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
                startYear: Value(waypoint.year.round()),
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
