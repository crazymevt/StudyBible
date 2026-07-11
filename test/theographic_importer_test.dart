import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/theographic_importer.dart';

/// Runs the real importer against the real bundled asset: parse, insert,
/// FTS indexing, and idempotency — the exact path a fresh install takes the
/// first time people data is needed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentStore store;

  setUp(() {
    store = ContentStore(NativeDatabase.memory());
  });

  tearDown(() async {
    await store.close();
  });

  test('imports the bundled dataset and indexes people for search', () async {
    final importer = TheographicImporter(store);
    await importer.ensureLoaded();

    final people = await store.select(store.biblePeople).get();
    expect(people.length, greaterThan(3000));

    final aaron = people.firstWhere((p) => p.slug == 'aaron_1');
    expect(aaron.displayTitle, 'Aaron');
    expect(aaron.bio, contains('eldest son of Amram'));
    final father = await (store.select(
      store.biblePeople,
    )..where((p) => p.id.equals(aaron.fatherId!))).getSingle();
    expect(father.name, 'Amram');

    // Aaron's verse links landed with real book names.
    final firstVerse =
        await (store.select(store.personVerses)
              ..where((v) => v.personId.equals(aaron.id))
              ..limit(1))
            .getSingle();
    expect(firstVerse.bookName, 'Exodus');

    // Names (including alternate names) are searchable via the global FTS.
    final hit = await store
        .customSelect(
          "SELECT reference_id FROM content_search "
          "WHERE type = 'person' AND content_search MATCH '\"Aaron\"' LIMIT 5",
        )
        .get();
    expect(hit, isNotEmpty);

    // Events imported in chronological order.
    final firstEvent = await (store.select(
      store.timelineEvents,
    )..where((e) => e.id.equals(1))).getSingle();
    expect(firstEvent.title, contains('Creation'));

    // Second call is a no-op, not a duplicate import.
    await importer.ensureLoaded();
    final recount = await store.select(store.biblePeople).get();
    expect(recount.length, people.length);
  });

  test('the v17 upgrade block patches Seth\'s deathYear in place', () async {
    // Installs that imported people before the upstream fix
    // (build_theographic.dart's _knownBadDeathYears) are stuck with Seth's
    // old, wrong deathYear forever: TheographicImporter only seeds
    // bible_people once, on an empty table, so a corrected asset can never
    // reach an already-populated install on its own. Simulate that install
    // by seeding the pre-fix row directly, then replay the `from < 17`
    // migration block that's supposed to correct it in place.
    await store
        .into(store.biblePeople)
        .insert(
          const BiblePeopleCompanion(
            id: Value(1),
            slug: Value('seth_2504'),
            name: Value('Seth'),
            displayTitle: Value('Seth'),
            birthYear: Value(-3874),
            deathYear: Value(-2692),
            verseCount: Value(0),
          ),
        );

    await store.migration.onUpgrade(store.createMigrator(), 16, 17);

    final seth = await (store.select(
      store.biblePeople,
    )..where((p) => p.slug.equals('seth_2504'))).getSingle();
    expect(seth.deathYear, -2962);
  });

  test(
    'the v18 upgrade block clears Samson/Ahaziah/Jehoram\'s contradictory years',
    () async {
      // Same problem as the v17 test, for three rows whose upstream
      // birthYear/deathYear contradict each other outright (death before
      // birth) with no clear correct value to substitute — see
      // build_theographic.dart's _unreliableLifespans. Seed the pre-fix
      // rows, then replay the `from < 18` block that should null both years.
      await store.batch((batch) {
        batch.insertAll(store.biblePeople, [
          const BiblePeopleCompanion(
            id: Value(1),
            slug: Value('samson_2468'),
            name: Value('Samson'),
            displayTitle: Value('Samson'),
            birthYear: Value(-1090),
            deathYear: Value(-1101),
            verseCount: Value(0),
          ),
          const BiblePeopleCompanion(
            id: Value(2),
            slug: Value('ahaziah_121'),
            name: Value('Ahaziah'),
            displayTitle: Value('Ahaziah'),
            birthYear: Value(-822),
            deathYear: Value(-844),
            verseCount: Value(0),
          ),
          const BiblePeopleCompanion(
            id: Value(3),
            slug: Value('jehoram_803'),
            name: Value('Jehoram'),
            displayTitle: Value('Jehoram'),
            birthYear: Value(-802),
            deathYear: Value(-844),
            verseCount: Value(0),
          ),
        ]);
      });

      await store.migration.onUpgrade(store.createMigrator(), 17, 18);

      for (final slug in ['samson_2468', 'ahaziah_121', 'jehoram_803']) {
        final row = await (store.select(
          store.biblePeople,
        )..where((p) => p.slug.equals(slug))).getSingle();
        expect(row.birthYear, isNull, reason: slug);
        expect(row.deathYear, isNull, reason: slug);
      }
    },
  );

  test(
    "the v19 upgrade block fixes Joshua/Rachel/Manasseh/Ahaz's years",
    () async {
      // Same problem again, for four more rows — see
      // build_theographic.dart's _knownBadDeathYears, _unreliableBirthYears,
      // and _unreliableLifespans for the sourcing behind each value. Seed
      // the pre-fix rows, then replay the `from < 19` block.
      await store.batch((batch) {
        batch.insertAll(store.biblePeople, [
          const BiblePeopleCompanion(
            id: Value(1),
            slug: Value('joshua_1727'),
            name: Value('Joshua'),
            displayTitle: Value('Joshua'),
            birthYear: Value(-1521),
            deathYear: Value(-1424),
            verseCount: Value(0),
          ),
          const BiblePeopleCompanion(
            id: Value(2),
            slug: Value('rachel_2386'),
            name: Value('Rachel'),
            displayTitle: Value('Rachel'),
            birthYear: Value(-1755),
            deathYear: Value(-1739),
            verseCount: Value(0),
          ),
          const BiblePeopleCompanion(
            id: Value(3),
            slug: Value('manasseh_1930'),
            name: Value('Manasseh'),
            displayTitle: Value('Manasseh (son of Hezekiah)'),
            birthYear: Value(-677),
            deathYear: Value(-642),
            verseCount: Value(0),
          ),
          const BiblePeopleCompanion(
            id: Value(4),
            slug: Value('ahaz_118'),
            name: Value('Ahaz'),
            displayTitle: Value('Ahaz'),
            birthYear: Value(-763),
            deathYear: Value(-716),
            verseCount: Value(0),
          ),
        ]);
      });

      await store.migration.onUpgrade(store.createMigrator(), 18, 19);

      Future<BiblePerson> row(String slug) => (store.select(
        store.biblePeople,
      )..where((p) => p.slug.equals(slug))).getSingle();

      final joshua = await row('joshua_1727');
      expect(joshua.birthYear, -1521);
      expect(joshua.deathYear, -1411);

      final rachel = await row('rachel_2386');
      expect(rachel.birthYear, isNull);
      expect(rachel.deathYear, -1739);

      for (final slug in ['manasseh_1930', 'ahaz_118']) {
        final p = await row(slug);
        expect(p.birthYear, isNull, reason: slug);
        expect(p.deathYear, isNull, reason: slug);
      }
    },
  );
}
