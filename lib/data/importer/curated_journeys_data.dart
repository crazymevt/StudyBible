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

  // Solomon's reign, ~1015-975 BC. Unlike Elijah/Elisha, Solomon was a
  // stationary administrative king, not an itinerant one — his diplomatic
  // and building activity (Tyre, Hazor, Megiddo, Gezer, Ezion-geber, the
  // Queen of Sheba's visit) happened via envoys, workforces, or visitors
  // coming to him, not Solomon personally traveling. His own real,
  // text-confirmed movement is just this one early round trip.
  CuratedPersonJourney(personSlug: 'solomon_2762', waypoints: [
    CuratedWaypoint(
      title: 'Anointed king at Gihon',
      year: -1015,
      bookName: '1 Kings',
      chapter: 1,
      verse: 38,
      placeName: 'Gihon 2',
    ),
    CuratedWaypoint(
      title: 'Sacrifices at Gibeon; asks for wisdom',
      year: -1014,
      bookName: '1 Kings',
      chapter: 3,
      verse: 4,
      placeName: 'Gibeon',
    ),
    CuratedWaypoint(
      title: 'Returns to Jerusalem to reign',
      year: -1013,
      bookName: '1 Kings',
      chapter: 3,
      verse: 15,
      placeName: 'Jerusalem',
    ),
  ]),

  // David's life between the two events the bundled dataset already gets
  // right ("David Kills Goliath" at -1066, "Death of David" at -1014) —
  // "Reign of David" in between is one 668-verse blob covering his entire
  // 40-year reign, replaced here with the real stops it collapses. Two
  // citations below aren't the first ones tried: 2 Samuel 11:1 (the Rabbah
  // siege beginning) literally says "David remained at Jerusalem" while
  // Joab besieged it — the siege David himself finished is 12:29, after
  // Nathan's rebuke.
  CuratedPersonJourney(personSlug: 'david_994', waypoints: [
    CuratedWaypoint(
      title: 'Anointed by Samuel at Bethlehem',
      year: -1068,
      bookName: '1 Samuel',
      chapter: 16,
      verse: 4,
      placeName: 'Bethlehem 1',
    ),
    // -1066: "David Kills Goliath" (bundled dataset, unchanged) -> Azekah.
    CuratedWaypoint(
      title: 'Flees to the priest at Nob',
      year: -1062,
      bookName: '1 Samuel',
      chapter: 21,
      verse: 1,
      placeName: 'Nob',
    ),
    CuratedWaypoint(
      title: 'Feigns madness before Achish at Gath',
      year: -1061,
      bookName: '1 Samuel',
      chapter: 21,
      verse: 10,
      placeName: 'Gath 1',
    ),
    CuratedWaypoint(
      title: 'Gathers followers at the cave of Adullam',
      year: -1060,
      bookName: '1 Samuel',
      chapter: 22,
      verse: 1,
      placeName: 'Adullam',
    ),
    CuratedWaypoint(
      title: 'Rescues Keilah from the Philistines',
      year: -1059,
      bookName: '1 Samuel',
      chapter: 23,
      verse: 5,
      placeName: 'Keilah',
    ),
    CuratedWaypoint(
      title: "Spares Saul's life at En-gedi",
      year: -1058,
      bookName: '1 Samuel',
      chapter: 24,
      verse: 1,
      placeName: 'Engedi',
    ),
    CuratedWaypoint(
      title: 'Nabal and Abigail at Carmel',
      year: -1057,
      bookName: '1 Samuel',
      chapter: 25,
      verse: 2,
      placeName: 'Carmel 1',
    ),
    CuratedWaypoint(
      title: 'Given Ziklag by Achish',
      year: -1056,
      bookName: '1 Samuel',
      chapter: 27,
      verse: 6,
      placeName: 'Ziklag',
    ),
    CuratedWaypoint(
      title: 'Anointed king over Judah at Hebron',
      year: -1054,
      bookName: '2 Samuel',
      chapter: 2,
      verse: 1,
      placeName: 'Hebron',
    ),
    CuratedWaypoint(
      title: 'Captures Jebus; establishes the City of David',
      year: -1047,
      bookName: '2 Samuel',
      chapter: 5,
      verse: 7,
      placeName: 'City of David',
    ),
    CuratedWaypoint(
      title: 'Brings the Ark up to Jerusalem',
      year: -1046,
      bookName: '2 Samuel',
      chapter: 6,
      verse: 12,
      placeName: 'City of David',
    ),
    CuratedWaypoint(
      title: 'Finishes the siege of Rabbah',
      year: -1035,
      bookName: '2 Samuel',
      chapter: 12,
      verse: 29,
      placeName: 'Rabbah 1',
    ),
    CuratedWaypoint(
      title: "Flees Absalom's rebellion to Mahanaim",
      year: -1023,
      bookName: '2 Samuel',
      chapter: 17,
      verse: 24,
      placeName: 'Mahanaim',
    ),
    CuratedWaypoint(
      title: "Returns to Jerusalem after Absalom's defeat",
      year: -1022,
      bookName: '2 Samuel',
      chapter: 19,
      verse: 15,
      placeName: 'Jerusalem',
    ),
    CuratedWaypoint(
      title: 'Numbers the people; the plague at Jerusalem',
      year: -1017,
      bookName: '2 Samuel',
      chapter: 24,
      verse: 16,
      placeName: 'Jerusalem',
    ),
    // -1014: "Death of David" (bundled dataset, unchanged) -> City of David.
  ]),

  // Isaiah's entire recorded biography, unlike every prior figure here, is
  // essentially one-location: court prophet to four kings, all in
  // Jerusalem. Most of the book's narrative-sounding episodes turn out on
  // close reading to describe someone *else's* location, not his own — the
  // Assyrian general reaching Ashdod (20:1), the Rabshakeh from Lachish
  // (36:2), Babylonian envoys (39:1) — the same "names a place, but not the
  // narrator's own" pattern documented elsewhere in this file. Kept honest
  // and short rather than padded: two real stops, both effectively in or
  // just outside Jerusalem.
  CuratedPersonJourney(personSlug: 'isaiah_617', waypoints: [
    CuratedWaypoint(
      title: 'Called as a prophet in the Temple',
      year: -758,
      bookName: 'Isaiah',
      chapter: 6,
      verse: 1,
      placeName: 'Jerusalem',
    ),
    CuratedWaypoint(
      title: 'Meets Ahaz at the Upper Pool conduit',
      year: -734,
      bookName: 'Isaiah',
      chapter: 7,
      verse: 3,
      placeName: 'Upper Pool',
    ),
  ]),

  // Jeremiah's ministry spans four kings' reigns and the fall of Jerusalem,
  // ~627-585 BC — much more narrative than Isaiah, but several of its most
  // "location-sounding" verses turn out to name someone *else's* location at
  // that moment, not Jeremiah's own: 38:7's "gate of Benjamin" is where the
  // king was sitting when Ebedmelech heard the news, not where the
  // imprisoned Jeremiah was; 36:10's temple reading was done by Baruch,
  // because Jeremiah had just said "I am shut up; I cannot go into the
  // house of the LORD" (36:5). Both skipped. 38:6 (lowered into Malchiah's
  // cistern) and 38:13 (drawn back out) aren't tagged to any place at all in
  // the bundled gazetteer, so 38:28 ("remained in the court of the prison
  // until Jerusalem was taken") stands in as the bookend for that whole
  // imprisonment, the same way David's census/plague episode used 24:16
  // instead of the untagged 24:18.
  CuratedPersonJourney(personSlug: 'jeremiah_853', waypoints: [
    CuratedWaypoint(
      title: 'Called as a young prophet at Anathoth',
      year: -627,
      bookName: 'Jeremiah',
      chapter: 1,
      verse: 1,
      placeName: 'Anathoth',
    ),
    CuratedWaypoint(
      title: 'Smashes the potter\'s flask in the Valley of Hinnom',
      year: -609,
      bookName: 'Jeremiah',
      chapter: 19,
      verse: 2,
      placeName: 'Valley of Hinnom',
    ),
    CuratedWaypoint(
      title: 'Struck and put in the stocks by Pashhur',
      year: -609,
      bookName: 'Jeremiah',
      chapter: 20,
      verse: 2,
      placeName: 'Benjamin Gate',
    ),
    CuratedWaypoint(
      title: 'Arrested at the gate, accused of deserting to the Chaldeans',
      year: -588,
      bookName: 'Jeremiah',
      chapter: 37,
      verse: 13,
      placeName: 'Benjamin Gate',
    ),
    CuratedWaypoint(
      title: 'Remains imprisoned until Jerusalem falls',
      year: -587,
      bookName: 'Jeremiah',
      chapter: 38,
      verse: 28,
      placeName: 'Jerusalem',
    ),
    CuratedWaypoint(
      title: 'Released from his chains at Ramah',
      year: -586,
      bookName: 'Jeremiah',
      chapter: 40,
      verse: 1,
      placeName: 'Ramah 1',
    ),
    CuratedWaypoint(
      title: 'Goes to Gedaliah at Mizpah',
      year: -586,
      bookName: 'Jeremiah',
      chapter: 40,
      verse: 6,
      placeName: 'Mizpah 3',
    ),
    CuratedWaypoint(
      title: 'Stops at Geruth Chimham, fleeing toward Egypt',
      year: -585,
      bookName: 'Jeremiah',
      chapter: 41,
      verse: 17,
      placeName: 'Geruth Chimham',
    ),
    CuratedWaypoint(
      title: 'Forcibly taken to Tahpanhes in Egypt',
      year: -585,
      bookName: 'Jeremiah',
      chapter: 43,
      verse: 7,
      placeName: 'Tahpanhes',
    ),
  ]),

  // Daniel's book is almost entirely court-set in Babylon, and — like
  // Isaiah — several of its most narrative-sounding verses turn out to name
  // somewhere other than Daniel's own location: 6:10's "windows... open
  // toward Jerusalem" is the direction he prayed, not where he stood;
  // 5:2-3's temple vessels are described by their Jerusalem origin, not
  // Belshazzar's feast hall. The golden-image episode (ch. 3) and the
  // lions'-den episode (ch. 6) are both skipped outright: Daniel isn't
  // textually present at the former (only his three friends are), and no
  // verse in the latter ties to any specific place at all. What's left is
  // honest but includes two real, named excursions away from Babylon that
  // are easy to miss: the ch. 8 vision at Susa and the ch. 10 vision by the
  // Tigris.
  CuratedPersonJourney(personSlug: 'daniel_975', waypoints: [
    CuratedWaypoint(
      title: 'Taken captive from Jerusalem',
      year: -605,
      bookName: 'Daniel',
      chapter: 1,
      verse: 1,
      placeName: 'Jerusalem',
    ),
    CuratedWaypoint(
      title: "Brought into the king's court at Babylon",
      year: -605,
      bookName: 'Daniel',
      chapter: 1,
      verse: 3,
      placeName: 'Babylon 1',
    ),
    CuratedWaypoint(
      title: 'Made ruler over the province of Babylon',
      year: -603,
      bookName: 'Daniel',
      chapter: 2,
      verse: 48,
      placeName: 'Babylon 1',
    ),
    CuratedWaypoint(
      title: "Vision of the ram and goat at Susa",
      year: -551,
      bookName: 'Daniel',
      chapter: 8,
      verse: 2,
      placeName: 'Susa',
    ),
    CuratedWaypoint(
      title: 'Vision by the great river Tigris',
      year: -536,
      bookName: 'Daniel',
      chapter: 10,
      verse: 4,
      placeName: 'Tigris',
    ),
  ]),

  // Ahab is different from every prior entry here: the bundled dataset's
  // "Reign of Ahab" event isn't a life-spanning blob, it's just his 3-verse
  // succession notice (1 Kings 16:28-30) — accurate, resolves cleanly to
  // Samaria, and left alone. What's missing is everything after it: his
  // entire 22-chapter reign (contest with Baal's prophets, two wars with
  // Ben-hadad, Naboth's vineyard, death at Ramoth-gilead) had no dated
  // waypoints at all. These fill that gap.
  CuratedPersonJourney(personSlug: 'ahab_113', waypoints: [
    CuratedWaypoint(
      title: "Gathers Israel to Mount Carmel for Elijah's contest",
      year: -863,
      bookName: '1 Kings',
      chapter: 18,
      verse: 20,
      placeName: 'Mount Carmel',
    ),
    CuratedWaypoint(
      title: 'Besieged in Samaria by Ben-hadad',
      year: -858,
      bookName: '1 Kings',
      chapter: 20,
      verse: 1,
      placeName: 'Samaria 1',
    ),
    CuratedWaypoint(
      title: "Defeats Ben-hadad's second invasion at Aphek",
      year: -857,
      bookName: '1 Kings',
      chapter: 20,
      verse: 30,
      placeName: 'Aphek 3',
    ),
    CuratedWaypoint(
      title: "Seizes Naboth's vineyard at Jezreel",
      year: -855,
      bookName: '1 Kings',
      chapter: 21,
      verse: 1,
      placeName: 'Jezreel 2',
    ),
    CuratedWaypoint(
      title: 'Marches to Ramoth-gilead disguised',
      year: -853,
      bookName: '1 Kings',
      chapter: 22,
      verse: 29,
      placeName: 'Ramoth-gilead',
    ),
    CuratedWaypoint(
      title: 'Brought back to Samaria and buried',
      year: -853,
      bookName: '1 Kings',
      chapter: 22,
      verse: 37,
      placeName: 'Samaria 1',
    ),
  ]),

  // The bundled dataset's "Reign of Jeroboam I" resolves to Egypt via 1
  // Kings 12:20 — but that verse's own text is "when all Israel heard that
  // Jeroboam was come again... made him king", meaning he had *already*
  // returned by then. It's the same retrospective-reference pattern found
  // throughout this file, just from the gazetteer's own tagging rather than
  // theographic.json's event data. Superseded here with real stops:
  // 12:28's "brought thee up out of Egypt" and 11:29's "went out of
  // Jerusalem" (where Ahijah, "the Shilonite", is found "in the way" — an
  // unspecified location between the two, not actually Jerusalem or Shiloh)
  // are both skipped for the same reason. So are 14:2 and 14:17: both
  // describe his wife's errand to Shiloh and back to Tirzah, not Jeroboam's
  // own location.
  CuratedPersonJourney(personSlug: 'jeroboam_872', waypoints: [
    CuratedWaypoint(
      title: 'Introduced as an Ephraimite of Zeredah',
      year: -990,
      bookName: '1 Kings',
      chapter: 11,
      verse: 26,
      placeName: 'Zeredah 1',
    ),
    CuratedWaypoint(
      title: 'Flees to Egypt from Solomon',
      year: -988,
      bookName: '1 Kings',
      chapter: 11,
      verse: 40,
      placeName: 'Egypt',
    ),
    CuratedWaypoint(
      title: "Hears of Solomon's death while still in Egypt",
      year: -975,
      bookName: '1 Kings',
      chapter: 12,
      verse: 2,
      placeName: 'Egypt',
    ),
    CuratedWaypoint(
      title: 'Returns and is made king over Israel at Shechem',
      year: -975,
      bookName: '1 Kings',
      chapter: 12,
      verse: 1,
      placeName: 'Shechem',
    ),
    CuratedWaypoint(
      title: 'Rebuilds and settles at Shechem as his capital',
      year: -974,
      bookName: '1 Kings',
      chapter: 12,
      verse: 25,
      placeName: 'Shechem',
    ),
    CuratedWaypoint(
      title: 'Also fortifies Penuel',
      year: -974,
      bookName: '1 Kings',
      chapter: 12,
      verse: 25,
      placeName: 'Penuel',
    ),
    CuratedWaypoint(
      title: 'Sets up the golden calf at Bethel',
      year: -973,
      bookName: '1 Kings',
      chapter: 12,
      verse: 29,
      placeName: 'Bethel 1',
    ),
    CuratedWaypoint(
      title: 'Sets up the golden calf at Dan',
      year: -973,
      bookName: '1 Kings',
      chapter: 12,
      verse: 29,
      placeName: 'Dan',
    ),
    CuratedWaypoint(
      title: 'Confronted by the man of God from Judah at Bethel',
      year: -973,
      bookName: '1 Kings',
      chapter: 13,
      verse: 1,
      placeName: 'Bethel 1',
    ),
  ]),

  // Unlike Jeroboam, the bundled "Deliverance by Gideon" resolves correctly
  // — Ophrah (Judges 6:11), where his calling actually happens — so it's
  // kept as the opening waypoint here, not superseded. What's missing is
  // the rest of the campaign's real geography. Several tempting verses
  // along the way describe someone/something *else's* location, not
  // Gideon's own, and are skipped: 6:33 is the Midianite/Amalekite muster
  // in the Valley of Jezreel; 7:22, 7:24, and 7:25 describe the fleeing
  // army's route and the Ephraimites seizing the fords, all before Gideon's
  // own crossing at 8:4 (which restates the same crossing already implied
  // by 7:25, so only 8:4 is kept, to avoid citing the same crossing twice).
  CuratedPersonJourney(personSlug: 'gideon_1314', waypoints: [
    CuratedWaypoint(
      title: 'Camps at the well of Harod before the battle',
      year: -1249,
      bookName: 'Judges',
      chapter: 7,
      verse: 1,
      placeName: 'Harod 1',
    ),
    CuratedWaypoint(
      title: 'Crosses the Jordan in pursuit of Zebah and Zalmunna',
      year: -1249,
      bookName: 'Judges',
      chapter: 8,
      verse: 4,
      placeName: 'Jordan',
    ),
    CuratedWaypoint(
      title: 'Denied bread by the men of Succoth',
      year: -1249,
      bookName: 'Judges',
      chapter: 8,
      verse: 5,
      placeName: 'Succoth 1',
    ),
    CuratedWaypoint(
      title: 'Denied again at Penuel',
      year: -1249,
      bookName: 'Judges',
      chapter: 8,
      verse: 8,
      placeName: 'Penuel',
    ),
    CuratedWaypoint(
      title: "Surprises the kings' camp near Jogbehah",
      year: -1249,
      bookName: 'Judges',
      chapter: 8,
      verse: 11,
      placeName: 'Jogbehah',
    ),
    CuratedWaypoint(
      title: 'Returns from battle by the ascent of Heres',
      year: -1249,
      bookName: 'Judges',
      chapter: 8,
      verse: 13,
      placeName: 'Heres',
    ),
    CuratedWaypoint(
      title: 'Punishes the elders of Succoth',
      year: -1249,
      bookName: 'Judges',
      chapter: 8,
      verse: 16,
      placeName: 'Succoth 1',
    ),
    CuratedWaypoint(
      title: 'Beats down the tower of Penuel',
      year: -1249,
      bookName: 'Judges',
      chapter: 8,
      verse: 17,
      placeName: 'Penuel',
    ),
    CuratedWaypoint(
      title: 'Sets up the ephod at Ophrah',
      year: -1248,
      bookName: 'Judges',
      chapter: 8,
      verse: 27,
      placeName: 'Ophrah 2',
    ),
    CuratedWaypoint(
      title: 'Dies and is buried at Ophrah',
      year: -1210,
      bookName: 'Judges',
      chapter: 8,
      verse: 32,
      placeName: 'Ophrah 2',
    ),
  ]),

  // Like Ahab and Gideon, the bundled "Reign of Zedekiah" already resolves
  // correctly — Jerusalem, via his enthronement notice (2 Kings 24:18) —
  // and is kept as the opening waypoint. What follows is the fall of
  // Jerusalem and his capture, one of the most dramatic single episodes in
  // the Old Testament, but scattered across three near-identical parallel
  // accounts (2 Kings 25, Jeremiah 39, Jeremiah 52) whose place tags
  // frequently favor an incidental mention (the besieging army's origin or
  // ultimate destination) over Zedekiah's own location at that moment.
  CuratedPersonJourney(personSlug: 'zedekiah_1950', waypoints: [
    CuratedWaypoint(
      title: 'Besieged in Jerusalem by Nebuchadnezzar',
      year: -588,
      bookName: '2 Kings',
      chapter: 25,
      verse: 1,
      placeName: 'Jerusalem',
    ),
    CuratedWaypoint(
      title: 'Flees Jerusalem by night toward the plain',
      year: -586,
      bookName: '2 Kings',
      chapter: 25,
      verse: 4,
      placeName: 'Arabah',
    ),
    CuratedWaypoint(
      title: 'Captured in the plains of Jericho',
      year: -586,
      bookName: '2 Kings',
      chapter: 25,
      verse: 5,
      placeName: 'Jericho 1',
    ),
    CuratedWaypoint(
      title: 'Sentenced before Nebuchadnezzar at Riblah',
      year: -586,
      bookName: '2 Kings',
      chapter: 25,
      verse: 6,
      placeName: 'Riblah 1',
    ),
    CuratedWaypoint(
      title: 'Sons slain before his eyes at Riblah',
      year: -586,
      bookName: 'Jeremiah',
      chapter: 39,
      verse: 6,
      placeName: 'Riblah 1',
    ),
    CuratedWaypoint(
      title: 'Blinded and carried to Babylon',
      year: -586,
      bookName: 'Jeremiah',
      chapter: 52,
      verse: 11,
      placeName: 'Babylon 1',
    ),
  ]),

  // Unlike the prophets and warrior-judges above, Rehoboam's own narrative
  // barely moves: he goes to Shechem to be confirmed king, flees back to
  // Jerusalem when the ten tribes revolt, and stays there for the rest of
  // his reign — including when Shishak's invasion catches up with him five
  // years later. The bundled "Reign of Rehoboam" event (1 Kings 12:17-24)
  // already resolves correctly to Jerusalem via its first placed verse
  // (12:18, fleeing there after Adoram is stoned) and is kept as-is. Added
  // here: the Shechem confrontation that precedes it, and the Shishak
  // episode that follows — both single-place verses with no competing tie
  // in places.json, so neither needs an override. (The fortified-cities
  // list in 2 Chr 11:5-10 is deliberately excluded — it's an administrative
  // summary of what he built, not a narrated personal itinerary, and each
  // verse there ties 3 cities at once with no way to tell which he actually
  // visited himself.)
  CuratedPersonJourney(personSlug: 'rehoboam_2412', waypoints: [
    CuratedWaypoint(
      title: 'Goes to Shechem to be made king',
      year: -975,
      bookName: '1 Kings',
      chapter: 12,
      verse: 1,
      placeName: 'Shechem',
    ),
    CuratedWaypoint(
      title: 'Humbled at Jerusalem before Shishak\'s invasion',
      year: -970,
      bookName: '2 Chronicles',
      chapter: 12,
      verse: 5,
      placeName: 'Jerusalem',
    ),
  ]),

  // Like Rehoboam, the bundled "Reign of Jehoiakim" event (2 Kings 23:36-24:7)
  // already resolves correctly to Jerusalem via its first placed verse
  // (23:36, his enthronement notice) and is kept as-is. Added here: an
  // earlier episode the 2 Kings summary telescopes past entirely —
  // Nebuchadnezzar's first campaign against Judah, which carried Jehoiakim
  // off to Babylon with some of the temple vessels (2 Chr 36:6-7; the same
  // event Daniel 1:1-2 describes from Daniel's side) — and the scroll-burning
  // incident (Jeremiah 36) a couple of years later, after he'd been
  // reinstated as a tribute-paying vassal back in Jerusalem. Jeremiah's
  // prophecy that he'd die and be buried "beyond the gates of Jerusalem"
  // (Jer. 22:19) is deliberately excluded — it's a prophetic oracle spoken
  // while Jehoiakim was still alive, not a narrated report of his actual
  // death, and no other verse ties his death to a place.
  CuratedPersonJourney(personSlug: 'jehoiakim_1085', waypoints: [
    CuratedWaypoint(
      title: 'Bound in fetters by Nebuchadnezzar at Jerusalem',
      year: -605,
      bookName: '2 Chronicles',
      chapter: 36,
      verse: 6,
      placeName: 'Jerusalem',
    ),
    CuratedWaypoint(
      title: 'Carried captive to Babylon with the temple vessels',
      year: -605,
      bookName: '2 Chronicles',
      chapter: 36,
      verse: 7,
      placeName: 'Babylon 1',
    ),
    CuratedWaypoint(
      title: "Baruch reads Jeremiah's scroll before the fast at Jerusalem",
      year: -603,
      bookName: 'Jeremiah',
      chapter: 36,
      verse: 9,
      placeName: 'Jerusalem',
    ),
  ]),
];
