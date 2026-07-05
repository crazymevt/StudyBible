import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/explorer/document_reference_extractor.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';

/// The persisted document-reference index: extraction (domain), the
/// self-healing sweep (any updatedAt bump reindexes, however the row was
/// written — save, sync merge, or restore), and the Explorer backlink
/// providers that query it.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('extractDocumentReferences', () {
    final books = [
      const Book(
        id: 1,
        versionId: 'KJV',
        name: 'Genesis',
        bookOrder: 1,
        testament: 'OT',
      ),
      const Book(
        id: 2,
        versionId: 'KJV',
        name: 'Romans',
        bookOrder: 45,
        testament: 'NT',
      ),
    ];

    test('normalizes citations to chapter spans and dedupes', () {
      final refs = extractDocumentReferences(
        content: '[{"insert":"ignored here\\n"}]',
        plainText: 'Compare Romans 8:28-30 with Romans 8:1 and Gen 1:1-2:3. '
            'Romans 8 again.',
        books: books,
      );
      expect(
        refs.passages.toSet(),
        {
          // All three Romans 8 citations collapse to one 8..8 span.
          const ExtractedPassageReference('Romans', 8, 8),
          const ExtractedPassageReference('Genesis', 1, 2),
        },
      );
      expect(refs.entities, isEmpty);
    });

    test('reads sbent links from the Delta and dedupes', () {
      final content = jsonEncode([
        {
          'insert': 'David',
          'attributes': {'link': 'sbent:person|1'},
        },
        {
          'insert': 'David again',
          'attributes': {'link': 'sbent:person|1'},
        },
        {
          'insert': 'En Gedi',
          'attributes': {'link': 'sbent:place|7'},
        },
        {
          'insert': 'not ours',
          'attributes': {'link': 'https://example.com'},
        },
        {'insert': '\n'},
      ]);
      final refs = extractDocumentReferences(
        content: content,
        plainText: 'David and En Gedi.',
        books: books,
      );
      expect(refs.passages, isEmpty);
      expect(refs.entities, hasLength(2));
    });

    test('an empty book list still extracts entity links', () {
      final refs = extractDocumentReferences(
        content: jsonEncode([
          {
            'insert': 'David',
            'attributes': {'link': 'sbent:person|1'},
          },
          {'insert': ' in Romans 8:1\n'},
        ]),
        plainText: 'David in Romans 8:1',
        books: const [],
      );
      expect(refs.passages, isEmpty);
      expect(refs.entities, hasLength(1));
    });
  });

  group('index sweep and backlink providers', () {
    late ContentStore store;
    late UserStore userStore;
    late ProviderContainer container;

    Future<void> insertSermon(
      String id,
      String plain, {
      int updatedAt = 1,
      List<Map<String, Object?>>? ops,
    }) {
      final content = jsonEncode(ops ?? [{'insert': '$plain\n'}]);
      return userStore.into(userStore.sermons).insert(
            SermonsCompanion(
              id: Value(id),
              createdAt: const Value(0),
              updatedAt: Value(updatedAt),
              deviceId: const Value('test-device'),
              title: Value('Sermon $id'),
              content: Value(content),
              contentPlain: Value(plain),
            ),
          );
    }

    setUp(() async {
      store = ContentStore(NativeDatabase.memory());
      userStore = UserStore(NativeDatabase.memory());

      await store.into(store.versions).insert(
            const VersionsCompanion(
              id: Value('KJV'),
              abbreviation: Value('KJV'),
              name: Value('KJV'),
            ),
          );
      await store.into(store.books).insert(
            const BooksCompanion(
              id: Value(1),
              versionId: Value('KJV'),
              name: Value('Romans'),
              bookOrder: Value(45),
              testament: Value('NT'),
            ),
          );

      SharedPreferences.setMockInitialValues({
        'activeVersions': ['KJV'],
      });
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          contentStoreProvider.overrideWithValue(store),
          userStoreProvider.overrideWithValue(userStore),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await store.close();
      await userStore.close();
    });

    /// Asserts the sermon backlinks for [target] settle to [matcher].
    ///
    /// Riverpod 3 pauses stream-backed providers with no listeners (so a bare
    /// `.future` read never resolves), and a table write propagates through
    /// the stamp stream → index sweep → family chain asynchronously — so this
    /// listens (like an open Explorer page does) and polls until the value
    /// matches or times out. Once it matches, the sweep that produced the
    /// value has fully committed, so direct table assertions are safe after.
    Future<void> expectBacklinks(ExplorerRef target, Object matcher) async {
      final provider = explorerSermonsProvider(target);
      final sub = container.listen(provider, (_, _) {});
      try {
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (true) {
          try {
            final results = await container.read(provider.future);
            expect([for (final r in results) r.referenceId], matcher);
            return;
          } on TestFailure {
            if (DateTime.now().isAfter(deadline)) rethrow;
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
        }
      } finally {
        sub.close();
      }
    }

    test('first sweep backfills pre-existing rows (the migration case)',
        () async {
      // Rows inserted before the indexer ever ran — exactly the state of an
      // upgraded install, where the v29 migration created empty index tables.
      await insertSermon('s1', 'On Romans 8:28 and hope.');
      await insertSermon('s2', 'No citations here.');

      await expectBacklinks(ExplorerRef.passage('Romans', 8), ['s1']);
      final refRows =
          await userStore.select(userStore.documentReferences).get();
      expect(refRows, hasLength(1));
      final stateRows =
          await userStore.select(userStore.documentReferenceStates).get();
      expect(stateRows, hasLength(2)); // s2 recorded as indexed-with-no-refs
    });

    test(
        'a bare row update reindexes — the sync-merge path, which knows '
        'nothing about this index', () async {
      await insertSermon('s1', 'On Romans 8:28.');
      await expectBacklinks(ExplorerRef.passage('Romans', 8), ['s1']);

      // Simulate a remote edit landing via sync: a direct table write that
      // only bumps updatedAt — no action-layer save hook involved.
      await (userStore.update(userStore.sermons)
            ..where((s) => s.id.equals('s1')))
          .write(
        SermonsCompanion(
          updatedAt: const Value(2),
          content: Value(jsonEncode([{'insert': 'Now about Romans 12:1\n'}])),
          contentPlain: const Value('Now about Romans 12:1'),
        ),
      );

      await expectBacklinks(ExplorerRef.passage('Romans', 8), isEmpty);
      await expectBacklinks(ExplorerRef.passage('Romans', 12), ['s1']);
    });

    test('soft delete drops the backlink and the reference rows', () async {
      await insertSermon('s1', 'On Romans 8:28.');
      await expectBacklinks(ExplorerRef.passage('Romans', 8), ['s1']);

      await (userStore.update(userStore.sermons)
            ..where((s) => s.id.equals('s1')))
          .write(
        const SermonsCompanion(deleted: Value(true), updatedAt: Value(2)),
      );

      await expectBacklinks(ExplorerRef.passage('Romans', 8), isEmpty);
      expect(
        await userStore.select(userStore.documentReferences).get(),
        isEmpty,
      );
    });

    test('entity links answer person/place pages exactly', () async {
      await insertSermon(
        's1',
        'David.',
        ops: [
          {
            'insert': 'David',
            'attributes': {'link': 'sbent:person|1'},
          },
          {'insert': '\n'},
        ],
      );
      await expectBacklinks(const ExplorerRef.person(1, 'David'), ['s1']);
      await expectBacklinks(const ExplorerRef.person(2, 'Saul'), isEmpty);
      await expectBacklinks(const ExplorerRef.place(1, 'En Gedi'), isEmpty);
    });

    test('hard-vanished rows are swept out (the restore path)', () async {
      await insertSermon('s1', 'On Romans 8:28.');
      await expectBacklinks(ExplorerRef.passage('Romans', 8), ['s1']);

      // A destructive restore can replace table contents outright. (Via the
      // drift API, as the restore service writes — a raw customStatement
      // wouldn't dispatch the stream notification that wakes the sweep.)
      await (userStore.delete(userStore.sermons)
            ..where((s) => s.id.equals('s1')))
          .go();

      await expectBacklinks(ExplorerRef.passage('Romans', 8), isEmpty);
      // The backlink emptiness comes from the join (the sermon row is gone),
      // so it can precede the orphan cleanup — poll the state table too.
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (true) {
        final states =
            await userStore.select(userStore.documentReferenceStates).get();
        if (states.isEmpty) break;
        if (DateTime.now().isAfter(deadline)) {
          fail('orphaned state rows were not swept out: $states');
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
  });
}
