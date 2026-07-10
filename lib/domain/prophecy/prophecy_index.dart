import '../scripture/passage_citation.dart';
import 'prophecy.dart';
import 'prophecy_data.dart';

/// One prophecy that cites a particular chapter, and how it does so: as the
/// [foretold] (an Old Testament reference lands in the chapter) and/or the
/// [fulfilled] (a New Testament reference lands there). [verses] are the start
/// verses cited within that chapter, sorted.
class ProphecyChapterHit {
  /// Index into the const `prophecies` list — the Explorer address.
  final int index;
  final String title;
  final bool foretold;
  final bool fulfilled;
  final List<int> verses;

  const ProphecyChapterHit({
    required this.index,
    required this.title,
    required this.foretold,
    required this.fulfilled,
    required this.verses,
  });
}

/// Map key for a chapter, e.g. `Micah|5`.
String prophecyChapterKey(String book, int chapter) => '$book|$chapter';

class _MutableHit {
  final int index;
  final String title;
  bool foretold = false;
  bool fulfilled = false;
  final Set<int> verses = {};
  _MutableHit(this.index, this.title);
}

/// Builds the chapter → prophecies reverse index once from the const dataset,
/// so the Explorer passage page can show which prophecies touch a chapter with
/// an O(1) lookup instead of scanning every prophecy on each page open. Keyed
/// by [prophecyChapterKey]; a prophecy that both foretells and is fulfilled in
/// the same chapter appears once with both flags set.
Map<String, List<ProphecyChapterHit>> buildProphecyChapterIndex([
  List<Prophecy> source = prophecies,
]) {
  final byKey = <String, Map<int, _MutableHit>>{};

  void record(int idx, String title, String passage, {required bool foretold}) {
    final citation = PassageCitation.tryParse(passage);
    if (citation == null) return;
    final book = citation.book;
    final chapter = citation.chapter;
    final verse = citation.verse ?? 1;
    final hit = byKey
        .putIfAbsent(prophecyChapterKey(book, chapter), () => {})
        .putIfAbsent(idx, () => _MutableHit(idx, title));
    if (foretold) {
      hit.foretold = true;
    } else {
      hit.fulfilled = true;
    }
    hit.verses.add(verse);
  }

  for (var i = 0; i < source.length; i++) {
    final p = source[i];
    for (final r in p.prophecy) {
      record(i, p.title, r, foretold: true);
    }
    for (final r in p.fulfillment) {
      record(i, p.title, r, foretold: false);
    }
  }

  return {
    for (final entry in byKey.entries)
      entry.key: [
        for (final h in entry.value.values)
          ProphecyChapterHit(
            index: h.index,
            title: h.title,
            foretold: h.foretold,
            fulfilled: h.fulfilled,
            verses: h.verses.toList()..sort(),
          ),
      ]..sort((a, b) => a.title.compareTo(b.title)),
  };
}

/// One prophecy search hit: its list [index] (the Explorer address), [title],
/// and a short [subtitle] (its theme).
class ProphecySearchHit {
  final int index;
  final String title;
  final String subtitle;
  const ProphecySearchHit(this.index, this.title, this.subtitle);
}

/// Matches [query] against the prophecy dataset for the Explorer's universal
/// search: by title, by a reference string ("Micah 5", "Isaiah 53:5"), or —
/// only for queries of 4+ characters, to keep common words like "the"/"God"
/// from flooding — by either prose half. Title-prefix matches rank first, then
/// alphabetically. Returns at most [limit] hits ([] for queries under 2 chars).
List<ProphecySearchHit> searchProphecies(
  String query, {
  int limit = 20,
  List<Prophecy> source = prophecies,
}) {
  final q = query.trim().toLowerCase();
  if (q.length < 2) return const [];
  final hits = <ProphecySearchHit>[];
  for (var i = 0; i < source.length; i++) {
    final p = source[i];
    final inTitle = p.title.toLowerCase().contains(q);
    final inRefs = p.prophecy
        .followedBy(p.fulfillment)
        .any((r) => r.toLowerCase().contains(q));
    final inBody = q.length >= 4 &&
        (p.prophecyText.toLowerCase().contains(q) ||
            p.fulfillmentText.toLowerCase().contains(q));
    if (inTitle || inRefs || inBody) {
      hits.add(ProphecySearchHit(i, p.title, p.category.label));
    }
  }
  hits.sort((a, b) {
    int rank(String t) => t.toLowerCase().startsWith(q) ? 0 : 1;
    final r = rank(a.title).compareTo(rank(b.title));
    return r != 0 ? r : a.title.compareTo(b.title);
  });
  return hits.take(limit).toList();
}
