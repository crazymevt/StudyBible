import 'thread.dart';
import 'thread_data.dart';

/// One thread search hit: its list [index] (the Explorer address), [title],
/// and a short [subtitle] (its category).
class ThreadSearchHit {
  final int index;
  final String title;
  final String subtitle;
  const ThreadSearchHit(this.index, this.title, this.subtitle);
}

/// Matches [query] against the thread dataset for the Explorer's universal
/// search: by title, by a stop's reference string ("Exodus 12", "John 1:29"),
/// or — only for queries of 4+ characters, to keep common words like
/// "the"/"God" from flooding — by description, stop title, or note prose.
/// Prose matches only at word starts ("lamb" finds The Lamb's notes; "gedy"
/// must not find "tragedy" — a mid-word hit would also rob a misspelled name
/// of its "Did you mean" suggestions, which only appear on an empty search).
/// Title-prefix matches rank first, then alphabetically. Returns at most
/// [limit] hits ([] for queries under 2 chars). Mirrors `searchProphecies`.
List<ThreadSearchHit> searchThreads(
  String query, {
  int limit = 20,
  List<Thread> source = threads,
}) {
  final q = query.trim().toLowerCase();
  if (q.length < 2) return const [];
  final wordStart = RegExp('\\b${RegExp.escape(q)}', caseSensitive: false);
  final hits = <ThreadSearchHit>[];
  for (var i = 0; i < source.length; i++) {
    final t = source[i];
    final inTitle = t.title.toLowerCase().contains(q);
    final inRefs = t.stops.any((s) => s.passage.toLowerCase().contains(q));
    final inBody =
        q.length >= 4 &&
        (wordStart.hasMatch(t.description) ||
            t.stops.any(
              (s) =>
                  wordStart.hasMatch(s.title) || wordStart.hasMatch(s.note),
            ));
    if (inTitle || inRefs || inBody) {
      hits.add(ThreadSearchHit(i, t.title, t.category.label));
    }
  }
  hits.sort((a, b) {
    int rank(String t) => t.toLowerCase().startsWith(q) ? 0 : 1;
    final r = rank(a.title).compareTo(rank(b.title));
    return r != 0 ? r : a.title.compareTo(b.title);
  });
  return hits.take(limit).toList();
}
