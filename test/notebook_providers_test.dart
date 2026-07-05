import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/notebook_providers.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

String _delta(String text) => jsonEncode([
  {'insert': '$text\n'},
]);

void main() {
  late UserStore store;
  late ProviderContainer container;

  setUp(() {
    store = UserStore(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        userStoreProvider.overrideWithValue(store),
        deviceIdProvider.overrideWith((ref) async => 'A'),
        achievementServiceProvider.overrideWith(
          (ref) => _NoopAchievementService(ref),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  group('NotebookActionNotifier', () {
    test('creates a notebook with cover colour and icon', () async {
      final actions = container.read(notebookActionProvider);
      final nb = await actions.createNotebook(
        'Romans Study',
        colorHex: '#1E88E5',
        iconKey: 'book',
      );
      expect(nb.title, 'Romans Study');
      expect(nb.colorHex, '#1E88E5');
      expect(nb.iconKey, 'book');
      expect(nb.pinned, isFalse);
      expect(nb.deleted, isFalse);
    });

    test(
      'new pages append at the end and derive contentPlain for FTS',
      () async {
        final actions = container.read(notebookActionProvider);
        final nb = await actions.createNotebook('N');

        final p1 = await actions.createPage(
          nb.id,
          title: 'One',
          content: _delta('first page body'),
        );
        final p2 = await actions.createPage(nb.id, title: 'Two');

        expect(p1.position, 0);
        expect(p2.position, 1);
        // contentPlain is the plain-text projection used by the FTS index.
        expect(p1.contentPlain, contains('first page body'));
      },
    );

    test('reorderPages rewrites positions to the given order', () async {
      final actions = container.read(notebookActionProvider);
      final nb = await actions.createNotebook('N');
      final a = await actions.createPage(nb.id, title: 'A');
      final b = await actions.createPage(nb.id, title: 'B');
      final c = await actions.createPage(nb.id, title: 'C');

      // Move C to the front: [C, A, B].
      await actions.reorderPages([c.id, a.id, b.id]);

      final pages = await (store.select(
        store.notebookPages,
      )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
      expect(pages.map((p) => p.title).toList(), ['C', 'A', 'B']);
    });

    test('deleting a notebook soft-deletes it and its pages', () async {
      final actions = container.read(notebookActionProvider);
      final nb = await actions.createNotebook('N');
      await actions.createPage(nb.id, title: 'A');
      await actions.createPage(nb.id, title: 'B');

      await actions.deleteNotebook(nb.id);

      final nbRow = await (store.select(
        store.notebooks,
      )..where((t) => t.id.equals(nb.id))).getSingle();
      expect(nbRow.deleted, isTrue);
      final livePages =
          await (store.select(store.notebookPages)
                ..where((t) => t.notebookId.equals(nb.id))
                ..where((t) => t.deleted.equals(false)))
              .get();
      expect(livePages, isEmpty);
    });

    test(
      'updatePage returns a fresh updatedAt and reprojects contentPlain',
      () async {
        final actions = container.read(notebookActionProvider);
        final nb = await actions.createNotebook('N');
        final page = await actions.createPage(nb.id, content: _delta('old'));

        final ts = await actions.updatePage(
          page.id,
          content: _delta('new body'),
        );
        final row = await (store.select(
          store.notebookPages,
        )..where((t) => t.id.equals(page.id))).getSingle();
        expect(row.updatedAt, ts);
        expect(row.contentPlain, contains('new body'));
      },
    );
  });

  group('notebook page FTS indexing', () {
    test('a page is searchable by its plain text', () async {
      final actions = container.read(notebookActionProvider);
      final nb = await actions.createNotebook('N');
      await actions.createPage(
        nb.id,
        title: 'Grace',
        content: _delta('justification by faith'),
      );

      final rows = await store
          .customSelect(
            "SELECT reference_id FROM user_search "
            "WHERE type = 'notebookPage' AND user_search MATCH 'justification'",
          )
          .get();
      expect(rows, isNotEmpty);
    });

    test('soft-deleting a page removes it from the FTS index', () async {
      final actions = container.read(notebookActionProvider);
      final nb = await actions.createNotebook('N');
      final page = await actions.createPage(
        nb.id,
        title: 'Grace',
        content: _delta('unique_token_xyz'),
      );

      await actions.deletePage(page.id);

      final rows = await store
          .customSelect(
            "SELECT reference_id FROM user_search "
            "WHERE type = 'notebookPage' AND user_search MATCH 'unique_token_xyz'",
          )
          .get();
      expect(rows, isEmpty);
    });
  });
}
