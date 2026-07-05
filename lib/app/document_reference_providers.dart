import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content_store.dart' show Book;
import '../data/fts_text.dart';
import '../data/user_store.dart';
import '../domain/explorer/document_reference_extractor.dart';
import 'content_providers.dart';
import 'reader_state.dart';
import 'user_providers.dart';

/// The `doc_type` discriminators in `document_references` /
/// `document_reference_states`. The notebook value matches the
/// SearchResult/user_search type string so the Explorer's cards stay
/// consistent.
const kDocTypeSermon = 'sermon';
const kDocTypeNotebookPage = 'notebookPage';

/// The columns the staleness diff needs — deliberately *not* the full row, so
/// watching every sermon/page stays cheap no matter how large their content
/// blobs grow.
class _DocStamp {
  final String id;
  final int updatedAt;
  final bool deleted;
  const _DocStamp(this.id, this.updatedAt, this.deleted);
}

final _sermonStampsProvider = StreamProvider<List<_DocStamp>>((ref) {
  final db = ref.watch(userStoreProvider);
  final q = db.selectOnly(db.sermons)
    ..addColumns([db.sermons.id, db.sermons.updatedAt, db.sermons.deleted]);
  return q.watch().map(
        (rows) => [
          for (final r in rows)
            _DocStamp(
              r.read(db.sermons.id)!,
              r.read(db.sermons.updatedAt)!,
              r.read(db.sermons.deleted)!,
            ),
        ],
      );
});

final _notebookPageStampsProvider = StreamProvider<List<_DocStamp>>((ref) {
  final db = ref.watch(userStoreProvider);
  final q = db.selectOnly(db.notebookPages)
    ..addColumns([
      db.notebookPages.id,
      db.notebookPages.updatedAt,
      db.notebookPages.deleted,
    ]);
  return q.watch().map(
        (rows) => [
          for (final r in rows)
            _DocStamp(
              r.read(db.notebookPages.id)!,
              r.read(db.notebookPages.updatedAt)!,
              r.read(db.notebookPages.deleted)!,
            ),
        ],
      );
});

/// Keeps the persisted `document_references` index in step with the sermons
/// and notebook_pages tables, then completes. The Explorer's backlink
/// providers await this before querying the index.
///
/// Self-healing by design: a document is (re)indexed whenever its state row
/// is missing or records a different `updatedAt`/scan version than the live
/// row. Local saves, sync merges, revision restores, and backup restores all
/// bump `updatedAt`, so none of those paths need to know this index exists —
/// and the very first sweep after the v29 migration doubles as the backfill.
/// Re-runs automatically on any sermon/page write (via the stamp streams) and
/// on an active-version change (citations re-resolve against the new book
/// list).
final documentReferenceIndexProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(userStoreProvider);
  final sermonStamps = await ref.watch(_sermonStampsProvider.future);
  final pageStamps = await ref.watch(_notebookPageStampsProvider.future);

  // The book list citations resolve against — same source the live scan used.
  // With no version installed, entity links still index; scanVersion '' marks
  // the rows so installing a version later re-scans everything.
  final versions = ref.watch(activeVersionsProvider);
  var books = const <Book>[];
  var scanVersion = '';
  if (versions.isNotEmpty) {
    books = await ref.watch(booksForVersionProvider(versions.first).future);
    if (books.isNotEmpty) scanVersion = versions.first;
  }

  final states = await db.select(db.documentReferenceStates).get();
  final stateByKey = {
    for (final s in states) '${s.docType}|${s.docId}': s,
  };

  Future<void> sweep({
    required String docType,
    required List<_DocStamp> stamps,
    required Future<List<({String id, String content, String? contentPlain})>>
        Function(List<String> ids) load,
  }) async {
    final deletedStale = <_DocStamp>[];
    final liveStale = <_DocStamp>[];
    for (final s in stamps) {
      final state = stateByKey['$docType|${s.id}'];
      final fresh = state != null &&
          state.indexedUpdatedAt == s.updatedAt &&
          (s.deleted || state.scanVersion == scanVersion);
      if (fresh) continue;
      (s.deleted ? deletedStale : liveStale).add(s);
    }

    // Tombstones: drop their reference rows without reading content.
    for (final s in deletedStale) {
      await db.batch((b) {
        b.deleteWhere(
          db.documentReferences,
          (r) =>
              r.docType.equals(docType) & r.docId.equals(s.id),
        );
        b.insert(
          db.documentReferenceStates,
          DocumentReferenceStatesCompanion.insert(
            docType: docType,
            docId: s.id,
            indexedUpdatedAt: s.updatedAt,
            scanVersion: scanVersion,
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      });
    }

    // Live documents: extract in chunks. Each document's delete+insert+state
    // rides one batch (one transaction), so a re-entrant sweep can interleave
    // without leaving duplicate rows.
    const chunkSize = 200;
    final stampById = {for (final s in liveStale) s.id: s};
    for (var i = 0; i < liveStale.length; i += chunkSize) {
      final chunk = [
        for (final s in liveStale.skip(i).take(chunkSize)) s.id,
      ];
      for (final doc in await load(chunk)) {
        final stamp = stampById[doc.id]!;
        final extracted = extractDocumentReferences(
          content: doc.content,
          plainText: doc.contentPlain ?? deltaToPlainText(doc.content),
          books: books,
        );
        await db.batch((b) {
          b.deleteWhere(
            db.documentReferences,
            (r) =>
                r.docType.equals(docType) & r.docId.equals(doc.id),
          );
          b.insertAll(db.documentReferences, [
            for (final p in extracted.passages)
              DocumentReferencesCompanion.insert(
                docType: docType,
                docId: doc.id,
                kind: 'passage',
                bookName: drift.Value(p.bookName),
                chapterStart: drift.Value(p.chapterStart),
                chapterEnd: drift.Value(p.chapterEnd),
              ),
            for (final e in extracted.entities)
              DocumentReferencesCompanion.insert(
                docType: docType,
                docId: doc.id,
                kind: 'entity',
                entityType: drift.Value(e.type.name),
                entityId: drift.Value(e.id),
              ),
          ]);
          b.insert(
            db.documentReferenceStates,
            DocumentReferenceStatesCompanion.insert(
              docType: docType,
              docId: doc.id,
              indexedUpdatedAt: stamp.updatedAt,
              scanVersion: scanVersion,
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        });
      }
    }

    // Orphans: state/reference rows for ids that vanished outright (rows are
    // normally only soft-deleted, but a backup restore can replace the whole
    // table). Harmless if left, but cheap to sweep out.
    final liveIds = {for (final s in stamps) s.id};
    for (final s in states) {
      if (s.docType != docType || liveIds.contains(s.docId)) continue;
      await db.batch((b) {
        b.deleteWhere(
          db.documentReferences,
          (r) =>
              r.docType.equals(docType) & r.docId.equals(s.docId),
        );
        b.deleteWhere(
          db.documentReferenceStates,
          (r) =>
              r.docType.equals(docType) & r.docId.equals(s.docId),
        );
      });
    }
  }

  await sweep(
    docType: kDocTypeSermon,
    stamps: sermonStamps,
    load: (ids) async {
      final rows = await (db.select(db.sermons)
            ..where((s) => s.id.isIn(ids)))
          .get();
      return [
        for (final s in rows)
          (id: s.id, content: s.content, contentPlain: s.contentPlain),
      ];
    },
  );
  await sweep(
    docType: kDocTypeNotebookPage,
    stamps: pageStamps,
    load: (ids) async {
      final rows = await (db.select(db.notebookPages)
            ..where((p) => p.id.isIn(ids)))
          .get();
      return [
        for (final p in rows)
          (id: p.id, content: p.content, contentPlain: p.contentPlain),
      ];
    },
  );

  return true;
});
