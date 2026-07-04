/// Hand-curated Atlas journey waypoints for people whose entry in
/// `theographic.json` collapses their entire, well-documented ministry into
/// a single dated event — too coarse to ever produce a real multi-stop path
/// through [PersonJourney] (see atlas_providers.dart). Elijah and Elisha are
/// the first two; more can be appended here later without any code changes —
/// just a new [CuratedPersonJourney] entry, following the same process:
/// verify every waypoint against the real verse text and cross-check it
/// against `places.json`'s own verse links for competing ties (see the
/// `atlas-curated-journey-verification-process` memory).
///
/// TODO: remaining priority list (single/few-dot journey today, ≥30 verses,
/// identified but not yet curated):
///   - Solomon (`solomon_2762`)
///   - David (`david_994`) — 3 events, but "Reign of David" is one
///     668-verse blob spanning his whole 40-year reign
///   - Isaiah (`isaiah_617`)
///   - Jeremiah (`jeremiah_853`)
///   - Daniel (`daniel_975`)
///   - Ahab (`ahab_113`)
///   - Jeroboam (`jeroboam_872`)
///   - Gideon (`gideon_1314`)
///   - Zedekiah (`zedekiah_1950`)
///   - Rehoboam (`rehoboam_2412`)
///   - Jehoiakim (`jehoiakim_1085`)
///   - Abimelech (`abimelech_41`)
///   - Caleb (`caleb_537`)
///   - Esau (`esau_1216`)
///   - Benjamin (`benjamin_463`)
///
/// Years are approximate and sequential within each person's known ministry
/// window, not literal text-given dates — the same convention the bundled
/// Theographic dataset already uses throughout (its BC years are themselves
/// a modern scholarly reconstruction). `bookName`/`chapter`/`verse` is the
/// single verse each waypoint resolves its place from (and doubles as the
/// "Read passage" link); `placeName` must match a `places.name` row exactly.
class CuratedWaypoint {
  final String title;
  final int year;
  final String bookName;
  final int chapter;
  final int verse;
  final String placeName;

  const CuratedWaypoint({
    required this.title,
    required this.year,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.placeName,
  });
}

class CuratedPersonJourney {
  /// Matches `bible_people.slug`.
  final String personSlug;

  /// Already in chronological order.
  final List<CuratedWaypoint> waypoints;

  const CuratedPersonJourney({
    required this.personSlug,
    required this.waypoints,
  });
}

const curatedPersonJourneys = <CuratedPersonJourney>[
  // Elijah's ministry under Ahab, Ahaziah, and early Jehoram, ~874-848 BC.
  CuratedPersonJourney(personSlug: 'elijah_1131', waypoints: [
    CuratedWaypoint(
      title: 'Introduced as a prophet to Ahab',
      year: -870,
      bookName: '1 Kings',
      chapter: 17,
      verse: 1,
      placeName: 'Tishbe',
    ),
    CuratedWaypoint(
      title: 'Hides at the Brook Cherith',
      year: -869,
      bookName: '1 Kings',
      chapter: 17,
      verse: 3,
      placeName: 'Cherith',
    ),
    CuratedWaypoint(
      title: "Fed by the widow of Zarephath",
      year: -868,
      bookName: '1 Kings',
      chapter: 17,
      verse: 9,
      placeName: 'Zarephath',
    ),
    CuratedWaypoint(
      title: 'Contest with the prophets of Baal',
      year: -863,
      bookName: '1 Kings',
      chapter: 18,
      verse: 19,
      placeName: 'Mount Carmel',
    ),
    CuratedWaypoint(
      title: "Outruns Ahab's chariot to Jezreel",
      year: -863,
      bookName: '1 Kings',
      chapter: 18,
      verse: 45,
      placeName: 'Jezreel 2',
    ),
    CuratedWaypoint(
      title: 'Flees Jezebel to Beersheba',
      year: -862,
      bookName: '1 Kings',
      chapter: 19,
      verse: 3,
      placeName: 'Beersheba 1',
    ),
    CuratedWaypoint(
      title: 'Forty days to Horeb; the still small voice',
      year: -862,
      bookName: '1 Kings',
      chapter: 19,
      verse: 8,
      placeName: 'Mount Horeb',
    ),
    CuratedWaypoint(
      title: 'Calls Elisha, who is plowing',
      year: -861,
      bookName: '1 Kings',
      chapter: 19,
      verse: 19,
      placeName: 'Abel-meholah',
    ),
    CuratedWaypoint(
      title: "Confronts Ahab over Naboth's vineyard",
      year: -858,
      bookName: '1 Kings',
      chapter: 21,
      verse: 1,
      placeName: 'Jezreel 2',
    ),
    CuratedWaypoint(
      title: "Intercepts Ahaziah's messengers",
      year: -852,
      bookName: '2 Kings',
      chapter: 1,
      verse: 3,
      placeName: 'Samaria 1',
    ),
    CuratedWaypoint(
      title: 'Sets out with Elisha on his last day',
      year: -848,
      bookName: '2 Kings',
      chapter: 2,
      verse: 1,
      placeName: 'Gilgal 2',
    ),
    CuratedWaypoint(
      title: 'Passes through Bethel',
      year: -848,
      bookName: '2 Kings',
      chapter: 2,
      verse: 2,
      placeName: 'Bethel 1',
    ),
    CuratedWaypoint(
      title: 'Passes through Jericho',
      year: -848,
      bookName: '2 Kings',
      chapter: 2,
      verse: 4,
      placeName: 'Jericho 1',
    ),
    CuratedWaypoint(
      title: 'Taken up in a whirlwind',
      year: -848,
      bookName: '2 Kings',
      chapter: 2,
      verse: 6,
      placeName: 'Jordan',
    ),
  ]),

  // Elisha's ministry under Jehoram, Jehu, Jehoahaz, and into Jehoash's
  // reign, ~848-796 BC.
  CuratedPersonJourney(personSlug: 'elisha_1153', waypoints: [
    CuratedWaypoint(
      title: "Takes up Elijah's mantle, crosses the Jordan",
      year: -848,
      bookName: '2 Kings',
      chapter: 2,
      verse: 13,
      placeName: 'Jordan',
    ),
    CuratedWaypoint(
      title: 'Heals the water at Jericho',
      year: -848,
      bookName: '2 Kings',
      chapter: 2,
      verse: 19,
      placeName: 'Jericho 1',
    ),
    CuratedWaypoint(
      title: 'Mocked by youths at Bethel',
      year: -847,
      bookName: '2 Kings',
      chapter: 2,
      verse: 23,
      placeName: 'Bethel 1',
    ),
    CuratedWaypoint(
      title: 'Goes on to Mount Carmel',
      year: -847,
      bookName: '2 Kings',
      chapter: 2,
      verse: 25,
      placeName: 'Mount Carmel',
    ),
    CuratedWaypoint(
      title: 'Returns to Samaria',
      year: -846,
      bookName: '2 Kings',
      chapter: 2,
      verse: 25,
      placeName: 'Samaria 1',
    ),
    CuratedWaypoint(
      title: 'The Shunammite woman',
      year: -840,
      bookName: '2 Kings',
      chapter: 4,
      verse: 8,
      placeName: 'Shunem',
    ),
    CuratedWaypoint(
      title: 'The poisoned stew at Gilgal',
      year: -835,
      bookName: '2 Kings',
      chapter: 4,
      verse: 38,
      placeName: 'Gilgal 2',
    ),
    CuratedWaypoint(
      title: 'Surrounded by the Syrian army at Dothan',
      year: -810,
      bookName: '2 Kings',
      chapter: 6,
      verse: 13,
      placeName: 'Dothan',
    ),
    CuratedWaypoint(
      title: 'Leads the blinded army to Samaria',
      year: -810,
      bookName: '2 Kings',
      chapter: 6,
      verse: 20,
      placeName: 'Samaria 1',
    ),
    CuratedWaypoint(
      title: 'Anoints Hazael at Damascus',
      year: -798,
      bookName: '2 Kings',
      chapter: 8,
      verse: 7,
      placeName: 'Damascus',
    ),
  ]),
];
