class ScriptureReference {
  final String book;
  final int chapter;
  final int verse;

  const ScriptureReference({
    required this.book,
    required this.chapter,
    required this.verse,
  });

  @override
  String toString() => '$book $chapter:$verse';
}
