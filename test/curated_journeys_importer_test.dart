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
    container = ProviderContainer(
      overrides: [contentStoreProvider.overrideWithValue(store)],
    );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  test('inserts every curated waypoint exactly once, idempotently', () async {
    final importer = CuratedJourneysImporter(store);
    // Depends on people/places already being loaded, same as production.
    await container.read(curatedJourneysReadyProvider.future);
    final events = await store.select(store.timelineEvents).get();
    final curatedTitles = {
      for (final j in curatedPersonJourneys)
        for (final w in j.waypoints) w.title,
    };
    final curatedEvents = events
        .where((e) => curatedTitles.contains(e.title))
        .toList();
    expect(curatedEvents.length, curatedTitles.length);

    // Re-running (directly, bypassing the cached provider) must not duplicate.
    await importer.ensureLoaded();
    final recount = await store.select(store.timelineEvents).get();
    expect(recount.length, events.length);
  });

  // Regression: ensureLoaded() used to gate on a single "have we ever run
  // this importer" sentinel (the very first waypoint's title) — so a
  // persistent on-device DB that already had that one title from an early
  // run would skip every waypoint added afterward, forever. Fixed to check
  // each waypoint's own title individually.
  test('a DB that already has just the first curated waypoint still gets '
      'every other waypoint on the next run', () async {
    await container.read(curatedJourneysReadyProvider.future);

    // Wipe everything the setup just loaded, then re-plant only the old
    // sentinel title, simulating a persistent DB stuck mid-history.
    await store.delete(store.timelineEvents).go();
    final sentinelTitle = curatedPersonJourneys.first.waypoints.first.title;
    await store
        .into(store.timelineEvents)
        .insert(TimelineEventsCompanion.insert(title: sentinelTitle));

    await CuratedJourneysImporter(store).ensureLoaded();
    final curatedTitles = {
      for (final j in curatedPersonJourneys)
        for (final w in j.waypoints) w.title,
    };
    final events = await store.select(store.timelineEvents).get();
    final curatedEvents = events
        .where((e) => curatedTitles.contains(e.title))
        .toList();
    expect(curatedEvents.length, curatedTitles.length);
  });

  test(
    "Elijah's journey has all 14 real stops in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final elijah = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('elijah_1131'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(elijah.id).future,
      );
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
    },
  );

  test(
    "Elisha's journey has all 10 real stops in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final elisha = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('elisha_1153'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(elisha.id).future,
      );
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
    },
  );

  test(
    "Solomon's journey has all 3 real stops in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final solomon = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('solomon_2762'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(solomon.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Gihon 2',
        'Gibeon',
        'Jerusalem',
      ]);
      // "Reign of Solomon" is superseded by these curated stops.
      expect(journey.unmappedEventCount, 1);
    },
  );

  test("David's journey has all 15 curated stops interleaved with the "
      "bundled dataset's own Goliath/death events", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final david = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('david_994'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(david.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Bethlehem 1', // curated: anointed by Samuel
      'Azekah', // bundled: David Kills Goliath
      'Nob',
      'Gath 1',
      'Adullam',
      'Keilah',
      'Engedi',
      'Carmel 1',
      'Ziklag',
      'Hebron',
      'City of David', // captures Jebus
      'City of David', // brings up the Ark
      'Rabbah 1',
      'Mahanaim',
      'Jerusalem', // returns after Absalom
      'Jerusalem', // census/plague
      'City of David', // bundled: Death of David
    ]);
    // "Reign of David" is superseded by these curated stops.
    expect(journey.unmappedEventCount, 1);
  });

  test("Isaiah's journey has both real stops (honestly short — his whole "
      "biography is essentially one location)", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final isaiah = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('isaiah_617'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(isaiah.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Jerusalem',
      'Upper Pool',
    ]);
    // "Prophecies of Isaiah" is superseded by these curated stops.
    expect(journey.unmappedEventCount, 1);
  });

  test('backfills the Isaiah 6:1 / Jerusalem place-verse link', () async {
    await container.read(curatedJourneysReadyProvider.future);
    final jerusalem = await (store.select(
      store.places,
    )..where((p) => p.name.equals('Jerusalem'))).getSingle();
    final link =
        await (store.select(store.placeVerses)..where(
              (pv) =>
                  pv.placeId.equals(jerusalem.id) &
                  pv.bookName.equals('Isaiah') &
                  pv.chapter.equals(6) &
                  pv.verse.equals(1),
            ))
            .getSingleOrNull();
    expect(link, isNotNull);
  });

  test('backfills the Abel-meholah / 1 Kings 19:19 place-verse link', () async {
    await container.read(curatedJourneysReadyProvider.future);
    final abelMeholah = await (store.select(
      store.places,
    )..where((p) => p.name.equals('Abel-meholah'))).getSingle();
    final link =
        await (store.select(store.placeVerses)..where(
              (pv) =>
                  pv.placeId.equals(abelMeholah.id) &
                  pv.bookName.equals('1 Kings') &
                  pv.chapter.equals(19) &
                  pv.verse.equals(19),
            ))
            .getSingleOrNull();
    expect(link, isNotNull);
  });

  test(
    "Jeremiah's journey has all 9 real stops in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final jeremiah = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('jeremiah_853'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(jeremiah.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Anathoth',
        'Valley of Hinnom',
        'Benjamin Gate',
        'Benjamin Gate',
        'Jerusalem',
        'Ramah 1',
        'Mizpah 3',
        'Geruth Chimham',
        'Tahpanhes',
      ]);
      // "Prophecies of Jeremiah" is superseded by these curated stops.
      expect(journey.unmappedEventCount, 1);
    },
  );

  test(
    "Daniel's journey has all 5 real stops in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final daniel = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('daniel_975'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(daniel.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Jerusalem',
        'Babylon 1',
        'Babylon 1',
        'Susa',
        'Tigris',
      ]);
      // "Prophecies of Daniel" is superseded by these curated stops.
      expect(journey.unmappedEventCount, 1);
    },
  );

  test("Ahab's journey has the bundled succession notice plus all 6 "
      "curated stops in chronological order", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final ahab = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('ahab_113'))).getSingle();

    final journey = await container.read(personJourneyProvider(ahab.id).future);
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Samaria 1', // bundled: "Reign of Ahab" succession notice
      'Mount Carmel',
      'Samaria 1',
      'Aphek 3',
      'Jezreel 2',
      'Ramoth-gilead',
      'Samaria 1',
    ]);
    // Unlike every prior person here, nothing is superseded — the bundled
    // event was only a 3-verse succession notice, not a life-spanning blob.
    expect(journey.unmappedEventCount, 0);
  });

  test(
    "Jeroboam's journey has all 9 real stops in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final jeroboam = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('jeroboam_872'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(jeroboam.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Zeredah 1',
        'Egypt',
        'Egypt',
        'Shechem',
        'Shechem',
        'Penuel',
        'Bethel 1',
        'Dan',
        'Bethel 1',
      ]);
      // "Reign of Jeroboam I" (a false-positive resolution to Egypt via the
      // gazetteer's own retrospective tagging of 1 Kings 12:20) is superseded
      // by these curated stops.
      expect(journey.unmappedEventCount, 1);
    },
  );

  test("Gideon's journey has the bundled calling plus all 10 curated stops "
      "in chronological order", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final gideon = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('gideon_1314'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(gideon.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Ophrah 2', // bundled: "Deliverance by Gideon" calling
      'Harod 1',
      'Jordan',
      'Succoth 1',
      'Penuel',
      'Jogbehah',
      'Heres',
      'Succoth 1',
      'Penuel',
      'Ophrah 2',
      'Ophrah 2',
    ]);
    // Nothing is superseded — the bundled event already resolves correctly
    // to Ophrah, where Gideon's calling actually happens.
    expect(journey.unmappedEventCount, 0);
  });

  test("Zedekiah's journey has the bundled enthronement plus all 6 curated "
      "stops in chronological order", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final zedekiah = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('zedekiah_1950'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(zedekiah.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Jerusalem', // bundled: "Reign of Zedekiah" enthronement notice
      'Jerusalem',
      'Arabah',
      'Jericho 1',
      'Riblah 1',
      'Riblah 1',
      'Babylon 1',
    ]);
    // Nothing is superseded — the bundled event already resolves correctly
    // to Jerusalem, where his reign begins.
    expect(journey.unmappedEventCount, 0);
  });

  test("Rehoboam's journey has Shechem, the bundled Jerusalem flight, and "
      "Shishak's invasion in chronological order", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final rehoboam = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('rehoboam_2412'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(rehoboam.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Shechem',
      'Jerusalem', // bundled: "Reign of Rehoboam" flight after Adoram's death
      'Jerusalem',
    ]);
    // Nothing is superseded — the bundled event already resolves correctly
    // to Jerusalem, where he flees and remains for the rest of his reign.
    expect(journey.unmappedEventCount, 0);
  });

  test(
    "Jehoiakim's journey has the bundled enthronement plus Nebuchadnezzar's "
    "first deportation and the scroll-burning, in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final jehoiakim = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('jehoiakim_1085'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(jehoiakim.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Jerusalem', // bundled: "Reign of Jehoiakim" enthronement notice
        'Jerusalem',
        'Babylon 1',
        'Jerusalem',
      ]);
      // Nothing is superseded — the bundled event already resolves correctly
      // to Jerusalem, where his reign begins.
      expect(journey.unmappedEventCount, 0);
    },
  );

  test("Abimelech's journey has the bundled kingship at Shechem plus his "
      "whole rise-and-fall story in chronological order", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final abimelech = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('abimelech_41'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(abimelech.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Shechem', // bundled: "Usurpation by Abimelech" (his birth notice)
      'Ophrah 2',
      'Arumah',
      'Shechem',
      'Mount Zalmon',
      'Tower of Shechem',
      'Thebez',
      'Thebez',
    ]);
    // Nothing is superseded — the bundled event already resolves correctly
    // to Shechem, where his story begins.
    expect(journey.unmappedEventCount, 0);
  });

  test("Caleb's journey has the spy mission and his claim on Hebron in "
      "chronological order", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final caleb = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('caleb_537'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(caleb.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Paran',
      'Hebron',
      'Valley of Eshcol',
      'Kadesh-barnea',
      'Gilgal 1',
      'Hebron',
      'Hebron',
      'Debir 1',
    ]);
    // "Birth of Caleb" (Numbers 13:6, just his name in the spy roster with no
    // place_verses link) is superseded by these curated stops.
    expect(journey.unmappedEventCount, 1);
  });

  test("Moses's journey fills in the real stops inside the Exodus and "
      "Wilderness Wanderings blobs, and fixes his death location", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final moses = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('moses_2108'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(moses.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Nile', // bundled: "Birth of Moses"
      'Egypt', // bundled: "Exodus from Egypt"
      'Rameses',
      'Succoth 2',
      'Etham',
      'Red Sea 1', // bundled: "Wilderness Wanderings"
      'Pi-hahiroth',
      'Shur',
      'Marah',
      'Elim',
      'Sin',
      'Rephidim',
      'Wilderness of Sinai', // bundled: "Ten Commandments Given"
      'Mount Sinai', // bundled: "Tabernacle Built"
      'Mount Nebo', // bundled: "Death of Moses" (was Gilead — a false
      // positive from the panoramic view God shows him, not his location)
    ]);
    // "Lifetime of Moses" and "The Transfiguration" have no place_verses
    // links at all for their cited verses.
    expect(journey.unmappedEventCount, 2);
  });

  test("Esau's journey has his reconciliation with Jacob, Isaac's burial, "
      "and his move to Edom in chronological order", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final esau = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('esau_1216'))).getSingle();

    final journey = await container.read(personJourneyProvider(esau.id).future);
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Mount Seir 1',
      'Hebron',
      'Canaan',
      'Mount Seir 1',
    ]);
    // "Birth of Jacob and Esau" (Genesis 25:24-26, no place_verses link) is
    // superseded by these curated stops.
    expect(journey.unmappedEventCount, 1);
  });

  test("Benjamin's journey has his birth at Ephrath (fixed from Bethel) and "
      "his trip to Egypt, in chronological order", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final benjamin = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('benjamin_463'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(benjamin.id).future,
    );
    expect(journey, isNotNull);
    expect(journey!.waypoints.map((w) => w.placeName), [
      'Ephrath', // bundled: "Rachel dies giving birth to Benjamin"
      // (was Bethel — the place they'd just left, not where Rachel labors)
      'Egypt',
    ]);
    // Nothing is superseded — the bundled event resolves correctly to
    // Ephrath once overridden.
    expect(journey.unmappedEventCount, 0);
  });

  test(
    "Jacob's journey covers Beersheba to Haran and back, Peniel, and "
    "Egypt, in chronological order (he had zero dated events before)",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final jacob = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('jacob_683'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(jacob.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Beersheba 2',
        'Bethel 1',
        'Haran',
        'Gilead 1',
        'Mahanaim',
        'Jabbok',
        'Penuel',
        'Succoth 1',
        'Shechem',
        'Bethel 1',
        'Ephrath',
        'Hebron',
        'Beersheba 2',
        'Goshen 1',
        'Machpelah',
      ]);
      expect(journey.unmappedEventCount, 0);
    },
  );

  test("Jesus's journey fills in the Passion Week and beyond, which "
      "Theographic leaves entirely undated", () async {
    await container.read(curatedJourneysReadyProvider.future);
    final jesus = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('jesus_905'))).getSingle();

    final journey = await container.read(
      personJourneyProvider(jesus.id).future,
    );
    expect(journey, isNotNull);
    // The curated Passion Week block is appended after everything else
    // (see the doc comment in curated_journeys_data.dart on why it isn't
    // perfectly interleaved with the handful of already-out-of-order
    // late-ministry events that precede it).
    expect(
      journey!.waypoints
          .map((w) => w.placeName)
          .toList()
          .sublist(journey.waypoints.length - 18),
      [
        'Bethany 1', // Anointed by Mary
        'Bethphage',
        'Jerusalem', // Triumphal Entry
        'Bethany 1', // Curses the fig tree
        'Jerusalem', // Cleanses the Temple
        'Jerusalem', // Debates in the Temple
        'Mount of Olives', // Olivet Discourse
        'Jerusalem', // Last Supper
        'Mount of Olives', // Departs for the Mount of Olives
        'Gethsemane',
        'Jerusalem', // Sent to Herod
        'Gabbatha', // Condemned by Pilate
        'Golgotha', // Crucified
        'Emmaus',
        'Jerusalem', // Returns to Jerusalem
        'Galilee 1', // Appears in Galilee
        'Jerusalem', // Commands the apostles to wait
        'Bethany 1', // Ascends to heaven
      ],
    );
  });

  test(
    "Paul's journey has all 60 curated stops in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final paul = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('paul_2479'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(paul.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Damascus',
        'Arabia 2',
        'Jerusalem',
        'Tarsus',
        'Antioch 1',
        'Salamis',
        'Paphos',
        'Perga',
        'Antioch 2',
        'Iconium',
        'Lystra',
        'Derbe',
        'Attalia',
        'Syria 2',
        'Derbe',
        'Lystra',
        'Phrygia',
        'Galatia',
        'Troas',
        'Neapolis',
        'Philippi',
        'Amphipolis',
        'Apollonia',
        'Thessalonica',
        'Berea',
        'Athens',
        'Corinth',
        'Cenchreae',
        'Ephesus',
        'Caesarea',
        'Jerusalem',
        'Antioch 1',
        'Galatia',
        'Ephesus',
        'Macedonia',
        'Corinth',
        'Philippi',
        'Troas',
        'Assos',
        'Mitylene',
        'Chios',
        'Samos',
        'Miletus',
        'Cos',
        'Rhodes 1',
        'Patara',
        'Tyre',
        'Ptolemais',
        'Caesarea',
        'Jerusalem',
        'Sidon',
        'Myra',
        'Fair Havens',
        'Malta',
        'Syracuse',
        'Rhegium',
        'Puteoli',
        'Forum of Appius',
        'Three Taverns',
        'Rome',
      ]);
      // 30 dated-but-excluded events: the 29 bundled events superseded by this
      // curated journey that still carry a start_year (same pattern as e.g.
      // Solomon's "Reign of Solomon" above), plus "Stephen is stoned" — the one
      // other bundled event tying Paul in as a participant (he consents to it,
      // Acts 7:58) — whose verses (Acts 7:54-60) have no place_verses ties at
      // all, so it's dated but unmapped rather than a waypoint here. The
      // remaining 23 superseded events have no start_year and fall under
      // undatedEventCount instead.
      expect(journey.unmappedEventCount, 30);
    },
  );

  test(
    "Peter's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('peter_2745'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Sea of Galilee',
        'Sea of Galilee',
        'Galilee 1',
        'Galilee 1',
        'Caesarea Philippi',
        'Bethsaida 2',
        'Caesarea Philippi',
        'Jerusalem',
        'Capernaum',
        'Capernaum',
        'Beautiful Gate',
        'Solomon’s Portico',
        'Jerusalem',
        'Solomon’s Portico',
        'Jerusalem',
        'Jerusalem',
        'Samaria 1',
        'Jerusalem',
        'Lod',
        'Joppa',
        'Caesarea',
        'Lod',
        'Caesarea',
        'Galilee 1',
        'Judea 1',
        'Jerusalem',
        'Caesarea',
        'Jerusalem',
        'Jerusalem',
        'Antioch 1',
        'Babylon 2',
      ]);
      expect(journey.unmappedEventCount, 7);
      expect(journey.undatedEventCount, 7);
    },
  );

  test(
    "Barnabas's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('barnabas_1722'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Cyprus',
        'Cyprus',
        'Antioch 1',
        'Tarsus',
        'Antioch 1',
        'Jerusalem',
        'Salamis',
        'Paphos',
        'Perga',
        'Antioch 2',
        'Iconium',
        'Lystra',
        'Derbe',
        'Attalia',
        'Jerusalem',
        'Cyprus',
      ]);
      expect(journey.unmappedEventCount, 6);
      expect(journey.undatedEventCount, 6);
    },
  );

  test(
    "Silas's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('silas_2740'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      // Regression: the Jerusalem Council stops used to carry Silas's real
      // introduction year (~49.0/49.1), which sorted *after* his Second
      // Journey stops (46.0-48.1, matching Paul's internal numbering) and
      // played his journey backwards. Renumbered to 45.8/45.9 so the
      // Council correctly comes first.
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Antioch 1',
        'Antioch 1',
        'Syria 2',
        'Neapolis',
        'Philippi',
        'Thessalonica',
        'Berea',
        'Corinth',
      ]);
      expect(journey.unmappedEventCount, 7);
      expect(journey.undatedEventCount, 7);
    },
  );

  test(
    "Timothy's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('timotheus_2863'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Derbe',
        'Macedonia',
        'Berea',
        'Corinth',
        'Asia',
        'Troas',
        'Rome',
      ]);
      expect(journey.unmappedEventCount, 4);
      expect(journey.undatedEventCount, 7);
    },
  );

  test(
    "Luke's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('luke_1836'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      // Regression: see the 'Arrives in Jerusalem' note on Ezra's test —
      // this Jerusalem stop is Luke's own Acts 21:15, not a merge target.
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Macedonia',
        'Macedonia',
        'Macedonia',
        'Chios',
        'Jerusalem',
        'Caesarea',
        'Malta',
        'Rome',
      ]);
      expect(journey.unmappedEventCount, 11);
      expect(journey.undatedEventCount, 6);
    },
  );

  test(
    "Philip the Evangelist's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('philip_2347'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Antioch 1',
        'Samaria 1',
        'Antioch 1',
        'Gaza',
        'Samaria 1',
        'Gaza',
        'Ashdod',
        'Ashdod',
        'Caesarea',
      ]);
      expect(journey.unmappedEventCount, 1);
      expect(journey.undatedEventCount, 1);
    },
  );

  test(
    "Joshua's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('joshua_893'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Amalek',
        'Mount Sinai',
        'Kadesh-barnea',
        'Jericho 1',
        'Jordan',
        'Gilgal 1',
        'Jericho 1',
        'Ai 1',
        'Mount Ebal',
        'Gibeon',
        'Waters of Merom',
        'Shiloh',
        'Shechem',
        'Gaash',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Jonah's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('jonah_1689'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Nineveh',
        'Gath-hepher',
        'Joppa',
        'Nineveh',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Ezekiel's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('ezekiel_1237'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Babylon 1',
        'Chebar',
        'Babylon 1',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Samuel's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('samuel_2469'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Shiloh',
        'Mizpah 2',
        'Ebenezer 1',
        'Bethel 1',
        'Ramah 1',
        'Zuph',
        'Gilgal 1',
        'Bethlehem 1',
        'Paran',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Saul's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('saul_2478'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Gibeah 1',
        'Bezek 1',
        'Gilgal 1',
        'Zelzah',
        'Bethel 1',
        'Carmel 1',
        'Valley of Elah',
        'Naioth',
        'Wilderness of Ziph',
        'Arabah',
        'Engedi',
        'En-dor',
        'Mount Gilboa',
        'Jordan',
      ]);
      expect(journey.unmappedEventCount, 1);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Ruth's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('ruth_2450'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Moab 1',
        'Bethlehem 1',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Naomi's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('naomi_2147'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Bethlehem 1',
        'Bethlehem 1',
        'Bethlehem 1',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Esther's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('esther_1343'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), ['Susa']);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "John the Baptist's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('john_1676'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Judea 1',
        'Judea 1',
        'Judea 1',
        'Judea 1',
        'Jordan',
        'Jordan',
        'Bethany 2',
        'Galilee 1',
        'Jerusalem',
        'Aenon',
        'Galilee 1',
      ]);
      expect(journey.unmappedEventCount, 1);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "James's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('james_717'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Sea of Galilee',
        'Capernaum',
        'Sea of Galilee',
        'Gethsemane',
        'Jerusalem',
        'Jerusalem',
      ]);
      expect(journey.unmappedEventCount, 2);
      expect(journey.undatedEventCount, 1);
    },
  );

  test(
    "Andrew's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('andrew_264'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Bethsaida 1',
        'Sea of Galilee',
        'Bethany 2',
        'Sea of Galilee',
        'Galilee 1',
        'Bethsaida 2',
        'Jerusalem',
      ]);
      expect(journey.unmappedEventCount, 1);
      expect(journey.undatedEventCount, 2);
    },
  );

  test(
    "Titus's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('titus_2869'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Jerusalem',
        'Macedonia',
        'Corinth',
        'Crete',
        'Nicopolis',
        'Dalmatia',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Apollos's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('apollos_276'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Alexandria',
        'Alexandria',
        'Achaia',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 1);
    },
  );

  test(
    "Ezra's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('ezra_1244'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      // Regression: 'Arrives in Jerusalem' used to collide with Luke's
      // identically-titled Acts 21:15 waypoint, silently merging Ezra's
      // 458 BC return into Luke's AD 54 event. Now titled distinctly, so
      // this must resolve to Ezra's own three curated stops.
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Babylon 1',
        'Ahava',
        'Jerusalem',
      ]);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Nehemiah's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('nehemiah_2171'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), ['Susa', 'Jerusalem']);
      expect(journey.unmappedEventCount, 0);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Abraham's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('abraham_58'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Canaan',
        'Canaan',
        'Moreh 1',
        'Ai 1',
        'Canaan',
        'Ai 1',
        'Hebron',
        'Dan',
        'Damascus',
        'Salem',
        'Gerar',
        'Beersheba 1',
        'Moriah',
        'Beersheba 1',
        'Canaan',
        'Canaan',
        'Egypt',
        'Egypt',
        'Bethel 1',
        'Beer-lahai-roi',
        'Gomorrah',
        'Beersheba 1',
      ]);
      expect(journey.unmappedEventCount, 4);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Isaac's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('isaac_616'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Beersheba 1',
        'Moriah',
        'Beersheba 1',
        'Beer-lahai-roi',
        'Gerar',
        'Valley of Gerar',
        'Beersheba 1',
        'Beersheba 1',
        'Beersheba 1',
        'Hebron',
        'Paddan-aram',
      ]);
      expect(journey.unmappedEventCount, 2);
      expect(journey.undatedEventCount, 0);
    },
  );

  test(
    "Joseph's journey follows the curated waypoints in chronological order",
    () async {
      await container.read(curatedJourneysReadyProvider.future);
      final person = await (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals('joseph_1710'))).getSingle();

      final journey = await container.read(
        personJourneyProvider(person.id).future,
      );
      expect(journey, isNotNull);
      expect(journey!.waypoints.map((w) => w.placeName), [
        'Shechem',
        'Shechem',
        'Dothan',
        'Egypt',
        'Egypt',
        'Egypt',
        'Goshen 1',
        'Canaan',
        'Egypt',
        'Egypt',
        'Shechem',
        'Egypt',
        'Egypt',
        'Egypt',
        'Egypt',
        'Canaan',
        'Egypt',
      ]);
      expect(journey.unmappedEventCount, 1);
      expect(journey.undatedEventCount, 0);
    },
  );
}
