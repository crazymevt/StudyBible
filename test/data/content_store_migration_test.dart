import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:study_bible/data/content_store.dart';

void main() {
  test(
    'onCreate recovers from an interrupted create (tables present, version 0)',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'content_store_migration',
      );
      final file = File('${dir.path}/content.db');
      try {
        // First open runs the full onCreate and stamps the schema version.
        final store1 = ContentStore(NativeDatabase(file));
        await store1.customSelect('SELECT 1').get(); // force the lazy open
        await store1.close();

        // Simulate an interrupted onCreate: the tables are committed on disk, but
        // drift never got to stamp the schema version. It reads back as 0, so the
        // next open treats the database as fresh and runs onCreate again.
        final raw = sqlite.sqlite3.open(file.path);
        raw.execute('PRAGMA user_version = 0');
        raw.close();

        // The re-run must be idempotent — a plain createAll() would throw
        // "table already exists" here and wedge every future open.
        final store2 = ContentStore(NativeDatabase(file));
        final row = await store2
            .customSelect('SELECT count(*) AS c FROM versions')
            .getSingle();
        expect(row.read<int>('c'), 0);
        await store2.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'the v14 migration heals people/topics missing from content_search',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'content_store_migration_v14',
      );
      final file = File('${dir.path}/content.db');
      try {
        // A pre-14 install: bible_people/topics rows exist (the datasets were
        // imported) but content_search was never backfilled for them — the
        // exact legacy state TheographicImporter/TopicalImporter's removed
        // per-launch self-heal used to detect and fix.
        final store1 = ContentStore(NativeDatabase(file));
        await store1.into(store1.biblePeople).insert(
              BiblePeopleCompanion.insert(
                slug: 'david',
                name: 'David',
                displayTitle: 'David',
                verseCount: 0,
              ),
            );
        await store1.into(store1.topics).insert(
              TopicsCompanion.insert(name: 'AARON', section: 'A'),
            );
        await store1.close();

        final raw = sqlite.sqlite3.open(file.path);
        raw.execute('PRAGMA user_version = 13');
        raw.close();

        // Opening at schema 14 must run the one-time backfill.
        final store2 = ContentStore(NativeDatabase(file));
        await store2.customSelect('SELECT 1').get(); // force the migration

        final person = await store2
            .customSelect(
              "SELECT text_content AS t FROM content_search WHERE type = 'person'",
            )
            .getSingle();
        expect(person.read<String>('t'), contains('David'));

        final topic = await store2
            .customSelect(
              "SELECT text_content AS t FROM content_search WHERE type = 'topic'",
            )
            .getSingle();
        expect(topic.read<String>('t'), 'AARON');

        await store2.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'the v14 migration is a no-op when content_search is already populated',
    () async {
      // Guards against double-indexing (duplicate rows) if the migration ever
      // ran against a DB that was already healed some other way.
      final dir = await Directory.systemTemp.createTemp(
        'content_store_migration_v14_noop',
      );
      final file = File('${dir.path}/content.db');
      try {
        final store1 = ContentStore(NativeDatabase(file));
        await store1.into(store1.biblePeople).insert(
              BiblePeopleCompanion.insert(
                slug: 'david',
                name: 'David',
                displayTitle: 'David',
                verseCount: 0,
              ),
            );
        await store1.customStatement(
          "INSERT INTO content_search(type, reference_id, text_content) "
          "VALUES ('person', 1, 'David')",
        );
        await store1.close();

        final raw = sqlite.sqlite3.open(file.path);
        raw.execute('PRAGMA user_version = 13');
        raw.close();

        final store2 = ContentStore(NativeDatabase(file));
        await store2.customSelect('SELECT 1').get();

        final rows = await store2
            .customSelect(
              "SELECT count(*) AS c FROM content_search WHERE type = 'person'",
            )
            .getSingle();
        expect(rows.read<int>('c'), 1);

        await store2.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
