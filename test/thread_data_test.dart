import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';
import 'package:study_bible/domain/scripture/passage_citation.dart';
import 'package:study_bible/domain/threads/thread_data.dart';

void main() {
  final orderedBooks = [...kjvVersification.ot, ...kjvVersification.nt];
  final byName = <String, SwordVersifiedBook>{
    for (final b in orderedBooks) b.name: b,
  };
  final bookIndex = <String, int>{
    for (var i = 0; i < orderedBooks.length; i++) orderedBooks[i].name: i,
  };

  String? problem(String passage) {
    final c = PassageCitation.tryParse(passage);
    if (c == null) return 'unparseable';
    final book = byName[c.book];
    if (book == null) return 'unknown book "${c.book}"';
    if (c.chapter < 1 || c.chapter > book.chapterCount) {
      return 'chapter ${c.chapter} out of range (1..${book.chapterCount})';
    }
    final maxVerse = book.versesPerChapter[c.chapter - 1];
    if (c.verse != null && (c.verse! < 1 || c.verse! > maxVerse)) {
      return 'verse ${c.verse} out of range (1..$maxVerse)';
    }
    if (c.endVerse != null &&
        (c.endVerse! < c.verse! || c.endVerse! > maxVerse)) {
      return 'end verse ${c.endVerse} out of range (${c.verse}..$maxVerse)';
    }
    return null;
  }

  test('every thread stop resolves against the KJV versification', () {
    final failures = <String>[];
    for (final t in threads) {
      for (final s in t.stops) {
        final issue = problem(s.passage);
        if (issue != null) failures.add('${t.id}: "${s.passage}" — $issue');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('stops walk forward through the canon (Genesis → Revelation)', () {
    // The walk's whole premise is following a motif through redemptive
    // history, so a stop may never move backward past the previous one.
    final failures = <String>[];
    for (final t in threads) {
      (int, int, int)? prev;
      for (final s in t.stops) {
        final c = PassageCitation.tryParse(s.passage);
        final idx = c == null ? null : bookIndex[c.book];
        if (c == null || idx == null) continue; // caught by the first test
        final key = (idx, c.chapter, c.verse ?? 1);
        if (prev != null &&
            (key.$1 < prev.$1 ||
                (key.$1 == prev.$1 &&
                    (key.$2 < prev.$2 ||
                        (key.$2 == prev.$2 && key.$3 < prev.$3))))) {
          failures.add('${t.id}: "${s.passage}" steps backward in the canon');
        }
        prev = key;
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('ids are unique', () {
    final ids = threads.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every thread has enough stops to be a walk', () {
    for (final t in threads) {
      expect(
        t.stops.length,
        greaterThanOrEqualTo(5),
        reason: '${t.id} has only ${t.stops.length} stops',
      );
    }
  });
}
