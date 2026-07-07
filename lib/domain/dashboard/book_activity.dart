/// Per-book (or per-chapter) study-activity tally across the four v1
/// categories. Journals are deliberately excluded — journal entries carry no
/// scripture-reference index yet.
class ActivityCounts {
  final int highlights;
  final int notes;
  final int sermonRefs;
  final int notebookRefs;

  const ActivityCounts({
    this.highlights = 0,
    this.notes = 0,
    this.sermonRefs = 0,
    this.notebookRefs = 0,
  });

  int get total => highlights + notes + sermonRefs + notebookRefs;
  bool get isEmpty => total == 0;
}

class RankedBookActivity {
  final String bookName;
  final ActivityCounts counts;
  const RankedBookActivity(this.bookName, this.counts);
}

/// Ranks every book in [canonicalOrder] by [ActivityCounts.total], highest
/// first. Ties break by canonical (reading) order — the earlier book wins —
/// so the result is fully deterministic regardless of map iteration order.
/// Books absent from [counts] are treated as all-zero, which is how
/// zero-activity books surface in the first place.
List<RankedBookActivity> rankBookActivity(
  List<String> canonicalOrder,
  Map<String, ActivityCounts> counts,
) {
  final indexOf = {
    for (var i = 0; i < canonicalOrder.length; i++) canonicalOrder[i]: i,
  };
  final ranked = [
    for (final book in canonicalOrder)
      RankedBookActivity(book, counts[book] ?? const ActivityCounts()),
  ];
  ranked.sort((a, b) {
    final byTotal = b.counts.total.compareTo(a.counts.total);
    if (byTotal != 0) return byTotal;
    return indexOf[a.bookName]!.compareTo(indexOf[b.bookName]!);
  });
  return ranked;
}

/// The dashboard headline: the single top book, or null if every book is at
/// zero (fresh install / no study activity recorded yet) — the empty state.
RankedBookActivity? mostUsedBook(List<RankedBookActivity> ranked) {
  if (ranked.isEmpty || ranked.first.counts.isEmpty) return null;
  return ranked.first;
}
