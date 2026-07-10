/// A single scripture citation that occupies an entire string — one of
/// `"Book C"` (whole chapter), `"Book C:V"`, or `"Book C:V-V"` (a same-chapter
/// verse range). This is the anchored, one-citation-per-string grammar that
/// the curated datasets use: prophecies, feasts, the Reference tables, and
/// curated topics all store hand-authored passage strings, one per entry.
///
/// Deliberately distinct from [BibleReferenceScanner], which finds references
/// *embedded* in free prose — there the surrounding text matters and false
/// positives are the risk. Here the whole trimmed string must be exactly one
/// citation or parsing fails.
class PassageCitation {
  /// Book name exactly as written (`"2 Kings"`, `"Song of Solomon"`) — not
  /// normalized or resolved to a book id. Callers match it against whatever
  /// book list they already hold.
  final String book;

  final int chapter;

  /// Starting verse, or null for a whole-chapter citation (`"Leviticus 16"`).
  /// Navigation callers that need a concrete target treat null as verse 1.
  final int? verse;

  /// Ending verse of a same-chapter range (`"Isaiah 53:5-6"`), or null when
  /// the citation names a single verse or a whole chapter.
  final int? endVerse;

  const PassageCitation({
    required this.book,
    required this.chapter,
    this.verse,
    this.endVerse,
  });

  // Group 1 (book) is lazy so multi-word names ("1 Samuel", "Song of
  // Solomon") aren't swallowed by the greedy chapter match. Group 2: chapter.
  // Group 3: verse (optional). Group 4: end of a same-chapter range.
  static final RegExp _exp = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

  /// Parses [passage], or returns null when it isn't a `"Book C[:V[-V]]"`
  /// citation. Leading/trailing whitespace is ignored.
  static PassageCitation? tryParse(String passage) {
    final m = _exp.firstMatch(passage.trim());
    if (m == null) return null;
    return PassageCitation(
      book: m.group(1)!.trim(),
      chapter: int.parse(m.group(2)!),
      verse: m.group(3) == null ? null : int.parse(m.group(3)!),
      endVerse: m.group(4) == null ? null : int.parse(m.group(4)!),
    );
  }

  /// Like [tryParse] but throws [FormatException] when [passage] can't be
  /// parsed — for curated const data where an unparseable citation is a bug
  /// that should surface loudly rather than be silently dropped.
  static PassageCitation parse(String passage) {
    final c = tryParse(passage);
    if (c == null) {
      throw FormatException('Not a passage citation: "$passage"');
    }
    return c;
  }

  @override
  String toString() {
    final v = verse == null
        ? ''
        : ':$verse${endVerse == null ? '' : '-$endVerse'}';
    return '$book $chapter$v';
  }
}
