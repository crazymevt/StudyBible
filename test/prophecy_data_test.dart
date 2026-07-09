import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/prophecy/prophecy.dart';
import 'package:study_bible/domain/prophecy/prophecy_data.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';

/// Same reference grammar the Feasts/curated-topic data and the reader's
/// passage navigation use: "Book C", "Book C:V", or "Book C:V-V".
final _passageExp = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

void main() {
  final byName = <String, SwordVersifiedBook>{
    for (final b in [...kjvVersification.ot, ...kjvVersification.nt]) b.name: b,
  };
  final otNames = {for (final b in kjvVersification.ot) b.name};
  final ntNames = {for (final b in kjvVersification.nt) b.name};

  String? problem(String passage) {
    final m = _passageExp.firstMatch(passage.trim());
    if (m == null) return 'unparseable';
    final book = byName[m.group(1)!.trim()];
    if (book == null) return 'unknown book "${m.group(1)!.trim()}"';
    final chapter = int.parse(m.group(2)!);
    if (chapter < 1 || chapter > book.chapterCount) {
      return 'chapter $chapter out of range (1..${book.chapterCount})';
    }
    final maxVerse = book.versesPerChapter[chapter - 1];
    final verse = m.group(3) == null ? null : int.parse(m.group(3)!);
    if (verse != null && (verse < 1 || verse > maxVerse)) {
      return 'verse $verse out of range (1..$maxVerse)';
    }
    final verseEnd = m.group(4) == null ? null : int.parse(m.group(4)!);
    if (verseEnd != null && (verseEnd < verse! || verseEnd > maxVerse)) {
      return 'end verse $verseEnd out of range ($verse..$maxVerse)';
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
        final book = _passageExp.firstMatch(ref.trim())?.group(1)?.trim();
        if (book != null && !otNames.contains(book) && byName.containsKey(book)) {
          failures.add('${p.id}: prophecy ref "$ref" is not Old Testament');
        }
      }
      // The oldTestament category is fulfilled within the OT by design, so its
      // fulfillment references are expected to be Old Testament.
      if (p.category == ProphecyCategory.oldTestament) continue;
      for (final ref in p.fulfillment) {
        final book = _passageExp.firstMatch(ref.trim())?.group(1)?.trim();
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
