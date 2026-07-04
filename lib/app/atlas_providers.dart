import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content_store.dart';
import '../data/importer/curated_journeys_importer.dart';
import 'content_providers.dart';
import 'explorer_providers.dart';
import 'place_providers.dart';

final curatedJourneysImporterProvider = Provider<CuratedJourneysImporter>(
  (ref) => CuratedJourneysImporter(ref.watch(contentStoreProvider)),
);

/// Hand-curated waypoints (see curated_journeys_data.dart) for people whose
/// entire ministry collapses into one dated event in the bundled dataset —
/// too coarse to ever produce a real journey. Layered on top of
/// [explorerReadyProvider] since it needs people and places to already exist
/// (curated waypoints are looked up by slug/name, not hardcoded id).
final curatedJourneysReadyProvider = FutureProvider<bool>((ref) async {
  await ref.watch(explorerReadyProvider.future);
  await ref.watch(curatedJourneysImporterProvider).ensureLoaded();
  return true;
});

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
/// prophecy, a historical aside, a parable's fictional setting) rather than
/// describing where the event itself took place, so no verse in the account
/// is a reliable waypoint. `place_verses` links a place to every verse that
/// names it, with no distinction between "this is the scene" and "this is
/// being cited as an example" — for these events every match the heuristic
/// below finds is the latter, so the event is left unmapped (already a
/// counted, handled state) rather than risk plotting a stop at whichever
/// aside sorts first.
///
/// - 'Blind and Dumb Demoniac and Following Discourse': the Beelzebul
///   controversy / sign-of-Jonah teaching (Matthew 12:22-50, Mark 3:19-30,
///   Luke 8:19-21, Luke 11:14-36). Jesus never leaves Galilee here, but the
///   account cites Nineveh and the Queen of the South (Matthew 12:41-42,
///   Luke 11:30-32) as examples of repentance/wisdom, and notes scribes who
///   "came down from Jerusalem" (Mark 3:22) — three unrelated places, none of
///   them the event's setting.
/// - 'Sermon on the Mount': delivered on an unnamed Galilee hillside, but its
///   only place mention is Matthew 5:35's aside on oaths ("nor by Jerusalem,
///   for it is the city of the great King").
/// - 'The Transfiguation': happened on an unnamed mountain; its only mention
///   is Luke 9:31, Moses and Elijah foretelling the death Jesus would
///   accomplish "at Jerusalem".
/// - '70 Sent Out' and 'Discourse on the Kingdom and Other Parables': each
///   cites Sodom (Luke 10:12; Luke 17:29, the story of Lot) as a rhetorical
///   comparison, not a place visited.
/// - 'Good Samaritan Parable Taught': Jericho (Luke 10:30) is the parable's
///   fictional setting, not where Jesus was standing when he told it.
/// - '3rd Tour of Galilee': its own title says Galilee, but the only place
///   mention is Matthew 10:15's Sodom-and-Gomorrah warning in the
///   mission discourse.
/// - 'Woes and Parables with Pharisees': Luke 13:1 reports news about "the
///   Galileans" Pilate had killed — Jesus himself was travelling toward
///   Jerusalem through Judea at the time, not in Galilee.
/// - 'Commandments and Tradition Discourse': every place mention in the
///   account (Matthew 15:1, Mark 7:1) is scribes/Pharisees who "came from
///   Jerusalem" to Jesus — his own location (Galilee) is never named.
/// - "Lydia's Conversion": its only place mention is Acts 16:14, Lydia's
///   hometown of Thyatira — the conversion itself happened in Philippi
///   (Acts 16:12), which this event's own verse range doesn't extend back to.
const _eventsWithNoReliablePlace = {
  'Blind and Dumb Demoniac and Following Discourse',
  'Sermon on the Mount',
  'The Transfiguation',
  '70 Sent Out',
  'Discourse on the Kingdom and Other Parables',
  'Good Samaritan Parable Taught',
  '3rd Tour of Galilee',
  'Woes and Parables with Pharisees',
  'Commandments and Tradition Discourse',
  "Lydia's Conversion",
};

/// Bundled-dataset events superseded by hand-curated waypoints
/// (curated_journeys_data.dart) for the same person. `theographic.json`
/// collapses each of these people's entire ministry into one dated event —
/// resolving to a real place, just one wildly out of place next to the
/// granular curated stops that now cover the same ground in far more
/// detail. Excluded here so the auto-derived blob doesn't surface as a
/// redundant, oddly-timed extra waypoint alongside them.
const _eventsSupersededByCuratedJourney = {
  'Prophecies of Elijah',
  'Prophecies of Elisha',
  'Reign of Solomon',
  'Reign of David',
  'Prophecies of Isaiah',
  'Prophecies of Jeremiah',
  'Prophecies of Daniel',
};

/// Event → the place name that should win instead of whatever the default
/// "earliest verse, lowest place id" heuristic (below) picks. Each of these
/// accounts already links the event to its true setting via `place_verses`
/// — the heuristic just ranks a different, incidental place first, usually
/// because a verse names both where someone *came from* and where they
/// arrived, and the tie-break (or an earlier throwaway verse) favors the
/// former.
///
/// - 'Birth of Jesus': Luke 2:2 ("governor of Syria") sorts one verse ahead
///   of 2:4, which names Bethlehem as the actual birthplace.
/// - 'John Baptizes Jesus': Matthew 3:13, "Jesus came from Galilee to the
///   Jordan" — same verse, but the baptism happened at the Jordan, not in
///   Galilee.
/// - 'Healing Canaanite Daughter': Matthew 15:21/Mark 7:24 both place this in
///   "the district of Tyre and Sidon"; Galilee (where Jesus came *from*) just
///   has a lower place id.
/// - 'Jesus Teaches in Perea': Matthew 19:1, "went away from Galilee" into
///   Judea beyond the Jordan — the event's own title says Perea.
/// - 'Bread of Life Sermon': John 6:59 explicitly places the sermon "in the
///   synagogue... at Capernaum"; Tiberias is only mentioned in passing
///   (other boats came from there) two verses earlier.
/// - 'Saul proclaims Jesus': Acts 9:21 has the Damascus crowd recalling
///   Saul's past "havoc in Jerusalem" — he's still in Damascus (9:22, where
///   he actually did the proclaiming) when this is said.
/// - 'First Missionary Journey': Acts 12:25, "returned from Jerusalem",
///   describes where Barnabas and Saul had been, not the journey; it
///   launches from Antioch (Acts 13:1).
/// - 'Third Missionary Journey': Acts 18:24 names both Ephesus (where this
///   is set) and Alexandria (Apollos's hometown) in the same verse; Alexandria
///   just has the lower place id.
/// - 'Paul arrested in the Temple': Acts 21:27's "Jews from Asia" describes
///   the accusers' origin — the temple, and the riot, are in Jerusalem
///   (21:31).
/// - 'Paul gives his testimony': Acts 21:39 has Paul naming his own
///   hometown, "Tarsus in Cilicia" — the testimony itself is delivered in
///   Jerusalem (22:17-18).
/// - 'Paul arrives at Rome': Acts 28:11 names the ship's home port,
///   Alexandria; Rome itself, the event's namesake, is named repeatedly
///   right after (28:14-16).
/// - "Paul's First Roman imprisonment": Acts 28:17 has Paul recalling being
///   "delivered as a prisoner from Jerusalem" — he's actually in Rome, named
///   at 28:30 ("He lived there two whole years at his own expense").
/// - 'Abraham goes to Egypt': Genesis 12:10, "there was a famine in the land
///   [Canaan], and Abram went down to Egypt" — same verse names both, but
///   the event's own title says Egypt.
/// - 'Abraham and Lot Separate': Genesis 13:1, "Abram went up from Egypt...
///   into the Negeb" describes where he'd been; the separation itself
///   happens back at Bethel (13:3-4).
/// - 'Wilderness Wanderings': Exodus 13:18 names both Egypt (just left) and
///   the Red Sea (where this account heads); Egypt has the lower place id.
/// - 'Ten Commandments Given': Exodus 19:1 names both Egypt (just left) and
///   the Wilderness of Sinai — where the commandments were actually given.
/// - 'Tabernacle Built': its only mention in the first ~200 (of 300) verses
///   is Exodus 29:46's retrospective "brought them out of the land of
///   Egypt"; Mount Sinai, where the tabernacle was actually built, is named
///   later (31:18).
///
/// The last four are curated waypoints (curated_journeys_data.dart), not
/// auto-derived ones — even a single hand-picked verse can still tie with
/// an incidental place mention already in the bundled gazetteer:
/// - 'Introduced as a prophet to Ahab': 1 Kings 17:1 also names Gilead
///   (Elijah's home region); Tishbe, his actual town, has the higher id.
/// - 'Fed by the widow of Zarephath': 1 Kings 17:9 also names Sidon
///   (Zarephath belonged to it); Sidon has the lower id.
/// - "Intercepts Ahaziah's messengers": 2 Kings 1:3 also names Ekron (the
///   god the messengers were sent to consult) and Tishbe (Elijah's epithet,
///   repeated here); Ekron has the lowest id of the three.
/// - 'Returns to Samaria': 2 Kings 2:25 covers two stops in one summary
///   verse ("...to Mount Carmel, and from there returned to Samaria"); Mount
///   Carmel — this same event's *other* curated waypoint — has the lower id.
/// - "Flees Absalom's rebellion to Mahanaim": 2 Samuel 17:24 also names the
///   Jordan (which David crossed to get there); Jordan has the lower id.
/// - "Returns to Jerusalem after Absalom's defeat": 2 Samuel 19:15 also
///   names Gilgal (where the crossing back over the Jordan happened) and
///   the Jordan itself; Gilgal has the lowest id of the three.
/// - "Smashes the potter's flask in the Valley of Hinnom": Jeremiah 19:2
///   names the Potsherd Gate as the landmark for the direction to travel,
///   not the destination itself ("go forth unto the valley of the son of
///   Hinnom... by the entry of the [Potsherd] gate"); the gate has the
///   lower id.
/// - 'Released from his chains at Ramah': Jeremiah 40:1 names Ramah (where
///   Jeremiah actually was, newly freed), Jerusalem, and Babylon (the
///   captives' origin and destination) in the same verse; both Jerusalem
///   and Babylon have lower ids.
/// - 'Stops at Geruth Chimham, fleeing toward Egypt': Jeremiah 41:17 names
///   Geruth Chimham itself, Bethlehem (just a proximity landmark, "by
///   Bethlehem"), and Egypt (the destination they hadn't reached yet) in
///   the same verse; both have lower ids.
/// - 'Forcibly taken to Tahpanhes in Egypt': Jeremiah 43:7 names Egypt (the
///   country) and Tahpanhes (the specific city they settled in) in the same
///   verse; Egypt has the lower id.
/// - 'Taken captive from Jerusalem': Daniel 1:1 also names Babylon
///   (Nebuchadnezzar's home, not yet Daniel's); Babylon has the lower id.
/// - 'Vision of the ram and goat at Susa': Daniel 8:2 names Elam (the
///   province Susa is in) and the river Ulai alongside Susa itself, the
///   named city ("I was at Shushan"); both have lower ids.
const _eventPlaceOverrides = {
  'Birth of Jesus': 'Bethlehem 1',
  'John Baptizes Jesus': 'Jordan',
  'Healing Canaanite Daughter': 'Tyre',
  'Jesus Teaches in Perea': 'Judea 1',
  'Bread of Life Sermon': 'Capernaum',
  'Saul proclaims Jesus': 'Damascus',
  'First Missionary Journey': 'Antioch 1',
  'Third Missionary Journey': 'Ephesus',
  'Paul arrested in the Temple': 'Jerusalem',
  'Paul gives his testimony': 'Jerusalem',
  'Paul arrives at Rome': 'Rome',
  "Paul's First Roman imprisonment": 'Rome',
  'Abraham goes to Egypt': 'Egypt',
  'Abraham and Lot Separate': 'Bethel 1',
  'Wilderness Wanderings': 'Red Sea 1',
  'Ten Commandments Given': 'Wilderness of Sinai',
  'Tabernacle Built': 'Mount Sinai',
  'Introduced as a prophet to Ahab': 'Tishbe',
  'Fed by the widow of Zarephath': 'Zarephath',
  "Intercepts Ahaziah's messengers": 'Samaria 1',
  'Returns to Samaria': 'Samaria 1',
  "Flees Absalom's rebellion to Mahanaim": 'Mahanaim',
  "Returns to Jerusalem after Absalom's defeat": 'Jerusalem',
  "Smashes the potter's flask in the Valley of Hinnom": 'Valley of Hinnom',
  'Released from his chains at Ramah': 'Ramah 1',
  'Stops at Geruth Chimham, fleeing toward Egypt': 'Geruth Chimham',
  'Forcibly taken to Tahpanhes in Egypt': 'Tahpanhes',
  'Taken captive from Jerusalem': 'Jerusalem',
  'Vision of the ram and goat at Susa': 'Susa',
};

/// A person's dated events, each resolved to the first place named in its
/// account (lowest `event_verses.ord`, tie-broken by lowest place id) — the
/// same verse-coordinate bridge [explorerEventDetailProvider] uses to
/// cross-reference events and places, extended to pick a single deterministic
/// waypoint per event instead of every place an account happens to mention.
final personJourneyProvider =
    FutureProvider.family<PersonJourney?, int>((ref, personId) async {
  await ref.watch(curatedJourneysReadyProvider.future);
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
          !_eventsWithNoReliablePlace.contains(r.read<String>('title')) &&
          !_eventsSupersededByCuratedJourney.contains(r.read<String>('title')))
        r.read<int>('event_id'),
  ];

  final eventTitleById = {
    for (final r in eventRows) r.read<int>('event_id'): r.read<String>('title'),
  };

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
      final placeName = r.read<String>('place_name');
      final resolved = (
        placeId: r.read<int>('place_id'),
        placeName: placeName,
        lat: r.read<double>('lat'),
        lng: r.read<double>('lng'),
      );
      final override = _eventPlaceOverrides[eventTitleById[eventId]];
      if (override != null) {
        // Only the overridden place name may win for this event, regardless
        // of ord/place-id order — replace, don't just fill an empty slot.
        if (placeName == override) placesByEvent[eventId] = resolved;
        continue;
      }
      // First row per event_id wins (already ordered by ord, place.id).
      placesByEvent.putIfAbsent(eventId, () => resolved);
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
