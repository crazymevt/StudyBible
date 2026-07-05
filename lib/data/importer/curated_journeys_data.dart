/// Hand-curated Atlas journey waypoints for people whose entry in
/// `theographic.json` collapses their entire, well-documented ministry into
/// a single dated event — too coarse to ever produce a real multi-stop path
/// through [PersonJourney] (see atlas_providers.dart). Elijah and Elisha were
/// the first two; the original priority list (single/few-dot journey, ≥30
/// verses) is now fully curated. More people can still be appended here
/// without any code changes — just a new [CuratedPersonJourney] entry,
/// following the same process: verify every waypoint against the real verse
/// text and cross-check it against `places.json`'s own verse links for
/// competing ties (see the `atlas-curated-journey-verification-process`
/// memory).
///
/// Years are approximate and sequential within each person's known ministry
/// window, not literal text-given dates — the same convention the bundled
/// Theographic dataset already uses throughout (its BC years are themselves
/// a modern scholarly reconstruction). `bookName`/`chapter`/`verse` is the
/// single verse each waypoint resolves its place from (and doubles as the
/// "Read passage" link); `placeName` must match a `places.name` row exactly.
///
/// `year` is a `num`, not an `int`, so a waypoint can be interleaved *between*
/// two Theographic events that round to the same whole year: those events'
/// own `sortKey` is a fractional value derived from `theographic.json`'s `k`
/// field (finer than the `y` field/`startYear` shown in the UI), and several
/// of a single person's bundled events can land within 0.001 of each other —
/// e.g. Moses's "Exodus from Egypt", "Wilderness Wanderings", and "Ten
/// Commandments Given" are all dated 1490 BC, a few ten-thousandths apart.
/// A curated stop that belongs between two such events needs a fractional
/// year in that same gap (see Moses below); plain integers work everywhere
/// else, same as before.
class CuratedWaypoint {
  final String title;
  final num? year;
  final String bookName;
  final int chapter;
  final int verse;
  final String placeName;

  const CuratedWaypoint({
    required this.title,
    this.year,
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
  CuratedPersonJourney(
    personSlug: 'elijah_1131',
    waypoints: [
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
    ],
  ),

  // Elisha's ministry under Jehoram, Jehu, Jehoahaz, and into Jehoash's
  // reign, ~848-796 BC.
  CuratedPersonJourney(
    personSlug: 'elisha_1153',
    waypoints: [
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
    ],
  ),

  // Solomon's reign, ~1015-975 BC. Unlike Elijah/Elisha, Solomon was a
  // stationary administrative king, not an itinerant one — his diplomatic
  // and building activity (Tyre, Hazor, Megiddo, Gezer, Ezion-geber, the
  // Queen of Sheba's visit) happened via envoys, workforces, or visitors
  // coming to him, not Solomon personally traveling. His own real,
  // text-confirmed movement is just this one early round trip.
  CuratedPersonJourney(
    personSlug: 'solomon_2762',
    waypoints: [
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
    ],
  ),

  // David's life between the two events the bundled dataset already gets
  // right ("David Kills Goliath" at -1066, "Death of David" at -1014) —
  // "Reign of David" in between is one 668-verse blob covering his entire
  // 40-year reign, replaced here with the real stops it collapses. Two
  // citations below aren't the first ones tried: 2 Samuel 11:1 (the Rabbah
  // siege beginning) literally says "David remained at Jerusalem" while
  // Joab besieged it — the siege David himself finished is 12:29, after
  // Nathan's rebuke.
  CuratedPersonJourney(
    personSlug: 'david_994',
    waypoints: [
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
    ],
  ),

  // Isaiah's entire recorded biography, unlike every prior figure here, is
  // essentially one-location: court prophet to four kings, all in
  // Jerusalem. Most of the book's narrative-sounding episodes turn out on
  // close reading to describe someone *else's* location, not his own — the
  // Assyrian general reaching Ashdod (20:1), the Rabshakeh from Lachish
  // (36:2), Babylonian envoys (39:1) — the same "names a place, but not the
  // narrator's own" pattern documented elsewhere in this file. Kept honest
  // and short rather than padded: two real stops, both effectively in or
  // just outside Jerusalem.
  CuratedPersonJourney(
    personSlug: 'isaiah_617',
    waypoints: [
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
    ],
  ),

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
  CuratedPersonJourney(
    personSlug: 'jeremiah_853',
    waypoints: [
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
    ],
  ),

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
  CuratedPersonJourney(
    personSlug: 'daniel_975',
    waypoints: [
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
    ],
  ),

  // Ahab is different from every prior entry here: the bundled dataset's
  // "Reign of Ahab" event isn't a life-spanning blob, it's just his 3-verse
  // succession notice (1 Kings 16:28-30) — accurate, resolves cleanly to
  // Samaria, and left alone. What's missing is everything after it: his
  // entire 22-chapter reign (contest with Baal's prophets, two wars with
  // Ben-hadad, Naboth's vineyard, death at Ramoth-gilead) had no dated
  // waypoints at all. These fill that gap.
  CuratedPersonJourney(
    personSlug: 'ahab_113',
    waypoints: [
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
    ],
  ),

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
  CuratedPersonJourney(
    personSlug: 'jeroboam_872',
    waypoints: [
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
    ],
  ),

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
  CuratedPersonJourney(
    personSlug: 'gideon_1314',
    waypoints: [
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
    ],
  ),

  // Like Ahab and Gideon, the bundled "Reign of Zedekiah" already resolves
  // correctly — Jerusalem, via his enthronement notice (2 Kings 24:18) —
  // and is kept as the opening waypoint. What follows is the fall of
  // Jerusalem and his capture, one of the most dramatic single episodes in
  // the Old Testament, but scattered across three near-identical parallel
  // accounts (2 Kings 25, Jeremiah 39, Jeremiah 52) whose place tags
  // frequently favor an incidental mention (the besieging army's origin or
  // ultimate destination) over Zedekiah's own location at that moment.
  CuratedPersonJourney(
    personSlug: 'zedekiah_1950',
    waypoints: [
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
    ],
  ),

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
  CuratedPersonJourney(
    personSlug: 'rehoboam_2412',
    waypoints: [
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
    ],
  ),

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
  CuratedPersonJourney(
    personSlug: 'jehoiakim_1085',
    waypoints: [
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
    ],
  ),

  // Unlike Ahab/Gideon/Zedekiah/Rehoboam/Jehoiakim above, Abimelech's single
  // bundled event ("Usurpation by Abimelech", Judges 8:29-9:57) isn't a thin
  // succession notice — it's the entire, genuinely multi-stop story of his
  // rise and fall, already spanning real places (Shechem, Ophrah, Arumah,
  // Mount Zalmon, Thebez) that just all collapse to one dot (Shechem, via
  // his birth notice at 8:31) under today's "first placed verse wins"
  // resolution. Kept as the opening waypoint since Shechem genuinely is
  // where his story starts — proclaimed king there in 9:6 — and every stop
  // below is a real, distinct place his own narrative puts him. No overrides
  // were needed: only one citation (9:41) ties another place at all
  // (Shechem, where he isn't currently standing), and Arumah already has the
  // lower id.
  CuratedPersonJourney(
    personSlug: 'abimelech_41',
    waypoints: [
      CuratedWaypoint(
        title: 'Murders his seventy brothers at Ophrah',
        year: -1216,
        bookName: 'Judges',
        chapter: 9,
        verse: 5,
        placeName: 'Ophrah 2',
      ),
      CuratedWaypoint(
        title: 'Dwells at Arumah as Shechem revolts',
        year: -1214,
        bookName: 'Judges',
        chapter: 9,
        verse: 41,
        placeName: 'Arumah',
      ),
      CuratedWaypoint(
        title: 'Storms the gate of Shechem',
        year: -1214,
        bookName: 'Judges',
        chapter: 9,
        verse: 44,
        placeName: 'Shechem',
      ),
      CuratedWaypoint(
        title: "Cuts wood on Mount Zalmon for the tower's fire",
        year: -1214,
        bookName: 'Judges',
        chapter: 9,
        verse: 48,
        placeName: 'Mount Zalmon',
      ),
      CuratedWaypoint(
        title: 'Burns the tower of Shechem',
        year: -1214,
        bookName: 'Judges',
        chapter: 9,
        verse: 49,
        placeName: 'Tower of Shechem',
      ),
      CuratedWaypoint(
        title: 'Besieges and takes Thebez',
        year: -1214,
        bookName: 'Judges',
        chapter: 9,
        verse: 50,
        placeName: 'Thebez',
      ),
      CuratedWaypoint(
        title: 'Struck by a millstone and dies at Thebez',
        year: -1214,
        bookName: 'Judges',
        chapter: 9,
        verse: 54,
        placeName: 'Thebez',
      ),
    ],
  ),

  // Caleb's only bundled event, "Birth of Caleb" (Numbers 13:6), doesn't
  // resolve to any place at all — that verse is just his name in the spy
  // roster, with no place_verses link — so today his journey shows zero
  // waypoints, not even one wrong dot. Superseded entirely (added to
  // _eventsSupersededByCuratedJourney) and replaced with his two real,
  // well-documented episodes: the spy mission forty years before the
  // conquest, and his personal claim on Hebron after it. One override
  // needed: Numbers 13:22 also names Egypt and Zoan in a parenthetical
  // aside dating Hebron's founding, not the spies' actual location.
  CuratedPersonJourney(
    personSlug: 'caleb_537',
    waypoints: [
      CuratedWaypoint(
        title: 'Sent from Paran to spy out Canaan',
        year: -1445,
        bookName: 'Numbers',
        chapter: 13,
        verse: 3,
        placeName: 'Paran',
      ),
      CuratedWaypoint(
        title: 'Reaches Hebron and sees the sons of Anak',
        year: -1445,
        bookName: 'Numbers',
        chapter: 13,
        verse: 22,
        placeName: 'Hebron',
      ),
      CuratedWaypoint(
        title: 'Cuts a cluster of grapes in the Valley of Eshcol',
        year: -1445,
        bookName: 'Numbers',
        chapter: 13,
        verse: 23,
        placeName: 'Valley of Eshcol',
      ),
      CuratedWaypoint(
        title: 'Returns to Kadesh-barnea and urges Israel to advance',
        year: -1445,
        bookName: 'Numbers',
        chapter: 13,
        verse: 26,
        placeName: 'Kadesh-barnea',
      ),
      CuratedWaypoint(
        title: 'Comes to Joshua at Gilgal to claim his inheritance',
        year: -1405,
        bookName: 'Joshua',
        chapter: 14,
        verse: 6,
        placeName: 'Gilgal 1',
      ),
      CuratedWaypoint(
        title: 'Given Hebron for an inheritance',
        year: -1405,
        bookName: 'Joshua',
        chapter: 14,
        verse: 13,
        placeName: 'Hebron',
      ),
      CuratedWaypoint(
        title: 'Drives out the sons of Anak from Hebron',
        year: -1405,
        bookName: 'Joshua',
        chapter: 15,
        verse: 14,
        placeName: 'Hebron',
      ),
      CuratedWaypoint(
        title: 'Offers Achsah in marriage for the capture of Debir',
        year: -1405,
        bookName: 'Joshua',
        chapter: 15,
        verse: 15,
        placeName: 'Debir 1',
      ),
    ],
  ),

  // Moses already had a real multi-stop journey via auto-derivation (he has
  // 8 dated Theographic events, not just one), so he was never on the
  // single-dot priority list above — but two of those events are enormous
  // blobs that still collapse to a single dot each: "Exodus from Egypt" (223
  // verses, resolves to Egypt, where it starts) and "Wilderness Wanderings"
  // (142 verses, resolves to the Red Sea via an existing override). Both are
  // kept as their opening waypoint, and the real intermediate stops inside
  // each — already narrated, just never surfaced — are added here. Also see
  // the 'Death of Moses' fix in _eventPlaceOverrides above (Mount Nebo, not
  // Gilead). "Tabernacle Built" (301 verses) is left alone: it's
  // instructions, not travel, and Sinai really is the one location for all
  // of it.
  //
  // The years below use fractional values for the same reason explained on
  // [CuratedWaypoint.year]: "Exodus from Egypt", "Wilderness Wanderings", and
  // "Ten Commandments Given" all round to 1490 BC but have distinct
  // Theographic sortKeys within 0.0001 of each other, so stops that belong
  // between two of them need a year in that same narrow gap.
  CuratedPersonJourney(
    personSlug: 'moses_2108',
    waypoints: [
      CuratedWaypoint(
        title: 'Departs from Rameses',
        year: -1489.9799,
        bookName: 'Exodus',
        chapter: 12,
        verse: 37,
        placeName: 'Rameses',
      ),
      CuratedWaypoint(
        title: 'Arrives at Succoth',
        year: -1489.9799,
        bookName: 'Exodus',
        chapter: 12,
        verse: 37,
        placeName: 'Succoth 2',
      ),
      CuratedWaypoint(
        title: 'Camps at Etham on the edge of the wilderness',
        year: -1489.9799,
        bookName: 'Exodus',
        chapter: 13,
        verse: 20,
        placeName: 'Etham',
      ),
      CuratedWaypoint(
        title: 'Camps at Pi-hahiroth before crossing the Red Sea',
        year: -1489.97984,
        bookName: 'Exodus',
        chapter: 14,
        verse: 2,
        placeName: 'Pi-hahiroth',
      ),
      CuratedWaypoint(
        title: 'Passes through the wilderness of Shur',
        year: -1489.97984,
        bookName: 'Exodus',
        chapter: 15,
        verse: 22,
        placeName: 'Shur',
      ),
      CuratedWaypoint(
        title: 'Bitter water made sweet at Marah',
        year: -1489.97984,
        bookName: 'Exodus',
        chapter: 15,
        verse: 23,
        placeName: 'Marah',
      ),
      CuratedWaypoint(
        title: "Camps at Elim's twelve springs",
        year: -1489.97984,
        bookName: 'Exodus',
        chapter: 15,
        verse: 27,
        placeName: 'Elim',
      ),
      CuratedWaypoint(
        title: 'Manna given in the wilderness of Sin',
        year: -1489.97984,
        bookName: 'Exodus',
        chapter: 16,
        verse: 1,
        placeName: 'Sin',
      ),
      CuratedWaypoint(
        title: 'Water from the rock at Rephidim',
        year: -1489.97984,
        bookName: 'Exodus',
        chapter: 17,
        verse: 1,
        placeName: 'Rephidim',
      ),
    ],
  ),

  // Like Caleb, Esau's only bundled event ("Birth of Jacob and Esau",
  // Genesis 25:24-26) doesn't resolve to any place — those verses are just
  // the twins' birth notice, with no place_verses link. Superseded entirely.
  // Esau's own narrative is thinner on named locations than most of the
  // people curated so far: the birthright sale, the stolen blessing, and
  // both marriages all go unmentioned in places.json (no verse ties them to
  // anywhere), so only his later, more settled chapters are curatable — the
  // reconciliation with Jacob, burying Isaac, and his final move to Edom.
  // No overrides needed: every citation here ties singly, or (Genesis 35:27)
  // already resolves to the lower-id name for the same site.
  CuratedPersonJourney(
    personSlug: 'esau_1216',
    waypoints: [
      CuratedWaypoint(
        title: 'Reconciles with Jacob and returns to Seir',
        year: -1736,
        bookName: 'Genesis',
        chapter: 33,
        verse: 16,
        placeName: 'Mount Seir 1',
      ),
      CuratedWaypoint(
        title: 'Buries Isaac at Hebron with Jacob',
        year: -1715,
        bookName: 'Genesis',
        chapter: 35,
        verse: 27,
        placeName: 'Hebron',
      ),
      CuratedWaypoint(
        title: 'Departs Canaan for Edom',
        year: -1714,
        bookName: 'Genesis',
        chapter: 36,
        verse: 6,
        placeName: 'Canaan',
      ),
      CuratedWaypoint(
        title: 'Settles permanently in Mount Seir',
        year: -1714,
        bookName: 'Genesis',
        chapter: 36,
        verse: 8,
        placeName: 'Mount Seir 1',
      ),
    ],
  ),

  // Benjamin's only bundled event, "Rachel dies giving birth to Benjamin"
  // (Genesis 35:16-27), already had a false-positive bug of its own — fixed
  // above in _eventPlaceOverrides (Ephrath, not Bethel, the place they'd
  // just left) — and is kept as the opening waypoint. His own adult
  // narrative is otherwise thin on named locations: he's a background
  // figure in Joseph's story, mostly acted upon rather than acting, and
  // most of the scenes naming him (Joseph embracing him, the silver cup
  // planted in his sack) have no place_verses link. The one clean exception
  // is Genesis 43:15, which names him personally among those who "went down
  // to Egypt" on the second trip — the one his brothers wouldn't make
  // without him.
  CuratedPersonJourney(
    personSlug: 'benjamin_463',
    waypoints: [
      CuratedWaypoint(
        title: 'Brought down to Egypt to appear before Joseph',
        year: -1705,
        bookName: 'Genesis',
        chapter: 43,
        verse: 15,
        placeName: 'Egypt',
      ),
    ],
  ),

  // Jacob has zero dated events in the bundled Theographic data at all — not
  // a wrong dot, not a single dot, nothing — despite having one of the most
  // location-rich narratives in Genesis. Found during a review prompted by
  // the user asking whether Moses's places were complete; this isn't part
  // of the original single-dot priority list (there was no dot to begin
  // with), but the same curation process applies. Three overrides needed,
  // all the same landmark/retrospective-reference pattern documented
  // elsewhere in this file.
  CuratedPersonJourney(
    personSlug: 'jacob_683',
    waypoints: [
      CuratedWaypoint(
        title: 'Departs from Beersheba toward Haran',
        year: -1758,
        bookName: 'Genesis',
        chapter: 28,
        verse: 10,
        placeName: 'Beersheba 2',
      ),
      CuratedWaypoint(
        title: 'Dreams of the ladder at Bethel',
        year: -1758,
        bookName: 'Genesis',
        chapter: 28,
        verse: 19,
        placeName: 'Bethel 1',
      ),
      CuratedWaypoint(
        title: 'Arrives in Haran and meets Rachel at the well',
        year: -1757,
        bookName: 'Genesis',
        chapter: 29,
        verse: 4,
        placeName: 'Haran',
      ),
      CuratedWaypoint(
        title: 'Flees toward Gilead, overtaken by Laban',
        year: -1737,
        bookName: 'Genesis',
        chapter: 31,
        verse: 25,
        placeName: 'Gilead 1',
      ),
      CuratedWaypoint(
        title: 'Encounters angels at Mahanaim',
        year: -1736,
        bookName: 'Genesis',
        chapter: 32,
        verse: 2,
        placeName: 'Mahanaim',
      ),
      CuratedWaypoint(
        title: 'Crosses the ford of Jabbok',
        year: -1736,
        bookName: 'Genesis',
        chapter: 32,
        verse: 22,
        placeName: 'Jabbok',
      ),
      CuratedWaypoint(
        title: 'Wrestles with the angel and is renamed Israel at Penuel',
        year: -1736,
        bookName: 'Genesis',
        chapter: 32,
        verse: 30,
        placeName: 'Penuel',
      ),
      CuratedWaypoint(
        title: 'Builds a house at Succoth',
        year: -1736,
        bookName: 'Genesis',
        chapter: 33,
        verse: 17,
        placeName: 'Succoth 1',
      ),
      CuratedWaypoint(
        title: 'Comes to Shechem and pitches his tent',
        year: -1736,
        bookName: 'Genesis',
        chapter: 33,
        verse: 18,
        placeName: 'Shechem',
      ),
      CuratedWaypoint(
        title: 'Returns to Bethel at God\'s command',
        year: -1720,
        bookName: 'Genesis',
        chapter: 35,
        verse: 1,
        placeName: 'Bethel 1',
      ),
      CuratedWaypoint(
        title: 'Rachel dies near Ephrath giving birth to Benjamin',
        year: -1719,
        bookName: 'Genesis',
        chapter: 35,
        verse: 16,
        placeName: 'Ephrath',
      ),
      CuratedWaypoint(
        title: 'Reunites with Isaac at Hebron before his death',
        year: -1715,
        bookName: 'Genesis',
        chapter: 35,
        verse: 27,
        placeName: 'Hebron',
      ),
      CuratedWaypoint(
        title: 'Stops at Beersheba to sacrifice before going to Egypt',
        year: -1705,
        bookName: 'Genesis',
        chapter: 46,
        verse: 1,
        placeName: 'Beersheba 2',
      ),
      CuratedWaypoint(
        title: 'Reunited with Joseph in Goshen',
        year: -1705,
        bookName: 'Genesis',
        chapter: 46,
        verse: 29,
        placeName: 'Goshen 1',
      ),
      CuratedWaypoint(
        title: 'Embalmed and buried at Machpelah near Hebron',
        year: -1688,
        bookName: 'Genesis',
        chapter: 50,
        verse: 13,
        placeName: 'Machpelah',
      ),
    ],
  ),

  // Unlike everyone else in this file, Jesus already has a rich, mostly
  // auto-derived journey (100+ dated events) — his early ministry doesn't
  // need curation. But Theographic leaves the entire Passion Week and
  // everything after it *undated* (no `y`/start_year at all on "Triumphal
  // Entry", "The Last Supper", "Crucifixion and Burial", etc.), so
  // personJourneyProvider's dated-events-only resolution silently drops all
  // of it — the most geographically significant week of his life shows
  // nothing on the map today. These waypoints fill that gap.
  //
  // Years: 30.45-30.484, deliberately placed *after* every existing dated
  // event for Jesus (highest existing `k`/sortKey is 30.44001006, "Jesus
  // ascends to Heaven") but still under 30.5 so they round to year 30, not
  // 31, in the UI. Theographic's own sortKey isn't true calendar
  // time — it's `book.chapter.verse` encoded as a decimal, so events cited
  // from different Gospels covering the same week don't interleave
  // correctly (e.g. "Lazarus Raised" (John 11, k=30.43011) already sorts
  // *after* "Resurrection and Ascension" (Matthew 28, k=30.40028) today,
  // even though it narratively happens weeks earlier — a pre-existing
  // quirk, not something introduced here). Rather than fight that scheme,
  // this whole block sorts as one unit after everything else; it's
  // internally in the correct order, just not perfectly threaded between
  // the handful of already-out-of-order late-ministry events that precede
  // it (Zaccheus, Lazarus, the Ephraim withdrawal).
  //
  // Deliberately excluded for lack of a citation naming *his* location:
  // Judas's suicide at Akeldama (that's Judas's location, not Jesus's, and
  // Jesus was elsewhere on trial at the same time), the Jewish trial before
  // Caiaphas (its only place-tagged verses are about Peter being recognized
  // as a Galilean, not Jesus), and the specific burial site (no verse ties
  // the garden tomb itself to a place — it's folded into the Golgotha stop).
  //
  // The nativity has the same cross-Gospel sort-key quirk described above,
  // and it's visible rather than cosmetic: Theographic's "Birth of Jesus"
  // (Luke 2, k=-2.57997999) sorts *after* its own "Joseph and Mary return
  // from Egypt" (Matthew 2, k=-2.59997981) and "...return to Nazareth"
  // (k=-2.59997978), purely because Matthew is book 39 and Luke is book 41 —
  // the map showed the Egypt trip before the Bethlehem birth. The two
  // Matthew-sourced events are superseded here (see
  // _eventsSupersededByCuratedJourney in atlas_providers.dart) and replaced
  // with waypoints dated just after "Childhood of Jesus" (Luke 2:40,
  // k=-2.5799796), the last of the Luke-sourced birth/circumcision/
  // presentation sequence. "...return to Nazareth" also gets its true
  // destination here instead of Theographic's own resolution: its cited
  // verses are Matthew 2:22-23, and 2:22 (Galilee/Judea, the region they
  // feared, not their destination) sorts ahead of 2:23's Nazareth by ord.
  CuratedPersonJourney(
    personSlug: 'jesus_905',
    waypoints: [
      CuratedWaypoint(
        // Deliberately distinct from Theographic's own "Joseph and Mary
        // return from Egypt" title (see _eventsSupersededByCuratedJourney) —
        // CuratedJourneysImporter treats an exact title match as "already
        // inserted" and skips writing a fresh sortKey, so reusing that title
        // here would silently keep the old, wrongly-ordered row instead of
        // replacing it.
        title: "Returns from Egypt after Herod's death",
        year: -2.55,
        bookName: 'Matthew',
        chapter: 2,
        verse: 20,
        placeName: 'Egypt',
      ),
      CuratedWaypoint(
        title: 'Settles with the family in Nazareth',
        year: -2.54,
        bookName: 'Matthew',
        chapter: 2,
        verse: 23,
        placeName: 'Nazareth',
      ),
      CuratedWaypoint(
        title: 'Anointed by Mary at Bethany six days before Passover',
        year: 30.45,
        bookName: 'John',
        chapter: 12,
        verse: 1,
        placeName: 'Bethany 1',
      ),
      CuratedWaypoint(
        title: 'Sends two disciples ahead from Bethphage',
        year: 30.452,
        bookName: 'Matthew',
        chapter: 21,
        verse: 1,
        placeName: 'Bethphage',
      ),
      CuratedWaypoint(
        title: 'Triumphal Entry into Jerusalem',
        year: 30.454,
        bookName: 'Matthew',
        chapter: 21,
        verse: 10,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Curses the fig tree leaving Bethany',
        year: 30.456,
        bookName: 'Mark',
        chapter: 11,
        verse: 12,
        placeName: 'Bethany 1',
      ),
      CuratedWaypoint(
        title: 'Cleanses the Temple',
        year: 30.458,
        bookName: 'Mark',
        chapter: 11,
        verse: 15,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Debates the religious leaders in the Temple',
        year: 30.46,
        bookName: 'Mark',
        chapter: 11,
        verse: 27,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Olivet Discourse on the Mount of Olives',
        year: 30.462,
        bookName: 'Matthew',
        chapter: 24,
        verse: 3,
        placeName: 'Mount of Olives',
      ),
      CuratedWaypoint(
        title: 'Prepares the Passover and eats the Last Supper in Jerusalem',
        year: 30.464,
        bookName: 'Mark',
        chapter: 14,
        verse: 13,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Departs after supper for the Mount of Olives',
        year: 30.466,
        bookName: 'Matthew',
        chapter: 26,
        verse: 30,
        placeName: 'Mount of Olives',
      ),
      CuratedWaypoint(
        title: 'Prays and is betrayed in Gethsemane',
        year: 30.468,
        bookName: 'Matthew',
        chapter: 26,
        verse: 36,
        placeName: 'Gethsemane',
      ),
      CuratedWaypoint(
        title: 'Sent to Herod at Jerusalem',
        year: 30.47,
        bookName: 'Luke',
        chapter: 23,
        verse: 7,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: "Condemned by Pilate at the Pavement",
        year: 30.472,
        bookName: 'John',
        chapter: 19,
        verse: 13,
        placeName: 'Gabbatha',
      ),
      CuratedWaypoint(
        title: 'Crucified at Golgotha',
        year: 30.474,
        bookName: 'Luke',
        chapter: 23,
        verse: 33,
        placeName: 'Golgotha',
      ),
      CuratedWaypoint(
        title: 'Risen Jesus meets two disciples on the road to Emmaus',
        year: 30.476,
        bookName: 'Luke',
        chapter: 24,
        verse: 13,
        placeName: 'Emmaus',
      ),
      CuratedWaypoint(
        title: 'Returns to Jerusalem and appears to the disciples',
        year: 30.478,
        bookName: 'Luke',
        chapter: 24,
        verse: 33,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Appears to the disciples in Galilee',
        year: 30.48,
        bookName: 'Matthew',
        chapter: 28,
        verse: 16,
        placeName: 'Galilee 1',
      ),
      CuratedWaypoint(
        title: 'Commands the apostles to wait in Jerusalem',
        year: 30.482,
        bookName: 'Acts',
        chapter: 1,
        verse: 4,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Ascends to heaven from Bethany',
        year: 30.484,
        bookName: 'Luke',
        chapter: 24,
        verse: 50,
        placeName: 'Bethany 1',
      ),
    ],
  ),

  CuratedPersonJourney(
    personSlug: 'paul_2479',
    waypoints: [
      CuratedWaypoint(
        title: 'Conversion on the road to Damascus',
        year: 32.1,
        bookName: 'Acts',
        chapter: 9,
        verse: 3,
        placeName: 'Damascus',
      ),
      CuratedWaypoint(
        title: 'Retreat to Arabia',
        year: 34.0,
        bookName: 'Galatians',
        chapter: 1,
        verse: 17,
        placeName: 'Arabia 2',
      ),
      CuratedWaypoint(
        title: 'Meets with the Apostles in Jerusalem',
        year: 35.0,
        bookName: 'Acts',
        chapter: 9,
        verse: 26,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Returns to hometown of Tarsus',
        year: 35.5,
        bookName: 'Acts',
        chapter: 9,
        verse: 30,
        placeName: 'Tarsus',
      ),
      CuratedWaypoint(
        title: 'Brought by Barnabas to Antioch',
        year: 40.0,
        bookName: 'Acts',
        chapter: 11,
        verse: 26,
        placeName: 'Antioch 1',
      ),
      CuratedWaypoint(
        title: 'First Journey: Preaches in Salamis',
        year: 45.0,
        bookName: 'Acts',
        chapter: 13,
        verse: 5,
        placeName: 'Salamis',
      ),
      CuratedWaypoint(
        title: 'First Journey: Confronts Elymas in Paphos',
        year: 45.1,
        bookName: 'Acts',
        chapter: 13,
        verse: 6,
        placeName: 'Paphos',
      ),
      CuratedWaypoint(
        title: 'First Journey: Arrives in Perga',
        year: 45.2,
        bookName: 'Acts',
        chapter: 13,
        verse: 13,
        placeName: 'Perga',
      ),
      CuratedWaypoint(
        title: 'First Journey: Preaches in Pisidian Antioch',
        year: 45.3,
        bookName: 'Acts',
        chapter: 13,
        verse: 14,
        placeName: 'Antioch 2',
      ),
      CuratedWaypoint(
        title: 'First Journey: Flees to Iconium',
        year: 45.4,
        bookName: 'Acts',
        chapter: 13,
        verse: 51,
        placeName: 'Iconium',
      ),
      CuratedWaypoint(
        title: 'First Journey: Heals a cripple in Lystra',
        year: 45.5,
        bookName: 'Acts',
        chapter: 14,
        verse: 6,
        placeName: 'Lystra',
      ),
      CuratedWaypoint(
        title: 'First Journey: Preaches in Derbe',
        year: 45.6,
        bookName: 'Acts',
        chapter: 14,
        verse: 20,
        placeName: 'Derbe',
      ),
      CuratedWaypoint(
        title: 'First Journey: Departs from Attalia',
        year: 45.7,
        bookName: 'Acts',
        chapter: 14,
        verse: 25,
        placeName: 'Attalia',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Travels through Syria and Cilicia',
        year: 46.0,
        bookName: 'Acts',
        chapter: 15,
        verse: 41,
        placeName: 'Syria 2',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Meets Timothy in Derbe',
        year: 46.1,
        bookName: 'Acts',
        chapter: 16,
        verse: 1,
        placeName: 'Derbe',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Returns to Lystra',
        year: 46.2,
        bookName: 'Acts',
        chapter: 16,
        verse: 1,
        placeName: 'Lystra',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Travels through Phrygia',
        year: 46.3,
        bookName: 'Acts',
        chapter: 16,
        verse: 6,
        placeName: 'Phrygia',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Travels through Galatia',
        year: 46.4,
        bookName: 'Acts',
        chapter: 16,
        verse: 6,
        placeName: 'Galatia',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Macedonian call in Troas',
        year: 46.5,
        bookName: 'Acts',
        chapter: 16,
        verse: 8,
        placeName: 'Troas',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Arrives in Neapolis',
        year: 46.6,
        bookName: 'Acts',
        chapter: 16,
        verse: 11,
        placeName: 'Neapolis',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Imprisoned in Philippi',
        year: 47.0,
        bookName: 'Acts',
        chapter: 16,
        verse: 19,
        placeName: 'Philippi',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Passes through Amphipolis',
        year: 47.1,
        bookName: 'Acts',
        chapter: 17,
        verse: 1,
        placeName: 'Amphipolis',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Passes through Apollonia',
        year: 47.2,
        bookName: 'Acts',
        chapter: 17,
        verse: 1,
        placeName: 'Apollonia',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Uproar in Thessalonica',
        year: 47.3,
        bookName: 'Acts',
        chapter: 17,
        verse: 1,
        placeName: 'Thessalonica',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Preaches in Berea',
        year: 47.4,
        bookName: 'Acts',
        chapter: 17,
        verse: 10,
        placeName: 'Berea',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Address at the Areopagus in Athens',
        year: 48.0,
        bookName: 'Acts',
        chapter: 17,
        verse: 15,
        placeName: 'Athens',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Stays a year and a half in Corinth',
        year: 48.1,
        bookName: 'Acts',
        chapter: 18,
        verse: 1,
        placeName: 'Corinth',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Departs from Cenchreae',
        year: 49.0,
        bookName: 'Acts',
        chapter: 18,
        verse: 18,
        placeName: 'Cenchreae',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Stops in Ephesus',
        year: 49.1,
        bookName: 'Acts',
        chapter: 18,
        verse: 19,
        placeName: 'Ephesus',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Lands at Caesarea',
        year: 49.2,
        bookName: 'Acts',
        chapter: 18,
        verse: 22,
        placeName: 'Caesarea',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Greets the church in Jerusalem',
        year: 49.3,
        bookName: 'Acts',
        chapter: 18,
        verse: 22,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Returns to Antioch',
        year: 49.4,
        bookName: 'Acts',
        chapter: 18,
        verse: 22,
        placeName: 'Antioch 1',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Strengthens disciples in Galatia',
        year: 50.0,
        bookName: 'Acts',
        chapter: 18,
        verse: 23,
        placeName: 'Galatia',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Three years in Ephesus',
        year: 50.1,
        bookName: 'Acts',
        chapter: 19,
        verse: 1,
        placeName: 'Ephesus',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Travels through Macedonia',
        year: 53.0,
        bookName: 'Acts',
        chapter: 20,
        verse: 1,
        placeName: 'Macedonia',
      ),
      // Acts 20:2 only names "Greece", and places.json ties that verse to the
      // Greece pin, not Corinth (they're ~60km apart) — but Paul's own bundled
      // bio (theographic.json's person entry) reads this stop as "spending
      // probably the greater part of this time in Corinth (Acts 20:2)", which
      // also matches his prior year-and-a-half stay there (Acts 18:1 above).
      // Deliberately overriding the raw tie for that reading.
      CuratedWaypoint(
        title: 'Third Journey: Three months in Greece',
        year: 53.1,
        bookName: 'Acts',
        chapter: 20,
        verse: 2,
        placeName: 'Corinth',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Sails from Philippi',
        year: 53.2,
        bookName: 'Acts',
        chapter: 20,
        verse: 6,
        placeName: 'Philippi',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Revives Eutychus in Troas',
        year: 53.3,
        bookName: 'Acts',
        chapter: 20,
        verse: 6,
        placeName: 'Troas',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Walks to Assos',
        year: 53.4,
        bookName: 'Acts',
        chapter: 20,
        verse: 13,
        placeName: 'Assos',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Sails to Mitylene',
        year: 53.5,
        bookName: 'Acts',
        chapter: 20,
        verse: 14,
        placeName: 'Mitylene',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Anchors at Chios',
        year: 53.6,
        bookName: 'Acts',
        chapter: 20,
        verse: 15,
        placeName: 'Chios',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Crosses to Samos',
        year: 53.7,
        bookName: 'Acts',
        chapter: 20,
        verse: 15,
        placeName: 'Samos',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Meets Ephesian elders in Miletus',
        year: 54.0,
        bookName: 'Acts',
        chapter: 20,
        verse: 15,
        placeName: 'Miletus',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Sails to Cos',
        year: 54.1,
        bookName: 'Acts',
        chapter: 21,
        verse: 1,
        placeName: 'Cos',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Sails to Rhodes',
        year: 54.2,
        bookName: 'Acts',
        chapter: 21,
        verse: 1,
        placeName: 'Rhodes 1',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Sails to Patara',
        year: 54.3,
        bookName: 'Acts',
        chapter: 21,
        verse: 1,
        placeName: 'Patara',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Seven days in Tyre',
        year: 54.4,
        bookName: 'Acts',
        chapter: 21,
        verse: 3,
        placeName: 'Tyre',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Greets the brothers in Ptolemais',
        year: 54.5,
        bookName: 'Acts',
        chapter: 21,
        verse: 7,
        placeName: 'Ptolemais',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Stays with Philip in Caesarea',
        year: 54.6,
        bookName: 'Acts',
        chapter: 21,
        verse: 8,
        placeName: 'Caesarea',
      ),
      CuratedWaypoint(
        title: 'Third Journey: Arrested in Jerusalem',
        year: 54.7,
        bookName: 'Acts',
        chapter: 21,
        verse: 15,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Permitted to see friends in Sidon',
        year: 56.0,
        bookName: 'Acts',
        chapter: 27,
        verse: 3,
        placeName: 'Sidon',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Changes ships in Myra',
        year: 56.1,
        bookName: 'Acts',
        chapter: 27,
        verse: 5,
        placeName: 'Myra',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Arrives at Fair Havens',
        year: 56.2,
        bookName: 'Acts',
        chapter: 27,
        verse: 8,
        placeName: 'Fair Havens',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Shipwrecked on Malta',
        year: 57.0,
        bookName: 'Acts',
        chapter: 28,
        verse: 1,
        placeName: 'Malta',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Stays three days in Syracuse',
        year: 57.1,
        bookName: 'Acts',
        chapter: 28,
        verse: 12,
        placeName: 'Syracuse',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Reaches Rhegium',
        year: 57.2,
        bookName: 'Acts',
        chapter: 28,
        verse: 13,
        placeName: 'Rhegium',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Finds brothers in Puteoli',
        year: 57.3,
        bookName: 'Acts',
        chapter: 28,
        verse: 13,
        placeName: 'Puteoli',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Met by brothers at Forum of Appius',
        year: 57.4,
        bookName: 'Acts',
        chapter: 28,
        verse: 15,
        placeName: 'Forum of Appius',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Met by brothers at Three Taverns',
        year: 57.5,
        bookName: 'Acts',
        chapter: 28,
        verse: 15,
        placeName: 'Three Taverns',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Under house arrest in Rome',
        year: 57.6,
        bookName: 'Acts',
        chapter: 28,
        verse: 16,
        placeName: 'Rome',
      ),
    ],
  ),
  CuratedPersonJourney(
    personSlug: 'peter_2745',
    waypoints: [
      CuratedWaypoint(
        title: 'Called by Jesus at the Sea of Galilee',
        year: 27.0,
        bookName: 'Matthew',
        chapter: 4,
        verse: 18,
        placeName: 'Sea of Galilee',
      ),
      CuratedWaypoint(
        title: 'Confesses Jesus as the Christ at Caesarea Philippi',
        year: 29.0,
        bookName: 'Matthew',
        chapter: 16,
        verse: 13,
        placeName: 'Caesarea Philippi',
      ),
      CuratedWaypoint(
        title: 'Preaches at Pentecost in Jerusalem',
        year: 30.5,
        bookName: 'Acts',
        chapter: 2,
        verse: 14,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Goes to Samaria to pray for new believers',
        year: 32.0,
        bookName: 'Acts',
        chapter: 8,
        verse: 14,
        placeName: 'Samaria 1',
      ),
      CuratedWaypoint(
        title: 'Heals Aeneas at Lydda',
        year: 37.0,
        bookName: 'Acts',
        chapter: 9,
        verse: 32,
        placeName: 'Lod',
      ),
      CuratedWaypoint(
        title: 'Raises Dorcas from the dead at Joppa',
        year: 37.1,
        bookName: 'Acts',
        chapter: 9,
        verse: 38,
        placeName: 'Joppa',
      ),
      CuratedWaypoint(
        title: 'Preaches to Cornelius in Caesarea',
        year: 38.0,
        bookName: 'Acts',
        chapter: 10,
        verse: 24,
        placeName: 'Caesarea',
      ),
      CuratedWaypoint(
        title: 'Imprisoned and miraculously released in Jerusalem',
        year: 44.0,
        bookName: 'Acts',
        chapter: 12,
        verse: 3,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Attends the Jerusalem Council',
        year: 49.0,
        bookName: 'Acts',
        chapter: 15,
        verse: 7,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Visits Antioch (confronted by Paul)',
        year: 49.5,
        bookName: 'Galatians',
        chapter: 2,
        verse: 11,
        placeName: 'Antioch 1',
      ),
      // Note: 1 Peter 5:13 mentions "Babylon". Nearly all scholars recognize this as a
      // cryptogram for Rome, as literal Babylon was largely desolate and all early 
      // church tradition places Peter in Rome at the end of his life.
      CuratedWaypoint(
        title: 'Writes his epistle from Rome (referred to as Babylon)',
        year: 62.0,
        bookName: '1 Peter',
        chapter: 5,
        verse: 13,
        placeName: 'Rome',
      ),
    ],
  ),

  // Paul's Companions

  // Barnabas
  CuratedPersonJourney(
    personSlug: 'barnabas_1722',
    waypoints: [
      CuratedWaypoint(
        title: 'Introduced in Jerusalem',
        year: 30.6,
        bookName: 'Acts',
        chapter: 4,
        verse: 36,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Sent to Antioch to investigate the church',
        year: 40.0,
        bookName: 'Acts',
        chapter: 11,
        verse: 22,
        placeName: 'Antioch 1',
      ),
      CuratedWaypoint(
        title: 'Goes to Tarsus to look for Saul',
        year: 40.1,
        bookName: 'Acts',
        chapter: 11,
        verse: 25,
        placeName: 'Tarsus',
      ),
      CuratedWaypoint(
        title: 'Brings Saul back to Antioch',
        year: 40.2,
        bookName: 'Acts',
        chapter: 11,
        verse: 26,
        placeName: 'Antioch 1',
      ),
      CuratedWaypoint(
        title: 'Brings famine relief to Judea',
        year: 44.0,
        bookName: 'Acts',
        chapter: 11,
        verse: 30,
        placeName: 'Judea 1', // or Jerusalem
      ),
      // Matches Paul's First Journey (45.0 - 45.7)
      CuratedWaypoint(
        title: 'First Journey: Preaches in Salamis',
        year: 45.0,
        bookName: 'Acts',
        chapter: 13,
        verse: 5,
        placeName: 'Salamis',
      ),
      CuratedWaypoint(
        title: 'First Journey: Confronts Elymas in Paphos',
        year: 45.1,
        bookName: 'Acts',
        chapter: 13,
        verse: 6,
        placeName: 'Paphos',
      ),
      CuratedWaypoint(
        title: 'First Journey: Arrives in Perga',
        year: 45.2,
        bookName: 'Acts',
        chapter: 13,
        verse: 13,
        placeName: 'Perga',
      ),
      CuratedWaypoint(
        title: 'First Journey: Preaches in Pisidian Antioch',
        year: 45.3,
        bookName: 'Acts',
        chapter: 13,
        verse: 14,
        placeName: 'Antioch 2',
      ),
      CuratedWaypoint(
        title: 'First Journey: Flees to Iconium',
        year: 45.4,
        bookName: 'Acts',
        chapter: 13,
        verse: 51,
        placeName: 'Iconium',
      ),
      CuratedWaypoint(
        title: 'First Journey: Called Zeus in Lystra',
        year: 45.5,
        bookName: 'Acts',
        chapter: 14,
        verse: 12,
        placeName: 'Lystra',
      ),
      CuratedWaypoint(
        title: 'First Journey: Preaches in Derbe',
        year: 45.6,
        bookName: 'Acts',
        chapter: 14,
        verse: 20,
        placeName: 'Derbe',
      ),
      CuratedWaypoint(
        title: 'First Journey: Departs from Attalia',
        year: 45.7,
        bookName: 'Acts',
        chapter: 14,
        verse: 25,
        placeName: 'Attalia',
      ),
      // Same title/citation as Peter's waypoint below — this is the same
      // single Council event, not a distinct one, so it's deliberately
      // shared (same pattern as Paul/Silas's Second Journey stops): the
      // importer merges same-titled waypoints into one timeline_events row
      // with both as participants, rather than two near-duplicate "Council"
      // entries on the Jerusalem place page.
      CuratedWaypoint(
        title: 'Attends the Jerusalem Council',
        year: 49.0,
        bookName: 'Acts',
        chapter: 15,
        verse: 7,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Sails to Cyprus with Mark',
        year: 49.1,
        bookName: 'Acts',
        chapter: 15,
        verse: 39,
        placeName: 'Cyprus',
      ),
    ],
  ),

  // Silas
  CuratedPersonJourney(
    personSlug: 'silas_2740',
    waypoints: [
      // Real-world scholarly dating puts the Council around AD 49, after
      // Paul's internal numbering (below) already reaches 46.0-48.1 for the
      // Second Journey that follows it — Paul's curated journey compresses
      // that gap rather than tracking absolute years. Using 49.0/49.1 here
      // (Silas's actual introduction) would sort *after* his own Second
      // Journey stops and play his path backwards, so these two are
      // renumbered just ahead of 46.0 to keep Silas's own journey in true
      // chronological order; the Second Journey stops below still line up
      // with Paul's numbering.
      CuratedWaypoint(
        title: 'Introduced at the Jerusalem Council',
        year: 45.8,
        bookName: 'Acts',
        chapter: 15,
        verse: 22,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Sent to Antioch with the council\'s letter',
        year: 45.9,
        bookName: 'Acts',
        chapter: 15,
        verse: 30,
        placeName: 'Antioch 1',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Travels through Syria and Cilicia',
        year: 46.0,
        bookName: 'Acts',
        chapter: 15,
        verse: 41,
        placeName: 'Syria 2',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Arrives in Neapolis',
        year: 46.6,
        bookName: 'Acts',
        chapter: 16,
        verse: 11,
        placeName: 'Neapolis',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Imprisoned in Philippi',
        year: 47.0,
        bookName: 'Acts',
        chapter: 16,
        verse: 19,
        placeName: 'Philippi',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Uproar in Thessalonica',
        year: 47.3,
        bookName: 'Acts',
        chapter: 17,
        verse: 1,
        placeName: 'Thessalonica',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Stays in Berea',
        year: 47.4,
        bookName: 'Acts',
        chapter: 17,
        verse: 14,
        placeName: 'Berea',
      ),
      CuratedWaypoint(
        title: 'Second Journey: Rejoins Paul in Corinth',
        year: 48.1, // Matches Paul's Corinth stay
        bookName: 'Acts',
        chapter: 18,
        verse: 5,
        placeName: 'Corinth',
      ),
    ],
  ),

  // Timothy
  CuratedPersonJourney(
    personSlug: 'timotheus_2863',
    waypoints: [
      CuratedWaypoint(
        title: 'Joins Paul in Lystra',
        year: 46.1, // Follows Paul's timeline
        bookName: 'Acts',
        chapter: 16,
        verse: 1,
        placeName: 'Lystra',
      ),
      // Timothy's presence at Philippi is inferred: Acts 16:3 says Paul took
      // him along, and 16:12 says "we" arrived in Philippi, but the "we"
      // narrator is Luke. Timothy isn't named again until 17:14 (Berea).
      CuratedWaypoint(
        title: 'Travels to Philippi',
        year: 47.0,
        bookName: 'Acts',
        chapter: 16,
        verse: 12,
        placeName: 'Philippi', // Inferred from Acts 16:3 "took him along"
      ),
      CuratedWaypoint(
        title: 'Stays in Berea with Silas',
        year: 47.4,
        bookName: 'Acts',
        chapter: 17,
        verse: 14,
        placeName: 'Berea',
      ),
      CuratedWaypoint(
        title: 'Rejoins Paul in Corinth',
        year: 48.1,
        bookName: 'Acts',
        chapter: 18,
        verse: 5,
        placeName: 'Corinth',
      ),
      CuratedWaypoint(
        title: 'Sent from Ephesus to Macedonia',
        year: 52.0,
        bookName: 'Acts',
        chapter: 19,
        verse: 22,
        placeName: 'Macedonia',
      ),
      CuratedWaypoint(
        title: 'Accompanies Paul to Troas',
        year: 53.3,
        bookName: 'Acts',
        chapter: 20,
        verse: 5,
        placeName: 'Troas',
      ),
      // Colossians 1:1 names Timothy as co-sender. Traditionally the letter
      // was written from Rome during Paul's first imprisonment (Acts 28:16-31),
      // though Ephesus and Caesarea have also been proposed. Using the majority
      // scholarly view (Rome).
      CuratedWaypoint(
        title: 'With Paul in Rome (co-sender of Colossians)',
        year: 60.0,
        bookName: 'Colossians',
        chapter: 1,
        verse: 1,
        placeName: 'Rome', // Traditional: written from Rome during Acts 28 imprisonment
      ),
    ],
  ),

  // Luke
  // Note: Luke is inferred via "we" passages in Acts
  CuratedPersonJourney(
    personSlug: 'luke_1836',
    waypoints: [
      CuratedWaypoint(
        title: 'Joins Paul in Troas (first "we" passage)',
        year: 46.5,
        bookName: 'Acts',
        chapter: 16,
        verse: 10,
        placeName: 'Troas',
      ),
      CuratedWaypoint(
        title: 'Travels to Philippi',
        year: 47.0,
        bookName: 'Acts',
        chapter: 16,
        verse: 12,
        placeName: 'Philippi',
      ),
      CuratedWaypoint(
        title: 'Rejoins Paul leaving Philippi',
        year: 53.2,
        bookName: 'Acts',
        chapter: 20,
        verse: 6,
        placeName: 'Philippi',
      ),
      CuratedWaypoint(
        title: 'Meets Ephesian elders in Miletus',
        year: 54.0,
        bookName: 'Acts',
        chapter: 20,
        verse: 15,
        placeName: 'Miletus',
      ),
      CuratedWaypoint(
        title: 'Arrives in Jerusalem',
        year: 54.7,
        bookName: 'Acts',
        chapter: 21,
        verse: 15,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Sails from Caesarea',
        year: 56.0,
        bookName: 'Acts',
        chapter: 27,
        verse: 1,
        placeName: 'Caesarea', // Inferred starting point
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Shipwrecked on Malta',
        year: 57.0,
        bookName: 'Acts',
        chapter: 28,
        verse: 1,
        placeName: 'Malta',
      ),
      CuratedWaypoint(
        title: 'Journey to Rome: Arrives in Rome',
        year: 57.6,
        bookName: 'Acts',
        chapter: 28,
        verse: 16,
        placeName: 'Rome',
      ),
    ],
  ),

  // Philip the Evangelist
  CuratedPersonJourney(
    personSlug: 'philip_2347', // Verified: Acts 6:5 — one of the seven
    waypoints: [
      CuratedWaypoint(
        title: 'Chosen as one of the seven in Jerusalem',
        year: 32.0,
        bookName: 'Acts',
        chapter: 6,
        verse: 5,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Preaches in Samaria',
        year: 33.0,
        bookName: 'Acts',
        chapter: 8,
        verse: 5,
        placeName: 'Samaria 1',
      ),
      CuratedWaypoint(
        title: 'Meets the Ethiopian eunuch on the road to Gaza',
        year: 33.1,
        bookName: 'Acts',
        chapter: 8,
        verse: 26,
        placeName: 'Gaza',
      ),
      CuratedWaypoint(
        title: 'Found at Azotus',
        year: 33.2,
        bookName: 'Acts',
        chapter: 8,
        verse: 40,
        placeName: 'Ashdod',
      ),
      CuratedWaypoint(
        title: 'Preaches in all the towns until he reaches Caesarea',
        year: 33.3,
        bookName: 'Acts',
        chapter: 8,
        verse: 40,
        placeName: 'Caesarea',
      ),
      CuratedWaypoint(
        title: 'Hosts Paul in Caesarea',
        year: 54.6, // Matches Paul's timeline
        bookName: 'Acts',
        chapter: 21,
        verse: 8,
        placeName: 'Caesarea',
      ),
    ],
  ),

  CuratedPersonJourney(
    personSlug: 'joshua_893',
    waypoints: [
      CuratedWaypoint(
        title: 'Fights Amalek at Rephidim',
        year: -1489,
        bookName: 'Exodus',
        chapter: 17,
        verse: 9,
        placeName: 'Rephidim',
      ),
      CuratedWaypoint(
        title: 'Ascends Mount Sinai with Moses',
        year: -1489,
        bookName: 'Exodus',
        chapter: 24,
        verse: 13,
        placeName: 'Mount Sinai',
      ),
      CuratedWaypoint(
        title: 'Spies out the land from Kadesh-barnea',
        year: -1445,
        bookName: 'Numbers',
        chapter: 13,
        verse: 26,
        placeName: 'Kadesh-barnea',
      ),
      CuratedWaypoint(
        title: 'Camps at Shittim before crossing',
        year: -1405,
        bookName: 'Joshua',
        chapter: 2,
        verse: 1,
        placeName: 'Shittim',
      ),
      CuratedWaypoint(
        title: 'Crosses the Jordan River',
        year: -1405,
        bookName: 'Joshua',
        chapter: 3,
        verse: 1,
        placeName: 'Jordan',
      ),
      CuratedWaypoint(
        title: 'Sets up memorial stones at Gilgal',
        year: -1405,
        bookName: 'Joshua',
        chapter: 4,
        verse: 19,
        placeName: 'Gilgal 1',
      ),
      CuratedWaypoint(
        title: 'Conquers Jericho',
        year: -1405,
        bookName: 'Joshua',
        chapter: 6,
        verse: 1,
        placeName: 'Jericho 1',
      ),
      CuratedWaypoint(
        title: 'Conquers Ai',
        year: -1405,
        bookName: 'Joshua',
        chapter: 8,
        verse: 1,
        placeName: 'Ai 1',
      ),
      CuratedWaypoint(
        title: 'Builds an altar on Mount Ebal',
        year: -1405,
        bookName: 'Joshua',
        chapter: 8,
        verse: 30,
        placeName: 'Mount Ebal',
      ),
      CuratedWaypoint(
        title: 'Defends Gibeon',
        year: -1405,
        bookName: 'Joshua',
        chapter: 10,
        verse: 9,
        placeName: 'Gibeon',
      ),
      CuratedWaypoint(
        title: 'Defeats the northern kings at the Waters of Merom',
        year: -1400,
        bookName: 'Joshua',
        chapter: 11,
        verse: 5,
        placeName: 'Waters of Merom',
      ),
      CuratedWaypoint(
        title: 'Sets up the tabernacle at Shiloh',
        year: -1399,
        bookName: 'Joshua',
        chapter: 18,
        verse: 1,
        placeName: 'Shiloh',
      ),
      CuratedWaypoint(
        title: 'Renews the covenant at Shechem',
        year: -1385,
        bookName: 'Joshua',
        chapter: 24,
        verse: 1,
        placeName: 'Shechem',
      ),
      CuratedWaypoint(
        title: 'Buried in Timnath-heres',
        year: -1385,
        bookName: 'Joshua',
        chapter: 24,
        verse: 30,
        placeName: 'Timnath-heres',
      ),
    ],
  ),

  // ----------------------------------------
  // PROPHETS & KINGS
  // ----------------------------------------

  // Jonah
  CuratedPersonJourney(
    personSlug: 'jonah_1689',
    waypoints: [
      CuratedWaypoint(
        title: 'Hometown of Gath-hepher',
        year: -780,
        bookName: '2 Kings',
        chapter: 14,
        verse: 25,
        placeName: 'Gath-hepher',
      ),
      CuratedWaypoint(
        title: 'Flees to Joppa',
        year: -760,
        bookName: 'Jonah',
        chapter: 1,
        verse: 3,
        placeName: 'Joppa',
      ),
      // Tarshish is his destination, but he boards a ship into the Mediterranean Sea
      CuratedWaypoint(
        title: 'Delivered in Nineveh',
        year: -760,
        bookName: 'Jonah',
        chapter: 3,
        verse: 3,
        placeName: 'Nineveh',
      ),
    ],
  ),

  // Ezekiel
  // Note: Ezekiel's visions include Jerusalem, but his physical location remains in Chaldea/Babylon.
  CuratedPersonJourney(
    personSlug: 'ezekiel_1237',
    waypoints: [
      CuratedWaypoint(
        title: 'Among the exiles by the Chebar canal',
        year: -593,
        bookName: 'Ezekiel',
        chapter: 1,
        verse: 1,
        placeName: 'Chebar',
      ),
      CuratedWaypoint(
        title: 'Sits overwhelmed at Tel-abib',
        year: -593,
        bookName: 'Ezekiel',
        chapter: 3,
        verse: 15,
        placeName: 'Tel-abib',
      ),
      // Ezekiel 8:3 — "the Spirit lifted me up ... and brought me in visions
      // of God to Jerusalem" — excluded because it's a spiritual vision, not
      // physical travel. Ezekiel remained in Babylon throughout. Contrast with
      // Daniel's Susa/Tigris entries, where Daniel physically traveled there.
    ],
  ),

  // Samuel
  CuratedPersonJourney(
    personSlug: 'samuel_2469',
    waypoints: [
      CuratedWaypoint(
        title: 'Given to the Lord at Shiloh',
        year: -1160,
        bookName: '1 Samuel',
        chapter: 1,
        verse: 24,
        placeName: 'Shiloh',
      ),
      CuratedWaypoint(
        title: 'Gathers Israel at Mizpah',
        year: -1120,
        bookName: '1 Samuel',
        chapter: 7,
        verse: 5,
        placeName: 'Mizpah 2', // Benjamite Mizpah
      ),
      CuratedWaypoint(
        title: 'Sets up a stone named Ebenezer',
        year: -1120,
        bookName: '1 Samuel',
        chapter: 7,
        verse: 12,
        placeName: 'Ebenezer 1',
      ),
      CuratedWaypoint(
        title: 'Judges on a circuit: Bethel, Gilgal, and Mizpah',
        year: -1115,
        bookName: '1 Samuel',
        chapter: 7,
        verse: 16,
        placeName: 'Bethel 1', // Pick one to represent the circuit
      ),
      CuratedWaypoint(
        title: 'Returns to his home in Ramah',
        year: -1115,
        bookName: '1 Samuel',
        chapter: 7,
        verse: 17,
        placeName: 'Ramah 1',
      ),
      CuratedWaypoint(
        title: 'Meets Saul in the land of Zuph',
        year: -1095,
        bookName: '1 Samuel',
        chapter: 9,
        verse: 5,
        placeName: 'Zuph',
      ),
      CuratedWaypoint(
        title: 'Renews the kingdom at Gilgal',
        year: -1095,
        bookName: '1 Samuel',
        chapter: 11,
        verse: 14,
        placeName: 'Gilgal 1',
      ),
      CuratedWaypoint(
        title: 'Anoints David in Bethlehem',
        year: -1068,
        bookName: '1 Samuel',
        chapter: 16,
        verse: 4,
        placeName: 'Bethlehem 1',
      ),
      CuratedWaypoint(
        title: 'Dies and is buried in Ramah',
        year: -1060,
        bookName: '1 Samuel',
        chapter: 25,
        verse: 1,
        placeName: 'Ramah 1',
      ),
    ],
  ),

  // King Saul
  CuratedPersonJourney(
    personSlug: 'saul_2478',
    waypoints: [
      CuratedWaypoint(
        title: 'Returns home to Gibeah after being chosen king',
        year: -1095,
        bookName: '1 Samuel',
        chapter: 10,
        verse: 26,
        placeName: 'Gibeah 1',
      ),
      CuratedWaypoint(
        title: 'Musters the army at Bezek to relieve Jabesh-gilead',
        year: -1095,
        bookName: '1 Samuel',
        chapter: 11,
        verse: 8,
        placeName: 'Bezek 1',
      ),
      CuratedWaypoint(
        title: 'Confirmed as king at Gilgal',
        year: -1095,
        bookName: '1 Samuel',
        chapter: 11,
        verse: 15,
        placeName: 'Gilgal 1',
      ),
      CuratedWaypoint(
        title: 'Gathers forces at Michmash',
        year: -1093,
        bookName: '1 Samuel',
        chapter: 13,
        verse: 2,
        placeName: 'Michmash',
      ),
      CuratedWaypoint(
        title: 'Sets up a monument at Carmel after defeating Amalek',
        year: -1079,
        bookName: '1 Samuel',
        chapter: 15,
        verse: 12,
        placeName: 'Carmel 1',
      ),
      CuratedWaypoint(
        title: 'Camps in the Valley of Elah against the Philistines',
        year: -1066,
        bookName: '1 Samuel',
        chapter: 17,
        verse: 2,
        placeName: 'Valley of Elah',
      ),
      CuratedWaypoint(
        title: 'Pursues David to Naioth in Ramah',
        year: -1062,
        bookName: '1 Samuel',
        chapter: 19,
        verse: 22,
        placeName: 'Naioth',
      ),
      CuratedWaypoint(
        title: 'Pursues David to the Wilderness of Ziph',
        year: -1059,
        bookName: '1 Samuel',
        chapter: 23,
        verse: 14,
        placeName: 'Wilderness of Ziph',
      ),
      CuratedWaypoint(
        title: 'Pursues David to the Wilderness of Maon',
        year: -1059,
        bookName: '1 Samuel',
        chapter: 23,
        verse: 24,
        placeName: 'Maon',
      ),
      CuratedWaypoint(
        title: 'Seeks David in the Wilderness of En-gedi',
        year: -1058,
        bookName: '1 Samuel',
        chapter: 24,
        verse: 1,
        placeName: 'Engedi',
      ),
      CuratedWaypoint(
        title: 'Consults the medium at En-dor',
        year: -1056,
        bookName: '1 Samuel',
        chapter: 28,
        verse: 7,
        placeName: 'En-dor',
      ),
      CuratedWaypoint(
        title: 'Dies in battle on Mount Gilboa',
        year: -1056,
        bookName: '1 Samuel',
        chapter: 31,
        verse: 1,
        placeName: 'Mount Gilboa',
      ),
    ],
  ),

  // ----------------------------------------
  // WOMEN OF THE BIBLE
  // ----------------------------------------

  // Ruth
  CuratedPersonJourney(
    personSlug: 'ruth_2450',
    waypoints: [
      CuratedWaypoint(
        title: 'Lives in Moab, marries Mahlon',
        year: -1140, // Approximate Judges period
        bookName: 'Ruth',
        chapter: 1,
        verse: 4,
        placeName: 'Moab 1',
      ),
      CuratedWaypoint(
        title: 'Returns with Naomi to Bethlehem',
        year: -1130,
        bookName: 'Ruth',
        chapter: 1,
        verse: 19,
        placeName: 'Bethlehem 1',
      ),
    ],
  ),

  // Naomi
  CuratedPersonJourney(
    personSlug: 'naomi_2147',
    waypoints: [
      CuratedWaypoint(
        title: 'Leaves Bethlehem due to famine',
        year: -1140,
        bookName: 'Ruth',
        chapter: 1,
        verse: 1,
        placeName: 'Bethlehem 1',
      ),
      CuratedWaypoint(
        title: 'Sojourns in Moab',
        year: -1140,
        bookName: 'Ruth',
        chapter: 1,
        verse: 2,
        placeName: 'Moab 1',
      ),
      CuratedWaypoint(
        title: 'Returns to Bethlehem with Ruth',
        year: -1130,
        bookName: 'Ruth',
        chapter: 1,
        verse: 19,
        placeName: 'Bethlehem 1',
      ),
    ],
  ),

  // Esther
  CuratedPersonJourney(
    personSlug: 'esther_1343',
    waypoints: [
      CuratedWaypoint(
        title: 'Taken to the king\'s palace in Susa',
        year: -479, // Xerxes reign
        bookName: 'Esther',
        chapter: 2,
        verse: 8,
        placeName: 'Susa',
      ),
    ],
  ),

  // ----------------------------------------
  // OTHER KEY NT FIGURES
  // ----------------------------------------

  // John the Baptist
  CuratedPersonJourney(
    personSlug: 'john_1676',
    waypoints: [
      CuratedWaypoint(
        title: 'Born in the hill country of Judea',
        year: -5.0,
        bookName: 'Luke',
        chapter: 1,
        verse: 65,
        placeName: 'Judea 1',
      ),
      CuratedWaypoint(
        title: 'Preaches in the Wilderness of Judea',
        year: 26.0,
        bookName: 'Matthew',
        chapter: 3,
        verse: 1,
        placeName: 'Judea 1',
      ),
      CuratedWaypoint(
        title: 'Baptizes at the Jordan River',
        year: 26.5,
        bookName: 'Matthew',
        chapter: 3,
        verse: 6,
        placeName: 'Jordan',
      ),
      CuratedWaypoint(
        title: 'Baptizes at Bethany across the Jordan',
        year: 27.0,
        bookName: 'John',
        chapter: 1,
        verse: 28,
        placeName: 'Bethany 2', // Bethany beyond Jordan
      ),
      CuratedWaypoint(
        title: 'Baptizes at Aenon near Salim',
        year: 27.5,
        bookName: 'John',
        chapter: 3,
        verse: 23,
        placeName: 'Aenon',
      ),
      // Note: Prison at Machaerus is historical (Josephus) but not explicitly named in the NT text.
      // We omit the explicit Machaerus pin to stick to strictly text-based derivations, or we can use the nearest region.
    ],
  ),

  // James (brother of John)
  CuratedPersonJourney(
    personSlug: 'james_717', // Verified: Matt 4:21 — son of Zebedee
    waypoints: [
      // Same title/citation as Peter's/Andrew's waypoint — Matthew 4:18-22
      // narrates both callings (Peter & Andrew, then James & John) as one
      // continuous scene by the Sea of Galilee, so this is deliberately
      // shared rather than split into two near-duplicate "Called by Jesus"
      // entries at the same place and year.
      CuratedWaypoint(
        title: 'Called by Jesus at the Sea of Galilee',
        year: 27.0,
        bookName: 'Matthew',
        chapter: 4,
        verse: 18,
        placeName: 'Sea of Galilee',
      ),
      CuratedWaypoint(
        title: 'Jesus heals Peter\'s mother-in-law in Capernaum',
        year: 27.1,
        bookName: 'Mark',
        chapter: 1,
        verse: 29,
        placeName: 'Capernaum',
      ),
      // Transfiguration (Matt 17:1) excluded: the text says only "a high
      // mountain" with no name. Tradition identifies Mount Hermon or Mount
      // Tabor, but we cannot derive a place from the verse text alone.
      CuratedWaypoint(
        title: 'With Jesus in Gethsemane',
        year: 30.0,
        bookName: 'Matthew',
        chapter: 26,
        verse: 37,
        placeName: 'Gethsemane',
      ),
      CuratedWaypoint(
        title: 'Executed by Herod in Jerusalem',
        year: 44.0,
        bookName: 'Acts',
        chapter: 12,
        verse: 2,
        placeName: 'Jerusalem',
      ),
    ],
  ),

  // Andrew
  CuratedPersonJourney(
    personSlug: 'andrew_264',
    waypoints: [
      // John 1:44 identifies Andrew's hometown, not a narrated travel event.
      // Included as the starting point of his journey since it establishes
      // his base location before Jesus's ministry.
      CuratedWaypoint(
        title: 'Hometown of Bethsaida',
        year: 26.0,
        bookName: 'John',
        chapter: 1,
        verse: 44,
        placeName: 'Bethsaida 1',
      ),
      CuratedWaypoint(
        title: 'Follows Jesus at Bethany across the Jordan',
        year: 27.0,
        bookName: 'John',
        chapter: 1,
        verse: 28,
        placeName: 'Bethany 2',
      ),
      CuratedWaypoint(
        title: 'Called by Jesus at the Sea of Galilee',
        year: 27.1,
        bookName: 'Matthew',
        chapter: 4,
        verse: 18,
        placeName: 'Sea of Galilee',
      ),
      CuratedWaypoint(
        title: 'In the upper room in Jerusalem',
        year: 30.5,
        bookName: 'Acts',
        chapter: 1,
        verse: 13,
        placeName: 'Jerusalem',
      ),
    ],
  ),

  // Titus
  // Locations heavily inferred from Epistles
  CuratedPersonJourney(
    personSlug: 'titus_2869',
    waypoints: [
      CuratedWaypoint(
        title: 'Goes to Jerusalem with Paul and Barnabas',
        year: 49.0, // Jerusalem Council
        bookName: 'Galatians',
        chapter: 2,
        verse: 1,
        placeName: 'Jerusalem',
      ),
      CuratedWaypoint(
        title: 'Meets Paul in Macedonia with news from Corinth',
        year: 54.0,
        bookName: '2 Corinthians',
        chapter: 7,
        verse: 5,
        placeName: 'Macedonia',
      ),
      CuratedWaypoint(
        title: 'Sent to Corinth to complete the collection',
        year: 54.1,
        bookName: '2 Corinthians',
        chapter: 8,
        verse: 16,
        placeName: 'Corinth',
      ),
      CuratedWaypoint(
        title: 'Left in Crete to appoint elders',
        year: 62.0,
        bookName: 'Titus',
        chapter: 1,
        verse: 5,
        placeName: 'Crete',
      ),
      CuratedWaypoint(
        title: 'Instructed to meet Paul at Nicopolis',
        year: 63.0,
        bookName: 'Titus',
        chapter: 3,
        verse: 12,
        placeName: 'Nicopolis',
      ),
      CuratedWaypoint(
        title: 'Departs for Dalmatia',
        year: 66.0,
        bookName: '2 Timothy',
        chapter: 4,
        verse: 10,
        placeName: 'Dalmatia',
      ),
    ],
  ),

  // Apollos
  CuratedPersonJourney(
    personSlug: 'apollos_276',
    waypoints: [
      CuratedWaypoint(
        title: 'Native of Alexandria',
        year: 52.0,
        bookName: 'Acts',
        chapter: 18,
        verse: 24,
        placeName: 'Alexandria',
      ),
      CuratedWaypoint(
        title: 'Preaches in Ephesus',
        year: 52.1,
        bookName: 'Acts',
        chapter: 18,
        verse: 24,
        placeName: 'Ephesus',
      ),
      CuratedWaypoint(
        title: 'Crosses over to Achaia (Corinth)',
        year: 52.2,
        bookName: 'Acts',
        chapter: 18,
        verse: 27,
        placeName: 'Achaia', // Corinth in Acts 19:1
      ),
    ],
  ),

  // ----------------------------------------
  // POST-EXILIC LEADERS
  // ----------------------------------------

  // Ezra
  CuratedPersonJourney(
    personSlug: 'ezra_1244',
    waypoints: [
      CuratedWaypoint(
        title: 'Departs from Babylon',
        year: -458,
        bookName: 'Ezra',
        chapter: 7,
        verse: 6,
        placeName: 'Babylon 1',
      ),
      CuratedWaypoint(
        title: 'Gathers the exiles at the Ahava Canal',
        year: -458,
        bookName: 'Ezra',
        chapter: 8,
        verse: 15,
        placeName: 'Ahava', // Or Ahava Canal
      ),
      // Distinct title from Luke's "Arrives in Jerusalem" (Acts 21:15, AD
      // 54) — the importer dedupes waypoints by exact title with no
      // per-person scoping, so a shared title here would silently merge
      // Ezra's 458 BC arrival into Luke's unrelated NT event.
      CuratedWaypoint(
        title: 'Arrives in Jerusalem with the returning exiles',
        year: -458,
        bookName: 'Ezra',
        chapter: 8,
        verse: 32,
        placeName: 'Jerusalem',
      ),
    ],
  ),

  // Nehemiah
  CuratedPersonJourney(
    personSlug: 'nehemiah_2171',
    waypoints: [
      CuratedWaypoint(
        title: 'Serves the king in Susa',
        year: -445,
        bookName: 'Nehemiah',
        chapter: 1,
        verse: 1,
        placeName: 'Susa',
      ),
      CuratedWaypoint(
        title: 'Arrives in Jerusalem to rebuild the walls',
        year: -445,
        bookName: 'Nehemiah',
        chapter: 2,
        verse: 11,
        placeName: 'Jerusalem',
      ),
    ],
  ),
  // Years for the patriarchs (Abraham, Isaac, Joseph) are sequential sort
  // keys, not historically calibrated dates. Their real chronology spans
  // decades-to-centuries (Abraham lived 175 years, Isaac 180, Joseph 110),
  // but the years here only need to be monotonically increasing so the
  // waypoints sort correctly on the timeline. The absolute values are
  // approximate anchors within the traditional dating window.
  CuratedPersonJourney(
    personSlug: 'abraham_58',
    waypoints: [
      CuratedWaypoint(
        title: 'Abraham leaves Ur of the Chaldeans',
        year: -2000,
        bookName: 'Genesis',
        chapter: 11,
        verse: 31,
        placeName: 'Ur 1',
      ),
      CuratedWaypoint(
        title: 'Abraham stays in Haran',
        year: -1999,
        bookName: 'Genesis',
        chapter: 11,
        verse: 31,
        placeName: 'Haran',
      ),
      CuratedWaypoint(
        title: 'Abraham arrives at Shechem',
        year: -1998,
        bookName: 'Genesis',
        chapter: 12,
        verse: 6,
        placeName: 'Shechem',
      ),
      CuratedWaypoint(
        title: 'Abraham pitches tent at Bethel',
        year: -1997,
        bookName: 'Genesis',
        chapter: 12,
        verse: 8,
        placeName: 'Bethel 1',
      ),
      CuratedWaypoint(
        title: 'Abraham journeys to Egypt during a famine',
        year: -1996,
        bookName: 'Genesis',
        chapter: 12,
        verse: 10,
        placeName: 'Egypt',
      ),
      CuratedWaypoint(
        title: 'Abraham returns to Bethel',
        year: -1995,
        bookName: 'Genesis',
        chapter: 13,
        verse: 3,
        placeName: 'Bethel 1',
      ),
      CuratedWaypoint(
        title: 'Abraham settles by the oaks of Mamre',
        year: -1994,
        bookName: 'Genesis',
        chapter: 13,
        verse: 18,
        placeName: 'Mamre',
      ),
      CuratedWaypoint(
        title: 'Abraham pursues kings to Dan',
        year: -1993,
        bookName: 'Genesis',
        chapter: 14,
        verse: 14,
        placeName: 'Dan',
      ),
      CuratedWaypoint(
        title: 'Abraham defeats kings near Hobah',
        year: -1992,
        bookName: 'Genesis',
        chapter: 14,
        verse: 15,
        placeName: 'Hobah',
      ),
      CuratedWaypoint(
        title: 'Abraham blessed by Melchizedek in Salem',
        year: -1991,
        bookName: 'Genesis',
        chapter: 14,
        verse: 18,
        placeName: 'Salem',
      ),
      CuratedWaypoint(
        title: 'Abraham sojourns in Gerar',
        year: -1990,
        bookName: 'Genesis',
        chapter: 20,
        verse: 1,
        placeName: 'Gerar',
      ),
      CuratedWaypoint(
        title: 'Abraham makes a covenant at Beersheba',
        year: -1989,
        bookName: 'Genesis',
        chapter: 21,
        verse: 31,
        placeName: 'Beersheba 1',
      ),
      CuratedWaypoint(
        title: 'Abraham travels to Moriah',
        year: -1988,
        bookName: 'Genesis',
        chapter: 22,
        verse: 2,
        placeName: 'Moriah',
      ),
      CuratedWaypoint(
        title: 'Abraham returns to Beersheba',
        year: -1987,
        bookName: 'Genesis',
        chapter: 22,
        verse: 19,
        placeName: 'Beersheba 1',
      ),
      CuratedWaypoint(
        title: 'Abraham buries Sarah in Machpelah',
        year: -1986,
        bookName: 'Genesis',
        chapter: 23,
        verse: 19,
        placeName: 'Machpelah',
      ),
    ],
  ),

  CuratedPersonJourney(
    personSlug: 'isaac_616',
    waypoints: [
      CuratedWaypoint(
        title: 'Isaac born in Beersheba',
        year: -1900,
        bookName: 'Genesis',
        chapter: 21,
        verse: 3,
        placeName: 'Beersheba 1', // Inferred from Abraham's prior location (Gen 21:31-33)
      ),
      CuratedWaypoint(
        title: 'Isaac taken to Moriah',
        year: -1899,
        bookName: 'Genesis',
        chapter: 22,
        verse: 2,
        placeName: 'Moriah',
      ),
      CuratedWaypoint(
        title: 'Isaac returns to Beersheba',
        year: -1898,
        bookName: 'Genesis',
        chapter: 22,
        verse: 19,
        placeName: 'Beersheba 1',
      ),
      CuratedWaypoint(
        title: 'Isaac settles at Beer-lahai-roi',
        year: -1897,
        bookName: 'Genesis',
        chapter: 24,
        verse: 62,
        placeName: 'Beer-lahai-roi',
      ),
      CuratedWaypoint(
        title: 'Isaac moves to Gerar',
        year: -1896,
        bookName: 'Genesis',
        chapter: 26,
        verse: 1,
        placeName: 'Gerar',
      ),
      CuratedWaypoint(
        title: 'Isaac digs wells in the Valley of Gerar',
        year: -1895,
        bookName: 'Genesis',
        chapter: 26,
        verse: 17,
        placeName: 'Valley of Gerar',
      ),
      CuratedWaypoint(
        title: 'Isaac returns to Beersheba after famine',
        year: -1894,
        bookName: 'Genesis',
        chapter: 26,
        verse: 23,
        placeName: 'Beersheba 1',
      ),
      CuratedWaypoint(
        title: 'Isaac dies at Mamre',
        year: -1893,
        bookName: 'Genesis',
        chapter: 35,
        verse: 27,
        placeName: 'Mamre',
      ),
    ],
  ),

  CuratedPersonJourney(
    personSlug: 'joseph_1710',
    waypoints: [
      CuratedWaypoint(
        title: 'Joseph sent from the Valley of Hebron',
        year: -1800,
        bookName: 'Genesis',
        chapter: 37,
        verse: 14,
        placeName: 'Valley of Hebron',
      ),
      CuratedWaypoint(
        title: 'Joseph looks for his brothers in Shechem',
        year: -1799,
        bookName: 'Genesis',
        chapter: 37,
        verse: 14,
        placeName: 'Shechem',
      ),
      CuratedWaypoint(
        title: 'Joseph finds his brothers in Dothan',
        year: -1798,
        bookName: 'Genesis',
        chapter: 37,
        verse: 17,
        placeName: 'Dothan',
      ),
      CuratedWaypoint(
        title: 'Joseph sold into Egypt',
        year: -1797,
        bookName: 'Genesis',
        chapter: 39,
        verse: 1,
        placeName: 'Egypt', // National boundary used as location
      ),
      CuratedWaypoint(
        title: 'Joseph imprisoned in Egypt',
        year: -1796,
        bookName: 'Genesis',
        chapter: 39,
        verse: 20,
        placeName: 'Egypt',
      ),
      CuratedWaypoint(
        title: 'Joseph elevated to Pharaoh\'s court',
        year: -1795,
        bookName: 'Genesis',
        chapter: 41,
        verse: 46,
        placeName: 'Egypt',
      ),
      CuratedWaypoint(
        title: 'Joseph meets his family in Goshen',
        year: -1794,
        bookName: 'Genesis',
        chapter: 46,
        verse: 28,
        placeName: 'Goshen 1',
      ),
      CuratedWaypoint(
        title: 'Joseph buries Jacob in Machpelah',
        year: -1793,
        bookName: 'Genesis',
        chapter: 50,
        verse: 13,
        placeName: 'Machpelah',
      ),
      CuratedWaypoint(
        title: 'Joseph returns to Egypt',
        year: -1792,
        bookName: 'Genesis',
        chapter: 50,
        verse: 14,
        placeName: 'Egypt',
      ),
    ],
  ),
];
