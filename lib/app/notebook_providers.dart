import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../data/user_store.dart';
import '../data/fts_text.dart';
import 'tag_providers.dart';
import 'user_providers.dart';
import 'sync_service.dart'; // for deviceIdProvider
import 'achievement_service.dart';
import 'revision_common.dart';

/// All non-deleted notebooks, newest-first. The panel filters/sorts client-side
/// (pinned float to the top) like the sermons list.
final allNotebooksProvider = StreamProvider<List<Notebook>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.notebooks)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)]))
      .watch();
});

/// All non-deleted notebook pages across every notebook, unordered. Used by
/// the Explorer's "Your notebooks" backlink cards, which need to scan every
/// page's content regardless of which notebook it's filed under. Deleting a
/// notebook cascades to soft-delete its pages, so filtering on `deleted` alone
/// (no join to `notebooks`) is enough to exclude pages of a deleted notebook.
final allNotebookPagesProvider = StreamProvider<List<NotebookPage>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.notebookPages)
        ..where((t) => t.deleted.equals(false)))
      .watch();
});

/// Tags for every notebook at once, as `notebookId -> tags` (each list sorted by
/// name). Mirrors [sermonTagsProvider].
final notebookTagsProvider = StreamProvider<Map<String, List<TagData>>>((ref) {
  final store = ref.watch(userStoreProvider);
  final query =
      store.select(store.entityTags).join([
          drift.innerJoin(
            store.tags,
            store.tags.id.equalsExp(store.entityTags.tagId),
          ),
        ])
        ..where(store.entityTags.entityType.equals('notebook'))
        ..where(store.entityTags.deleted.equals(false))
        ..where(store.tags.deleted.equals(false));

  return query.watch().map((rows) {
    final map = <String, List<TagData>>{};
    for (final row in rows) {
      final et = row.readTable(store.entityTags);
      final t = row.readTable(store.tags);
      (map[et.entityId] ??= []).add(
        TagData(id: t.id, name: t.name, colorHex: t.colorHex),
      );
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return map;
  });
});

/// Watches a single notebook row (including soft-deletes).
final notebookByIdProvider = StreamProvider.family<Notebook?, String>((ref, id) {
  final store = ref.watch(userStoreProvider);
  return (store.select(
    store.notebooks,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();
});

/// Live, position-ordered list of a notebook's pages (non-deleted).
final pagesForNotebookProvider =
    StreamProvider.family<List<NotebookPage>, String>((ref, notebookId) {
      final store = ref.watch(userStoreProvider);
      return (store.select(store.notebookPages)
            ..where(
              (t) => t.notebookId.equals(notebookId) & t.deleted.equals(false),
            )
            ..orderBy([
              (t) => drift.OrderingTerm.asc(t.position),
              (t) => drift.OrderingTerm.asc(t.createdAt),
            ]))
          .watch();
    });

/// Tags for every page of a notebook at once, as `pageId -> tags`.
final pageTagsForNotebookProvider =
    StreamProvider.family<Map<String, List<TagData>>, String>((
      ref,
      notebookId,
    ) {
      final store = ref.watch(userStoreProvider);
      // Join entity_tags -> tags, then restrict to pages of this notebook.
      final query =
          store.select(store.entityTags).join([
              drift.innerJoin(
                store.tags,
                store.tags.id.equalsExp(store.entityTags.tagId),
              ),
              drift.innerJoin(
                store.notebookPages,
                store.notebookPages.id.equalsExp(store.entityTags.entityId),
              ),
            ])
            ..where(store.entityTags.entityType.equals('notebookPage'))
            ..where(store.entityTags.deleted.equals(false))
            ..where(store.tags.deleted.equals(false))
            ..where(store.notebookPages.notebookId.equals(notebookId));

      return query.watch().map((rows) {
        final map = <String, List<TagData>>{};
        for (final row in rows) {
          final et = row.readTable(store.entityTags);
          final t = row.readTable(store.tags);
          (map[et.entityId] ??= []).add(
            TagData(id: t.id, name: t.name, colorHex: t.colorHex),
          );
        }
        for (final list in map.values) {
          list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        }
        return map;
      });
    });

/// Watches a single page row (including soft-deletes). The editor uses this to
/// notice when a remote sync overwrites the page while it's open.
final notebookPageByIdProvider =
    StreamProvider.family<NotebookPage?, String>((ref, id) {
      final store = ref.watch(userStoreProvider);
      return (store.select(
        store.notebookPages,
      )..where((t) => t.id.equals(id))).watchSingleOrNull();
    });

/// Live, newest-first list of a page's saved revisions.
final notebookPageRevisionsProvider =
    StreamProvider.family<List<NotebookPageRevision>, String>((ref, pageId) {
      final store = ref.watch(userStoreProvider);
      return (store.select(store.notebookPageRevisions)
            ..where((t) => t.pageId.equals(pageId) & t.deleted.equals(false))
            ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
          .watch();
    });

class SelectedNotebookIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final selectedNotebookIdProvider =
    NotifierProvider<SelectedNotebookIdNotifier, String?>(
      () => SelectedNotebookIdNotifier(),
    );

class SelectedNotebookPageIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final selectedNotebookPageIdProvider =
    NotifierProvider<SelectedNotebookPageIdNotifier, String?>(
      () => SelectedNotebookPageIdNotifier(),
    );

class NotebookActionNotifier {
  final Ref _ref;
  final UserStore _store;

  NotebookActionNotifier(this._ref, this._store);

  Future<Notebook> createNotebook(
    String title, {
    String? colorHex,
    String? iconKey,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deviceId = await _ref.read(deviceIdProvider.future);
    final notebook = NotebooksCompanion.insert(
      id: const Uuid().v4(),
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      title: title,
      colorHex: drift.Value(colorHex),
      iconKey: drift.Value(iconKey),
    );
    await _store.into(_store.notebooks).insert(notebook);
    _ref.read(achievementServiceProvider).evaluateAchievements();
    return (await (_store.select(
      _store.notebooks,
    )..where((t) => t.id.equals(notebook.id.value))).getSingle());
  }

  Future<void> updateNotebook(
    String id, {
    String? title,
    // Use a wrapped value so a caller can explicitly clear the color/icon.
    drift.Value<String?> colorHex = const drift.Value.absent(),
    drift.Value<String?> iconKey = const drift.Value.absent(),
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.notebooks)..where((t) => t.id.equals(id))).write(
      NotebooksCompanion(
        updatedAt: drift.Value(now),
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        colorHex: colorHex,
        iconKey: iconKey,
      ),
    );
  }

  /// Pins or unpins a notebook. Bumps [updatedAt] so the pin syncs (LWW).
  Future<void> setPinned(String id, bool pinned) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.notebooks)..where((t) => t.id.equals(id))).write(
      NotebooksCompanion(pinned: drift.Value(pinned), updatedAt: drift.Value(now)),
    );
  }

  /// Soft-deletes a notebook and all of its pages, and strips every associated
  /// tag (notebook + each page).
  Future<void> deleteNotebook(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pages = await (_store.select(
      _store.notebookPages,
    )..where((t) => t.notebookId.equals(id))).get();

    await (_store.update(_store.notebooks)..where((t) => t.id.equals(id))).write(
      NotebooksCompanion(
        deleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );
    await (_store.update(
      _store.notebookPages,
    )..where((t) => t.notebookId.equals(id))).write(
      NotebookPagesCompanion(
        deleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );

    final tags = _ref.read(tagControllerProvider);
    await tags.removeAllTagsFromEntity(id);
    for (final page in pages) {
      await tags.removeAllTagsFromEntity(page.id);
    }
  }

  // --- Pages ---

  Future<NotebookPage> createPage(
    String notebookId, {
    String title = 'Untitled Page',
    String? content,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deviceId = await _ref.read(deviceIdProvider.future);
    final effectiveContent = content ?? '[{"insert":"\\n"}]';
    // Append to the end: one past the current max position.
    final existing = await (_store.select(_store.notebookPages)
          ..where((t) => t.notebookId.equals(notebookId) & t.deleted.equals(false)))
        .get();
    final nextPosition = existing.isEmpty
        ? 0
        : existing.map((p) => p.position).reduce((a, b) => a > b ? a : b) + 1;
    final page = NotebookPagesCompanion.insert(
      id: const Uuid().v4(),
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      notebookId: notebookId,
      title: title,
      content: effectiveContent,
      contentPlain: drift.Value(deltaToPlainText(effectiveContent)),
      position: drift.Value(nextPosition),
    );
    await _store.into(_store.notebookPages).insert(page);
    // Bump the notebook so it floats up the list and syncs as recently touched.
    await _touchNotebook(notebookId, now);
    return (await (_store.select(
      _store.notebookPages,
    )..where((t) => t.id.equals(page.id.value))).getSingle());
  }

  /// Writes the supplied fields and returns the `updatedAt` timestamp stamped on
  /// the row so the editor can tell its own saves apart from a remote edit.
  Future<int> updatePage(
    String id, {
    String? title,
    String? content,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.notebookPages)..where((t) => t.id.equals(id)))
        .write(
      NotebookPagesCompanion(
        updatedAt: drift.Value(now),
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        content: content != null
            ? drift.Value(content)
            : const drift.Value.absent(),
        contentPlain: content != null
            ? drift.Value(deltaToPlainText(content))
            : const drift.Value.absent(),
      ),
    );
    return now;
  }

  Future<void> deletePage(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.notebookPages)..where((t) => t.id.equals(id)))
        .write(
      NotebookPagesCompanion(
        deleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );
    await _ref.read(tagControllerProvider).removeAllTagsFromEntity(id);
  }

  /// Persists a new page order. [orderedIds] is the full list of a notebook's
  /// page ids in their desired order; each page's [position] is rewritten to its
  /// index. Only pages whose position actually changes are written (and bump
  /// updatedAt so the new order syncs).
  Future<void> reorderPages(List<String> orderedIds) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final current = await (_store.select(
        _store.notebookPages,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (current == null || current.position == i) continue;
      await (_store.update(_store.notebookPages)..where((t) => t.id.equals(id)))
          .write(
        NotebookPagesCompanion(
          position: drift.Value(i),
          updatedAt: drift.Value(now),
        ),
      );
    }
  }

  Future<void> _touchNotebook(String notebookId, int now) async {
    await (_store.update(_store.notebooks)
          ..where((t) => t.id.equals(notebookId)))
        .write(NotebooksCompanion(updatedAt: drift.Value(now)));
  }
}

final notebookActionProvider = Provider<NotebookActionNotifier>((ref) {
  final store = ref.watch(userStoreProvider);
  return NotebookActionNotifier(ref, store);
});

class NotebookPageRevisionActionNotifier {
  final Ref _ref;
  final UserStore _store;

  NotebookPageRevisionActionNotifier(this._ref, this._store);

  /// Captures [content] (plus title) as a revision of [pageId]. Automatic kinds
  /// are pruned to [kMaxAutoRevisions] per page afterward; manual revisions are
  /// kept indefinitely. Mirrors [SermonRevisionActionNotifier.saveRevision].
  Future<void> saveRevision({
    required String pageId,
    required String title,
    required String content,
    String? label,
    String kind = RevisionKind.manual,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deviceId = await _ref.read(deviceIdProvider.future);
    if (kind != RevisionKind.manual) {
      final existing =
          await (_store.select(_store.notebookPageRevisions)..where(
                (t) =>
                    t.pageId.equals(pageId) &
                    t.deleted.equals(false) &
                    t.content.equals(content),
              ))
              .get();
      if (existing.isNotEmpty) return;
    }
    await _store
        .into(_store.notebookPageRevisions)
        .insert(
          NotebookPageRevisionsCompanion.insert(
            id: const Uuid().v4(),
            updatedAt: now,
            deviceId: deviceId,
            createdAt: now,
            pageId: pageId,
            title: title,
            content: content,
            label: drift.Value(label),
            kind: kind,
          ),
        );
    if (kind != RevisionKind.manual) {
      await _pruneAutoRevisions(pageId);
    }
  }

  /// Restores [revisionId] into its page. The page's current content is first
  /// snapshotted as a [RevisionKind.restore] revision so the restore is itself
  /// reversible.
  Future<void> restoreRevision(String revisionId) async {
    final revision = await (_store.select(
      _store.notebookPageRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (revision == null) return;
    final page = await (_store.select(
      _store.notebookPages,
    )..where((t) => t.id.equals(revision.pageId))).getSingleOrNull();
    if (page == null) return;

    await saveRevision(
      pageId: page.id,
      title: page.title,
      content: page.content,
      kind: RevisionKind.restore,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(
      _store.notebookPages,
    )..where((t) => t.id.equals(page.id))).write(
      NotebookPagesCompanion(
        updatedAt: drift.Value(now),
        title: drift.Value(revision.title),
        content: drift.Value(revision.content),
        contentPlain: drift.Value(deltaToPlainText(revision.content)),
      ),
    );
  }

  Future<void> deleteRevision(String revisionId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(
      _store.notebookPageRevisions,
    )..where((t) => t.id.equals(revisionId))).write(
      NotebookPageRevisionsCompanion(
        deleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );
  }

  Future<void> _pruneAutoRevisions(String pageId) async {
    final auto =
        await (_store.select(_store.notebookPageRevisions)
              ..where(
                (t) =>
                    t.pageId.equals(pageId) &
                    t.deleted.equals(false) &
                    t.kind.equals(RevisionKind.manual).not(),
              )
              ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
            .get();
    if (auto.length <= kMaxAutoRevisions) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final stale in auto.skip(kMaxAutoRevisions)) {
      await (_store.update(
        _store.notebookPageRevisions,
      )..where((t) => t.id.equals(stale.id))).write(
        NotebookPageRevisionsCompanion(
          deleted: const drift.Value(true),
          updatedAt: drift.Value(now),
        ),
      );
    }
  }
}

final notebookPageRevisionActionProvider =
    Provider<NotebookPageRevisionActionNotifier>((ref) {
      final store = ref.watch(userStoreProvider);
      return NotebookPageRevisionActionNotifier(ref, store);
    });
