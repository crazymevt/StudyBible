// Pure-Dart estimate of how long a sermon takes to read/preach aloud — see
// CLAUDE.md (domain layer). No Flutter or IO imports.

/// Typical calm speaking pace, in words per minute.
const int kSermonWordsPerMinute = 130;

/// Counts words in [text] by splitting on whitespace.
int countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

/// Estimated time to read [wordCount] words aloud at [wordsPerMinute].
Duration estimateReadingTime(
  int wordCount, {
  int wordsPerMinute = kSermonWordsPerMinute,
}) {
  if (wordCount <= 0) return Duration.zero;
  final minutes = wordCount / wordsPerMinute;
  return Duration(seconds: (minutes * 60).round());
}
