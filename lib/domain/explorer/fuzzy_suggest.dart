/// Typo-tolerant "Did you mean …?" matching for the Explorer's universal
/// search: when a query's LIKE search comes back empty, the nearest entity
/// names by edit distance are offered instead ("Nebucadnezzar" →
/// Nebuchadnezzar, "Jerico" → Jericho).
library;

/// One entity name the suggester can match a misspelled query against:
/// where a hit should navigate, every spelling it answers to, and a weight
/// (verse count) to break distance ties toward the better-known entity.
class FuzzyCandidate<T> {
  final T item;

  /// Lowercased name variants: the full name plus, for multi-word names,
  /// each individual word — so "Magdelene" can reach "Mary Magdalene".
  final List<String> names;

  final int weight;

  FuzzyCandidate(this.item, Iterable<String> rawNames, {this.weight = 0})
      : names = {
          for (final raw in rawNames) ...[
            raw.trim().toLowerCase(),
            for (final word in raw.trim().toLowerCase().split(' '))
              if (word.length >= _minWordLength) word,
          ],
        }.where((n) => n.isNotEmpty).toList();

  /// Words shorter than this aren't matchable on their own — a 1-edit
  /// tolerance on "of"/"the" would match everything.
  static const _minWordLength = 4;
}

class FuzzySuggestion<T> {
  final T item;
  final int distance;
  const FuzzySuggestion(this.item, this.distance);
}

/// The closest [candidates] to [query] within a length-scaled edit-distance
/// tolerance (1 edit for short queries, up to 3 for long ones), nearest
/// first, ties broken by weight then name. Exact matches score 0 like any
/// other distance — callers only invoke this once substring search has
/// already failed, so 0 just means "matched a name word exactly".
List<FuzzySuggestion<T>> fuzzySuggest<T>(
  String query,
  Iterable<FuzzyCandidate<T>> candidates, {
  int limit = 5,
}) {
  final q = query.trim().toLowerCase();
  if (q.length < 3) return const [];
  final maxDistance = q.length <= 4
      ? 1
      : q.length <= 7
          ? 2
          : 3;

  final hits = <(FuzzySuggestion<T>, String, int)>[];
  for (final c in candidates) {
    var best = maxDistance + 1;
    var bestName = '';
    for (final name in c.names) {
      final d = boundedEditDistance(q, name, best - 1);
      if (d < best) {
        best = d;
        bestName = name;
      }
      if (best == 0) break;
    }
    if (best <= maxDistance) {
      hits.add((FuzzySuggestion(c.item, best), bestName, c.weight));
    }
  }
  hits.sort((a, b) {
    final d = a.$1.distance.compareTo(b.$1.distance);
    if (d != 0) return d;
    final w = b.$3.compareTo(a.$3);
    if (w != 0) return w;
    return a.$2.compareTo(b.$2);
  });
  return [for (final h in hits.take(limit)) h.$1];
}

/// Damerau-Levenshtein distance (optimal string alignment: insert, delete,
/// substitute, or transpose adjacent characters — transposition catches the
/// commonest typo class, "Jhon" for "John"), capped at [maxDistance]:
/// returns `maxDistance + 1` as soon as the true distance is provably
/// larger, so callers can prune without paying for the full computation.
int boundedEditDistance(String a, String b, int maxDistance) {
  if (maxDistance < 0) maxDistance = 0;
  if ((a.length - b.length).abs() > maxDistance) return maxDistance + 1;
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Three rolling rows of the DP matrix (the transposition case looks two
  // rows back).
  var twoAgo = List<int>.filled(b.length + 1, 0);
  var oneAgo = List<int>.generate(b.length + 1, (j) => j);
  var current = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    var rowMin = current[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var d = _min3(
        oneAgo[j] + 1, // deletion
        current[j - 1] + 1, // insertion
        oneAgo[j - 1] + cost, // substitution
      );
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1)) {
        final t = twoAgo[j - 2] + 1; // transposition
        if (t < d) d = t;
      }
      current[j] = d;
      if (d < rowMin) rowMin = d;
    }
    if (rowMin > maxDistance) return maxDistance + 1;
    final recycled = twoAgo;
    twoAgo = oneAgo;
    oneAgo = current;
    current = recycled;
  }
  final result = oneAgo[b.length];
  return result > maxDistance ? maxDistance + 1 : result;
}

int _min3(int a, int b, int c) {
  final m = a < b ? a : b;
  return m < c ? m : c;
}
