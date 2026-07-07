import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_store.dart';
import '../domain/dashboard/book_activity.dart';
import 'achievement_service.dart';
import 'document_reference_providers.dart';
import 'user_providers.dart';

// --- Book-level breakdown (the 66-book list) ---

final _highlightCountsByBookProvider = StreamProvider<Map<String, int>>((ref) {
  final store = ref.watch(userStoreProvider);
  final countExpr = countAll();
  final q = store.selectOnly(store.highlights)
    ..addColumns([store.highlights.bookName, countExpr])
    ..where(store.highlights.deleted.equals(false))
    ..groupBy([store.highlights.bookName]);
  return q.watch().map((rows) => {
        for (final r in rows)
          r.read(store.highlights.bookName)!: r.read(countExpr)!,
      });
});

final _noteCountsByBookProvider = StreamProvider<Map<String, int>>((ref) {
  final store = ref.watch(userStoreProvider);
  final countExpr = countAll();
  final q = store.selectOnly(store.notes)
    ..addColumns([store.notes.bookName, countExpr])
    ..where(store.notes.deleted.equals(false))
    ..groupBy([store.notes.bookName]);
  return q.watch().map((rows) => {
        for (final r in rows) r.read(store.notes.bookName)!: r.read(countExpr)!,
      });
});

/// Extracts the book name from a tag's `entityId` when `entityType` is
/// 'verse', e.g. `'Verse:Gen|1|1'` -> `'Gen'`. Mirrors the parsing
/// [entitiesForTagProvider] already does for the same format.
String? _verseBookFromEntityId(String entityId) {
  final parts = entityId.split(':');
  if (parts.length < 2) return null;
  final data = parts[1].split('|');
  return data.isNotEmpty ? data[0] : null;
}

/// Per-book count of tag applications on verses (`entity_tags` rows with
/// `entityType == 'verse'`), one per tag/verse pairing — the same
/// per-row granularity as highlight and note counts. Tags on other entity
/// types (notes, sermons, ...) aren't counted here since those documents
/// already contribute via their own category.
final _taggedVerseCountsByBookProvider = StreamProvider<Map<String, int>>((ref) {
  final store = ref.watch(userStoreProvider);
  final q = store.select(store.entityTags)
    ..where((et) => et.entityType.equals('verse'))
    ..where((et) => et.deleted.equals(false));
  return q.watch().map((rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      final book = _verseBookFromEntityId(row.entityId);
      if (book != null) counts[book] = (counts[book] ?? 0) + 1;
    }
    return counts;
  });
});

/// Per-book distinct-document counts for sermons and notebook pages, sourced
/// from the persisted `document_references` index (kept fresh by
/// [documentReferenceIndexProvider]). `COUNT(DISTINCT doc_id)` so a document
/// citing the same book twice (e.g. Romans 8 and Romans 12) counts once —
/// the same dedupe rule `_documentsReferencing` uses for Explorer backlinks.
Future<({Map<String, int> sermon, Map<String, int> notebook})>
    _docRefCountsByBook(UserStore store) async {
  final rows = await store.customSelect(
    'SELECT doc_type AS doc_type, book_name AS book, '
    'COUNT(DISTINCT doc_id) AS cnt FROM document_references '
    "WHERE kind = 'passage' AND book_name IS NOT NULL "
    "AND doc_type IN ('$kDocTypeSermon', '$kDocTypeNotebookPage') "
    'GROUP BY doc_type, book_name',
  ).get();
  final sermon = <String, int>{};
  final notebook = <String, int>{};
  for (final r in rows) {
    final target =
        r.read<String>('doc_type') == kDocTypeSermon ? sermon : notebook;
    target[r.read<String>('book')] = r.read<int>('cnt');
  }
  return (sermon: sermon, notebook: notebook);
}

/// Combined per-book study-activity breakdown across all four v1 categories,
/// zero-filled for every canonical book so under-studied books show up too.
final bookActivityBreakdownProvider =
    FutureProvider<Map<String, ActivityCounts>>((ref) async {
  final highlightCounts = ref.watch(_highlightCountsByBookProvider).value ?? {};
  final noteCounts = ref.watch(_noteCountsByBookProvider).value ?? {};
  final tagCounts = ref.watch(_taggedVerseCountsByBookProvider).value ?? {};
  await ref.watch(documentReferenceIndexProvider.future);
  final docRefCounts = await _docRefCountsByBook(ref.watch(userStoreProvider));
  return {
    for (final book in bibleChapters.keys)
      book: ActivityCounts(
        highlights: highlightCounts[book] ?? 0,
        notes: noteCounts[book] ?? 0,
        sermonRefs: docRefCounts.sermon[book] ?? 0,
        notebookRefs: docRefCounts.notebook[book] ?? 0,
        taggedVerses: tagCounts[book] ?? 0,
      ),
  };
});

final rankedBookActivityProvider = Provider<List<RankedBookActivity>>((ref) {
  final counts = ref.watch(bookActivityBreakdownProvider).value ?? {};
  return rankBookActivity(bibleChapters.keys.toList(), counts);
});

final mostUsedBookProvider = Provider<RankedBookActivity?>(
  (ref) => mostUsedBook(ref.watch(rankedBookActivityProvider)),
);

// --- Chapter-level breakdown (per-book drill-down), computed lazily ---

/// Per-chapter study-activity breakdown for a single book, zero-filled across
/// every chapter that book has. Computed on demand (not eagerly for all 1189
/// chapters) since it's only needed once a user drills into a specific book.
final bookChapterActivityProvider =
    FutureProvider.family<Map<int, ActivityCounts>, String>((ref, book) async {
  final store = ref.watch(userStoreProvider);
  final totalChapters = bibleChapters[book] ?? 0;

  final highlightCountExpr = countAll();
  final highlightRows = await (store.selectOnly(store.highlights)
        ..addColumns([store.highlights.chapter, highlightCountExpr])
        ..where(store.highlights.bookName.equals(book) &
            store.highlights.deleted.equals(false))
        ..groupBy([store.highlights.chapter]))
      .get();
  final highlightCounts = {
    for (final r in highlightRows)
      r.read(store.highlights.chapter)!: r.read(highlightCountExpr)!,
  };

  final noteCountExpr = countAll();
  final noteRows = await (store.selectOnly(store.notes)
        ..addColumns([store.notes.chapter, noteCountExpr])
        ..where(store.notes.bookName.equals(book) &
            store.notes.deleted.equals(false))
        ..groupBy([store.notes.chapter]))
      .get();
  final noteCounts = {
    for (final r in noteRows) r.read(store.notes.chapter)!: r.read(noteCountExpr)!,
  };

  final tagRows = await (store.select(store.entityTags)
        ..where((et) => et.entityType.equals('verse'))
        ..where((et) => et.deleted.equals(false))
        ..where((et) => et.entityId.like('Verse:$book|%')))
      .get();
  final tagCounts = <int, int>{};
  for (final row in tagRows) {
    final parts = row.entityId.split(':');
    if (parts.length < 2) continue;
    final data = parts[1].split('|');
    if (data.length < 2) continue;
    final chapter = int.tryParse(data[1]);
    if (chapter != null) tagCounts[chapter] = (tagCounts[chapter] ?? 0) + 1;
  }

  await ref.watch(documentReferenceIndexProvider.future);
  final docRefRows = await store.customSelect(
    'SELECT doc_type AS doc_type, doc_id AS doc_id, '
    'chapter_start AS chapter_start, chapter_end AS chapter_end '
    "FROM document_references WHERE kind = 'passage' AND book_name = ? "
    "AND doc_type IN ('$kDocTypeSermon', '$kDocTypeNotebookPage')",
    variables: [Variable.withString(book)],
  ).get();

  // A citation spanning multiple chapters (e.g. "Romans 8-9") counts once per
  // chapter it touches; distinct doc ids per chapter avoid inflating a count
  // when a single document cites the same chapter more than once.
  final sermonDocsByChapter = <int, Set<String>>{};
  final notebookDocsByChapter = <int, Set<String>>{};
  for (final r in docRefRows) {
    final docsByChapter = r.read<String>('doc_type') == kDocTypeSermon
        ? sermonDocsByChapter
        : notebookDocsByChapter;
    final start = r.read<int>('chapter_start');
    final end = r.read<int>('chapter_end');
    final docId = r.read<String>('doc_id');
    for (var chapter = start; chapter <= end; chapter++) {
      docsByChapter.putIfAbsent(chapter, () => {}).add(docId);
    }
  }

  return {
    for (var chapter = 1; chapter <= totalChapters; chapter++)
      chapter: ActivityCounts(
        highlights: highlightCounts[chapter] ?? 0,
        notes: noteCounts[chapter] ?? 0,
        sermonRefs: sermonDocsByChapter[chapter]?.length ?? 0,
        notebookRefs: notebookDocsByChapter[chapter]?.length ?? 0,
        taggedVerses: tagCounts[chapter] ?? 0,
      ),
  };
});
