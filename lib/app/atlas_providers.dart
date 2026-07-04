import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content_store.dart';
import 'content_providers.dart';
import 'explorer_providers.dart';
import 'place_providers.dart';

/// All bundled places, name-ordered — the Atlas's general browse mode.
final allPlacesProvider = FutureProvider<List<Place>>((ref) async {
  await ref.watch(placesReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  return (store.select(store.places)
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .get();
});

/// One stop on a person's auto-derived journey: a dated event they took part
/// in, resolved to the first place named in its account.
class JourneyWaypoint {
  final int eventId;
  final String title;
  final int startYear;
  final int placeId;
  final String placeName;
  final double lat;
  final double lng;

  /// The event's first verse, for "Read passage".
  final String? bookName;
  final int? chapter;
  final int? verse;

  JourneyWaypoint({
    required this.eventId,
    required this.title,
    required this.startYear,
    required this.placeId,
    required this.placeName,
    required this.lat,
    required this.lng,
    this.bookName,
    this.chapter,
    this.verse,
  });
}

/// A person's movements over time, auto-derived from their dated events (no
/// curated journey data exists in the bundled datasets). Events are excluded
/// from the path — but counted, not silently dropped — when they have no
/// [startYear] ([undatedEventCount]) or resolve to no mappable place
/// ([unmappedEventCount]).
class PersonJourney {
  final int personId;
  final String displayTitle;
  final List<JourneyWaypoint> waypoints;
  final int unmappedEventCount;
  final int undatedEventCount;

  PersonJourney({
    required this.personId,
    required this.displayTitle,
    required this.waypoints,
    required this.unmappedEventCount,
    required this.undatedEventCount,
  });
}

/// Events whose account only names places rhetorically (a comparison, a
/// prophecy, a historical aside) rather than describing where the event
/// itself took place, so no verse in the account is a reliable waypoint.
/// `place_verses` links a place to every verse that names it, with no
/// distinction between "this is the scene" and "this is being cited as an
/// example" — for these events every match the heuristic below finds is the
/// latter, so the event is left unmapped (already a counted, handled state)
/// rather than risk plotting a stop at whichever aside sorts first.
///
/// - 'Blind and Dumb Demoniac and Following Discourse': the Beelzebul
///   controversy / sign-of-Jonah teaching (Matthew 12:22-50, Mark 3:19-30,
///   Luke 8:19-21, Luke 11:14-36). Jesus never leaves Galilee here, but the
///   account cites Nineveh and the Queen of the South (Matthew 12:41-42,
///   Luke 11:30-32) as examples of repentance/wisdom, and notes scribes who
///   "came down from Jerusalem" (Mark 3:22) — three unrelated places, none of
///   them the event's setting.
const _eventsWithNoReliablePlace = {
  'Blind and Dumb Demoniac and Following Discourse',
};

/// A person's dated events, each resolved to the first place named in its
/// account (lowest `event_verses.ord`, tie-broken by lowest place id) — the
/// same verse-coordinate bridge [explorerEventDetailProvider] uses to
/// cross-reference events and places, extended to pick a single deterministic
/// waypoint per event instead of every place an account happens to mention.
final personJourneyProvider =
    FutureProvider.family<PersonJourney?, int>((ref, personId) async {
  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);

  final person = await (store.select(store.biblePeople)
        ..where((p) => p.id.equals(personId)))
      .getSingleOrNull();
  if (person == null) return null;

  final eventRows = await store.customSelect(
    'SELECT e.id AS event_id, e.title AS title, e.start_year AS start_year, '
    '       ev0.book_name AS book_name, ev0.chapter AS chapter, ev0.verse AS verse '
    'FROM event_participants ep '
    'JOIN timeline_events e ON e.id = ep.event_id '
    'LEFT JOIN event_verses ev0 ON ev0.event_id = e.id AND ev0.ord = 0 '
    'WHERE ep.person_id = ? '
    'ORDER BY e.sort_key IS NULL, e.sort_key, e.id',
    variables: [Variable.withInt(personId)],
  ).get();

  if (eventRows.isEmpty) {
    return PersonJourney(
      personId: personId,
      displayTitle: person.displayTitle,
      waypoints: const [],
      unmappedEventCount: 0,
      undatedEventCount: 0,
    );
  }

  final datedEventIds = [
    for (final r in eventRows)
      if (r.readNullable<int>('start_year') != null &&
          !_eventsWithNoReliablePlace.contains(r.read<String>('title')))
        r.read<int>('event_id'),
  ];

  // Batch-resolve places for every dated event in one query, extending the
  // event↔place verse-coordinate bridge with `ev.ord` so the place tied to
  // the account's earliest verse — the scene-setter — sorts first per event.
  final placesByEvent = <int, ({int placeId, String placeName, double lat, double lng})>{};
  if (datedEventIds.isNotEmpty) {
    final placeholders = List.filled(datedEventIds.length, '?').join(',');
    final placeRows = await store.customSelect(
      'SELECT ev.event_id AS event_id, ev.ord AS ord, '
      '       p.id AS place_id, p.name AS place_name, p.lat AS lat, p.lng AS lng '
      'FROM event_verses ev '
      'JOIN place_verses pv ON pv.book_name = ev.book_name '
      '  AND pv.chapter = ev.chapter AND pv.verse = ev.verse '
      'JOIN places p ON p.id = pv.place_id '
      'WHERE ev.event_id IN ($placeholders) '
      'ORDER BY ev.event_id, ev.ord, p.id',
      variables: [for (final id in datedEventIds) Variable.withInt(id)],
    ).get();
    for (final r in placeRows) {
      final eventId = r.read<int>('event_id');
      // First row per event_id wins (already ordered by ord, place.id).
      placesByEvent.putIfAbsent(
        eventId,
        () => (
          placeId: r.read<int>('place_id'),
          placeName: r.read<String>('place_name'),
          lat: r.read<double>('lat'),
          lng: r.read<double>('lng'),
        ),
      );
    }
  }

  final waypoints = <JourneyWaypoint>[];
  var unmapped = 0;
  var undated = 0;
  for (final r in eventRows) {
    final startYear = r.readNullable<int>('start_year');
    if (startYear == null) {
      undated++;
      continue;
    }
    final place = placesByEvent[r.read<int>('event_id')];
    if (place == null) {
      unmapped++;
      continue;
    }
    waypoints.add(JourneyWaypoint(
      eventId: r.read<int>('event_id'),
      title: r.read<String>('title'),
      startYear: startYear,
      placeId: place.placeId,
      placeName: place.placeName,
      lat: place.lat,
      lng: place.lng,
      bookName: r.readNullable<String>('book_name'),
      chapter: r.readNullable<int>('chapter'),
      verse: r.readNullable<int>('verse'),
    ));
  }

  return PersonJourney(
    personId: personId,
    displayTitle: person.displayTitle,
    waypoints: waypoints,
    unmappedEventCount: unmapped,
    undatedEventCount: undated,
  );
});
