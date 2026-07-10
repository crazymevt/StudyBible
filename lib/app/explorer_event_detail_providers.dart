part of 'explorer_providers.dart';

// --- Event page ---

class ExplorerEventDetail {
  final TimelineEvent event;

  /// Participants, most-mentioned first.
  final List<BiblePerson> participants;

  /// The event's account, in canonical order.
  final List<EventVerse> verses;

  /// Places mentioned within the event's verses, ranked by how many of those
  /// verses name each one and capped at [_maxEventPlaces] — some bundled
  /// events (a prophet's whole book of oracles, a king's whole reign, a
  /// missionary journey) otherwise resolve to dozens of incidental places.
  final List<Place> places;

  /// The true count before the cap above was applied, so the UI can show
  /// "12 of 137" instead of silently truncating.
  final int placesTotalCount;
  ExplorerEventDetail({
    required this.event,
    required this.participants,
    required this.verses,
    required this.places,
    required this.placesTotalCount,
  });
}

/// Event → place name(s) to add when the event's own tagged verses don't
/// name any indexed place at all, but the surrounding narrative establishes
/// an unambiguous setting just outside that verse range (the same class of
/// gap `_eventPlaceOverrides` in atlas_providers.dart fixes for tie-breaks
/// rather than total misses). Looked up by name in `places`; numbered
/// suffixes disambiguate repeated place names ("Bethlehem 1", "Ramah 1"),
/// same convention as curated_journeys_data.dart.
///
/// - 'Leaving the Ark': Genesis 8:4, just before this event's own 8:15-19,
///   names "the mountains of Ararat" as where the ark came to rest.
/// - 'Death of Isaac': Genesis 35:27, the verse before this event's own
///   35:28-29, names Hebron ("Mamre... which is Hebron") as the family's home.
/// - 'Birth of Job', 'Lifetime of Job', 'Death of Job': Job 1:1, the book's
///   opening line, places him "in the land of Uz."
/// - 'Judgeship of Eli', 'Death of Eli, Ark Captured': 1 Samuel 1-4 as a
///   whole is set at Shiloh, where the tabernacle stood (e.g. 4:12's "ran...
///   unto Shiloh", one verse before this event's own 4:15-18).
/// - 'United Kingdom': 1 Samuel 10:1's private anointing happens at Samuel's
///   home city, identified elsewhere as Ramah (7:17, 8:4).
/// - 'Reign of Nadab', 'Reign of Tibni', 'Death of Tibni': the northern
///   kingdom's capital at this point, per 1 Kings 15:33 and 16:8-24 (Baasha,
///   Elah, and Zimri all reign "in Tirzah"; Omri does too until he builds
///   Samaria) — Nadab inherits the same seat from Jeroboam (14:17).
/// - 'Reign of Athaliah': the throne of Judah, seized in Jerusalem
///   (2 Kings 11:3, "in the house of the LORD").
/// - 'Death of Menahem', 'Death of Pekah': Samaria, the northern capital.
/// - 'Death of Hezekiah', 'Death of Amon': Jerusalem, the throne of Judah.
/// - 'Espousal of Mary', 'An Angel Speaks to Joseph in a Dream',
///   'Childhood of Jesus': Nazareth (Luke 1:26-27, 2:39-40) — these precede
///   or follow the Bethlehem trip without a place name of their own.
/// - 'Jesus Circumsized': Luke 2:21, still within the Bethlehem stay.
/// - 'Jesus and Nicodemus': set during the Jerusalem Passover of John
///   2:23, just before this event's own 3:1-21.
/// - 'Jesus Calls Matthew', 'Fasting Question', 'Parable of the
///   Winseskins', 'Capernaum Miracles': the Matthew 9 / Luke 5 cluster is
///   set at Capernaum (Mark's parallel, 2:1, names it explicitly).
/// - 'Light of the World/I am discourse', 'The Good Shepherd Teaching':
///   continue the Jerusalem Feast of Tabernacles setting of John 7:14 and
///   the Feast of Dedication of 10:22-23.
/// - 'Sanhedrin Conspiracy', 'Judas Plans Betrayal', 'Teaching by the Fig
///   Tree', 'Chief Priests Conspire Against Jesus', 'Upper Room Discourse',
///   'The conspiracy to kill Paul': Passion-week events set in Jerusalem
///   (e.g. Matthew 26:3's "palace of the high priest"; John 13's upper room;
///   Acts 23:12's plot against Paul before the Sanhedrin).
/// - 'The church grows', 'Believers pray for boldness', 'Ananias and
///   Sapphira lie to God', 'Stephen is stoned': all Acts 2-7, continuing the
///   Jerusalem setting of Pentecost.
/// - 'Paul casts demon out of soothsayer', 'Philippian jailer converted',
///   'Paul and Silas released': Acts 16:12 names Philippi for this whole
///   sequence.
/// - 'Eutychus revived': Acts 20:6-7 names Troas for this sequence.
/// - 'Abrahamic Covenant': Genesis 12:4, "Abram departed... out of Haran,"
///   the family's home per the preceding 11:31-32.
const _eventPlaceAdditions = <String, List<String>>{
  'Leaving the Ark': ['Ararat'],
  'Death of Isaac': ['Hebron'],
  'Birth of Job': ['Uz'],
  'Lifetime of Job': ['Uz'],
  'Death of Job': ['Uz'],
  'Judgeship of Eli': ['Shiloh'],
  'Death of Eli, Ark Captured': ['Shiloh'],
  'United Kingdom': ['Ramah 1'],
  'Reign of Nadab': ['Tirzah'],
  'Reign of Tibni': ['Tirzah'],
  'Death of Tibni': ['Tirzah'],
  'Reign of Athaliah': ['Jerusalem'],
  'Death of Menahem': ['Samaria 1'],
  'Death of Pekah': ['Samaria 1'],
  'Death of Hezekiah': ['Jerusalem'],
  'Death of Amon': ['Jerusalem'],
  'Espousal of Mary': ['Nazareth'],
  'An Angel Speaks to Joseph in a Dream': ['Nazareth'],
  'Jesus Circumsized': ['Bethlehem 1'],
  'Childhood of Jesus': ['Nazareth'],
  'Jesus and Nicodemus': ['Jerusalem'],
  'Jesus Calls Matthew': ['Capernaum'],
  'Fasting Question': ['Capernaum'],
  'Parable of the Winseskins': ['Capernaum'],
  'Capernaum Miracles': ['Capernaum'],
  'Light of the World/I am discourse': ['Jerusalem'],
  'The Good Shepherd Teaching': ['Jerusalem'],
  'Sanhedrin Conspiracy': ['Jerusalem'],
  'Judas Plans Betrayal': ['Jerusalem'],
  'Teaching by the Fig Tree': ['Jerusalem'],
  'Chief Priests Conspire Against Jesus': ['Jerusalem'],
  'Upper Room Discourse': ['Jerusalem'],
  'The church grows': ['Jerusalem'],
  'Believers pray for boldness': ['Jerusalem'],
  'Ananias and Sapphira lie to God': ['Jerusalem'],
  'Stephen is stoned': ['Jerusalem'],
  'Paul casts demon out of soothsayer': ['Philippi'],
  'Philippian jailer converted': ['Philippi'],
  'Paul and Silas released': ['Philippi'],
  'Eutychus revived': ['Troas'],
  'The conspiracy to kill Paul': ['Jerusalem'],
  'Abrahamic Covenant': ['Haran'],
};

/// Cap on how many places an event page's map/chip list shows — see
/// [ExplorerEventDetail.places].
const _maxEventPlaces = 20;

final explorerEventDetailProvider =
    FutureProvider.family<ExplorerEventDetail?, int>((ref, eventId) async {
      await ref.watch(explorerReadyProvider.future);
      final store = ref.watch(contentStoreProvider);
      final event = await (store.select(
        store.timelineEvents,
      )..where((e) => e.id.equals(eventId))).getSingleOrNull();
      if (event == null) return null;

      final participantRows = await store
          .customSelect(
            'SELECT p.id AS id FROM event_participants ep '
            'JOIN bible_people p ON p.id = ep.person_id '
            'WHERE ep.event_id = ? ORDER BY p.verse_count DESC',
            variables: [Variable.withInt(eventId)],
          )
          .get();
      final participants = await _peopleByIds(store, [
        for (final r in participantRows) r.read<int>('id'),
      ]);

      final verses =
          await (store.select(store.eventVerses)
                ..where((v) => v.eventId.equals(eventId))
                ..orderBy([(v) => OrderingTerm.asc(v.ord)]))
              .get();

      // Places aren't linked to events in the dataset; the event's verses are the
      // bridge — any place mentioned in one of them belongs on the event's map.
      // Ranked by mention count so a bundled event (a prophet's whole book, a
      // king's whole reign) surfaces its most central places first instead of an
      // arbitrary alphabetical slice when capped below.
      final placeRows = await store
          .customSelect(
            'SELECT p.id AS id, p.name AS name, COUNT(*) AS mentions '
            'FROM event_verses ev '
            'JOIN place_verses pv ON pv.book_name = ev.book_name '
            '  AND pv.chapter = ev.chapter AND pv.verse = ev.verse '
            'JOIN places p ON p.id = pv.place_id '
            'WHERE ev.event_id = ? '
            'GROUP BY p.id ORDER BY mentions DESC, p.name ASC',
            variables: [Variable.withInt(eventId)],
          )
          .get();
      final placeIds = [for (final r in placeRows) r.read<int>('id')];

      final additionNames = _eventPlaceAdditions[event.title];
      if (additionNames != null) {
        final additionRows = await (store.select(
          store.places,
        )..where((p) => p.name.isIn(additionNames))).get();
        for (final p in additionRows) {
          if (!placeIds.contains(p.id)) placeIds.add(p.id);
        }
      }

      final places = await _placesByIds(
        store,
        placeIds.take(_maxEventPlaces).toList(),
      );

      return ExplorerEventDetail(
        event: event,
        participants: participants,
        verses: verses,
        places: places,
        placesTotalCount: placeIds.length,
      );
    });
