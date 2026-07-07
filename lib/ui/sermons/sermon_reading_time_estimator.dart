import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../data/importer/mybible_verse_parser.dart';
import '../../domain/sermons/sermon_reading_time.dart';
import '../common/reference_autolink.dart';

/// A citation's line counts as "just a citation" (verse text not already in
/// the document) when fewer than this many words share its line, once the
/// citation's own text is excluded. A spoken lead-in like "turn with me to"
/// is short; an actually-pasted verse is typically 15+ words, so this fails
/// safe — worst case it skips a legitimate bare citation rather than ever
/// double-counting a pasted one.
const int kPastedVerseWordThreshold = 8;

/// Finds `sbref:`-linked citations in [deltaOps] (as from
/// `document.toDelta().toJson()`) whose verse text does not appear to already
/// be present in the document, by the threshold above. Pure data-in/data-out
/// so it's directly testable with hand-built delta JSON.
List<ParsedReferenceUrl> bareCitationsInDelta(List<dynamic> deltaOps) {
  final result = <ParsedReferenceUrl>[];

  var lineText = StringBuffer();
  var lineCitations = <(ParsedReferenceUrl, String)>[];

  void finishLine() {
    final citationWords = lineCitations.fold<int>(
      0,
      (sum, c) => sum + countWords(c.$2),
    );
    final extraWords = countWords(lineText.toString()) - citationWords;
    if (extraWords < kPastedVerseWordThreshold) {
      result.addAll(lineCitations.map((c) => c.$1));
    }
    lineText = StringBuffer();
    lineCitations = [];
  }

  for (final op in deltaOps) {
    if (op is! Map || op['insert'] is! String) continue;
    final text = op['insert'] as String;
    final attributes = op['attributes'];
    final link = attributes is Map ? attributes['link'] : null;
    final parsed = link is String ? parseReferenceUrl(link) : null;

    var start = 0;
    while (true) {
      final newlineIndex = text.indexOf('\n', start);
      final segment = newlineIndex == -1
          ? text.substring(start)
          : text.substring(start, newlineIndex);
      lineText.write(segment);
      if (parsed != null && segment.isNotEmpty) {
        lineCitations.add((parsed, segment));
      }
      if (newlineIndex == -1) break;
      finishLine();
      start = newlineIndex + 1;
    }
  }
  finishLine();

  return result;
}

/// Estimates how long [document] would take to read/preach aloud: the
/// document's own word count, plus the word count of any bare scripture
/// citation's verse text (looked up, since it isn't in the document) —
/// see [bareCitationsInDelta].
Future<Duration> estimateSermonReadingTime(
  Document document,
  WidgetRef ref,
) async {
  final totalWords = countWords(document.toPlainText());

  final versions = ref.read(activeVersionsProvider);
  if (versions.isEmpty) return estimateReadingTime(totalWords);
  final versionId = versions.first;

  final citations = bareCitationsInDelta(document.toDelta().toJson());
  var citedWords = 0;
  for (final citation in citations) {
    final book = await ref.read(
      bookByNameProvider((versionId: versionId, name: citation.bookName)).future,
    );
    if (book == null) continue;

    final startChapter = citation.chapter;
    final endChapter = citation.endChapter ?? startChapter;
    // A citation with no endChapter/endVerse is a single verse, not an
    // open-ended range — cap the last chapter at that same verse rather than
    // reading to the end of the chapter.
    final isRange = citation.endChapter != null || citation.endVerse != null;
    for (var chapter = startChapter; chapter <= endChapter; chapter++) {
      final verses = await ref.read(
        versesForChapterProvider((bookId: book.id, chapter: chapter)).future,
      );
      final lowBound = chapter == startChapter ? citation.verse : null;
      final highBound = chapter == endChapter
          ? (isRange ? citation.endVerse : citation.verse)
          : null;
      for (final verse in verses) {
        if (lowBound != null && verse.verse < lowBound) continue;
        if (highBound != null && verse.verse > highBound) continue;
        citedWords += countWords(mybibleVersePlainText(verse.textContent));
      }
    }
  }

  return estimateReadingTime(totalWords + citedWords);
}
