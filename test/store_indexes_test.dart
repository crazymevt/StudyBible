import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';

/// Guards the hot-path indexes added for large-database loading times (user
/// store v28, content store v13). A fresh store must carry every index, and
/// the queries they exist for must actually use them — a schema tweak that
/// silently drops one back to a full table scan should fail here.
void main() {
  Future<Set<String>> indexNames(
    Future<List<Map<String, Object?>>> Function(String sql) query,
  ) async {
    final rows = await query(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
    );
    return {for (final r in rows) r['name']! as String};
  }

  group('UserStore indexes', () {
    late UserStore store;

    setUp(() => store = UserStore(NativeDatabase.memory()));
    tearDown(() => store.close());

    test('a fresh store has every hot-path index', () async {
      final names = await indexNames(
        (sql) async => [
          for (final row in await store.customSelect(sql).get()) row.data,
        ],
      );
      expect(
        names,
        containsAll({
          'idx_highlight_location',
          'idx_note_location',
          'idx_bookmark_location',
          'idx_journal_revision_journal',
          'idx_sermon_revision_sermon',
          'idx_navigation_history_updated',
          'idx_entity_tag_tag',
          'idx_entity_tag_entity',
          'idx_entity_tag_type',
          'idx_notebook_page_notebook',
          'idx_notebook_page_revision_page',
          'idx_attachment_ref_location',
          'idx_attachment_ref_attachment',
        }),
      );
    });

    test('chapter highlight lookups use the location index', () async {
      final plan = await store
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT * FROM highlights "
            "WHERE book_name = 'John' AND chapter = 3 AND deleted = 0",
          )
          .get();
      final detail = plan.map((r) => r.data['detail']).join('\n');
      expect(detail, contains('idx_highlight_location'));
    });

    test('the v28 upgrade block recreates every index', () async {
      // A fresh store gets its indexes from createAll; upgrading installs get
      // them from the raw SQL in the `from < 28` block. Drop them all, replay
      // that block, and require the same end state — catching any typo in the
      // raw statements that the annotation-driven path would mask.
      final before = await store
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
          )
          .get();
      expect(before, isNotEmpty);
      for (final row in before) {
        await store.customStatement('DROP INDEX ${row.data['name']}');
      }
      await store.migration.onUpgrade(store.createMigrator(), 27, 28);
      final after = await store
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
          )
          .get();
      expect(
        {for (final r in after) r.data['name']},
        {for (final r in before) r.data['name']},
      );
    });

    test('tag entity lookups use the tag index', () async {
      final plan = await store
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT * FROM entity_tags "
            "WHERE tag_id = 'abc' AND deleted = 0",
          )
          .get();
      final detail = plan.map((r) => r.data['detail']).join('\n');
      expect(detail, contains('idx_entity_tag_tag'));
    });
  });

  group('ContentStore indexes', () {
    late ContentStore store;

    setUp(() => store = ContentStore(NativeDatabase.memory()));
    tearDown(() => store.close());

    test('a fresh store has every hot-path index', () async {
      final names = await indexNames(
        (sql) async => [
          for (final row in await store.customSelect(sql).get()) row.data,
        ],
      );
      expect(
        names,
        containsAll({
          'idx_verses_location',
          'idx_commentary_entry_location',
          'idx_commentary_entry_commentary',
          'idx_dictionary_entry_word',
          'idx_subheading_location',
          'idx_topic_entry_topic',
          'idx_topic_ref_topic',
          'idx_place_verse_place',
          'idx_event_verse_location',
          'idx_event_verse_event',
          // Pre-existing indexes must survive the v13 additions.
          'idx_topic_ref_location',
          'idx_place_verse_location',
          'idx_person_verse_location',
          'idx_person_verse_person',
          'idx_cross_references_source',
        }),
      );
    });

    test('the v13 upgrade block recreates its indexes', () async {
      // Same guard as the user-store upgrade test: replay the `from < 13` raw
      // SQL after dropping the indexes it should create.
      const v13Indexes = {
        'idx_verses_location',
        'idx_commentary_entry_location',
        'idx_commentary_entry_commentary',
        'idx_dictionary_entry_word',
        'idx_subheading_location',
        'idx_topic_entry_topic',
        'idx_topic_ref_topic',
        'idx_place_verse_place',
        'idx_event_verse_location',
        'idx_event_verse_event',
      };
      for (final name in v13Indexes) {
        await store.customStatement('DROP INDEX $name');
      }
      await store.migration.onUpgrade(store.createMigrator(), 12, 13);
      final after = await store
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
          )
          .get();
      expect({for (final r in after) r.data['name']}, containsAll(v13Indexes));
    });

    test('chapter verse loads use the location index', () async {
      final plan = await store
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM verses '
            'WHERE book_id = 1 AND chapter = 3',
          )
          .get();
      final detail = plan.map((r) => r.data['detail']).join('\n');
      expect(detail, contains('idx_verses_location'));
    });

    test('commentary chapter lookups use the location index', () async {
      final plan = await store
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT * FROM commentary_entries "
            "WHERE book_name = 'John' AND chapter = 3",
          )
          .get();
      final detail = plan.map((r) => r.data['detail']).join('\n');
      expect(detail, contains('idx_commentary_entry_location'));
    });

    test('no-wildcard LIKE headword lookups use the NOCASE index', () async {
      final plan = await store
          .customSelect(
            "EXPLAIN QUERY PLAN SELECT * FROM dictionary_entries "
            "WHERE word LIKE 'Aaron'",
          )
          .get();
      final detail = plan.map((r) => r.data['detail']).join('\n');
      expect(detail, contains('idx_dictionary_entry_word'));
    });
  });
}
