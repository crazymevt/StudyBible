part of 'explorer_providers.dart';

// --- Passage page ---

class ExplorerEventHit {
  final int id;
  final String title;
  final int? startYear;
  ExplorerEventHit(this.id, this.title, this.startYear);
}

class ExplorerTopicHit {
  final int id;
  final String name;
  ExplorerTopicHit(this.id, this.name);
}

/// One installed commentary's entries for a chapter.
class ExplorerCommentarySection {
  final Commentary commentary;

  /// Entries for the chapter, in verse order.
  final List<CommentaryEntry> entries;
  ExplorerCommentarySection(this.commentary, this.entries);
}

/// Chapter commentary across *all* installed commentaries (the reader's
/// Commentary panel shows one selected module at a time; the Explorer shows
/// everything available for the passage). Empty when none are installed.
final explorerPassageCommentariesProvider =
    FutureProvider.family<
      List<ExplorerCommentarySection>,
      ({String book, int chapter})
    >((ref, loc) async {
      final store = ref.watch(contentStoreProvider);
      final commentaries = await ref.watch(commentariesProvider.future);
      if (commentaries.isEmpty) return const [];

      final entries =
          await (store.select(store.commentaryEntries)
                ..where(
                  (c) =>
                      c.bookName.equals(loc.book) &
                      c.chapter.equals(loc.chapter),
                )
                ..orderBy([(c) => OrderingTerm.asc(c.verse)]))
              .get();
      if (entries.isEmpty) return const [];

      final byCommentary = <int, List<CommentaryEntry>>{};
      for (final e in entries) {
        byCommentary.putIfAbsent(e.commentaryId, () => []).add(e);
      }
      return [
        for (final c in commentaries)
          if (byCommentary[c.id] != null)
            ExplorerCommentarySection(c, byCommentary[c.id]!),
      ];
    });

/// A chapter's cross-references from one source verse, target-votes desc.
class ExplorerCrossRefGroup {
  final int verse;
  final List<CrossReference> refs;
  ExplorerCrossRefGroup(this.verse, this.refs);
}

/// Chapter cross-references across the whole `cross_references` dataset,
/// grouped by source verse. The reader's Cross-References panel queries one
/// verse at a time (on tap); this aggregates every verse in the chapter for
/// the passage page.
final explorerPassageCrossReferencesProvider =
    FutureProvider.family<
      List<ExplorerCrossRefGroup>,
      ({String book, int chapter})
    >((ref, loc) async {
      final store = ref.watch(contentStoreProvider);
      final rows =
          await (store.select(store.crossReferences)
                ..where(
                  (c) =>
                      c.sourceBookName.equals(loc.book) &
                      c.sourceChapter.equals(loc.chapter),
                )
                ..orderBy([
                  (c) => OrderingTerm.asc(c.sourceVerse),
                  (c) => OrderingTerm(
                    expression: c.votes,
                    mode: OrderingMode.desc,
                  ),
                ]))
              .get();
      if (rows.isEmpty) return const [];

      final byVerse = <int, List<CrossReference>>{};
      for (final r in rows) {
        byVerse.putIfAbsent(r.sourceVerse, () => []).add(r);
      }
      return [
        for (final verse in byVerse.keys.toList()..sort())
          ExplorerCrossRefGroup(verse, byVerse[verse]!),
      ];
    });
