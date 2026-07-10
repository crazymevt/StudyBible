import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/prophecy/prophecy.dart';
import 'package:study_bible/domain/prophecy/prophecy_data.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';
import 'package:study_bible/domain/scripture/passage_citation.dart';

void main() {
  final byName = <String, SwordVersifiedBook>{
    for (final b in [...kjvVersification.ot, ...kjvVersification.nt]) b.name: b,
  };
  final otNames = {for (final b in kjvVersification.ot) b.name};
  final ntNames = {for (final b in kjvVersification.nt) b.name};

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

  test('every prophecy reference resolves against the KJV versification', () {
    final failures = <String>[];
    for (final p in prophecies) {
      for (final ref in [...p.prophecy, ...p.fulfillment]) {
        final issue = problem(ref);
        if (issue != null) failures.add('${p.id}: "$ref" — $issue');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('prophecy refs are Old Testament; fulfillment refs New Testament '
      '(except the oldTestament category)', () {
    final failures = <String>[];
    for (final p in prophecies) {
      for (final ref in p.prophecy) {
        final book = PassageCitation.tryParse(ref)?.book;
        if (book != null && !otNames.contains(book) && byName.containsKey(book)) {
          failures.add('${p.id}: prophecy ref "$ref" is not Old Testament');
        }
      }
      // The oldTestament category is fulfilled within the OT by design, so its
      // fulfillment references are expected to be Old Testament.
      if (p.category == ProphecyCategory.oldTestament) continue;
      for (final ref in p.fulfillment) {
        final book = PassageCitation.tryParse(ref)?.book;
        if (book != null && !ntNames.contains(book) && byName.containsKey(book)) {
          failures.add('${p.id}: fulfillment ref "$ref" is not New Testament');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('ids are unique', () {
    final ids = prophecies.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
