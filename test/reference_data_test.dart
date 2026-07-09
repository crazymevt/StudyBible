import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/reference/covenants_data.dart';
import 'package:study_bible/domain/reference/kings_data.dart';
import 'package:study_bible/domain/reference/measures_data.dart';
import 'package:study_bible/domain/reference/named_group.dart';
import 'package:study_bible/domain/reference/named_groups_data.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';

/// Same reference grammar the Feasts/Prophecies/curated-topic data and the
/// reader's passage navigation use: "Book C", "Book C:V", or "Book C:V-V".
final _passageExp = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

void main() {
  final byName = <String, SwordVersifiedBook>{
    for (final b in [...kjvVersification.ot, ...kjvVersification.nt]) b.name: b,
  };

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

  test('every king/reign citation resolves against the KJV versification', () {
    final failures = <String>[];
    for (final k in kingReigns) {
      for (final ref in k.citations) {
        final issue = problem(ref);
        if (issue != null) failures.add('${k.id}: "$ref" — $issue');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('ids are unique', () {
    final ids = kingReigns.map((k) => k.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every measure citation resolves against the KJV versification', () {
    final failures = <String>[];
    for (final m in measures) {
      for (final ref in m.citations) {
        final issue = problem(ref);
        if (issue != null) failures.add('${m.id}: "$ref" — $issue');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('measure ids are unique', () {
    final ids = measures.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every covenant citation resolves against the KJV versification', () {
    final failures = <String>[];
    for (final c in covenants) {
      for (final ref in c.citations) {
        final issue = problem(ref);
        if (issue != null) failures.add('${c.id}: "$ref" — $issue');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('covenant ids are unique', () {
    final ids = covenants.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every named group citation resolves against the KJV versification', () {
    final failures = <String>[];
    for (final e in namedGroups) {
      for (final ref in e.citations) {
        final issue = problem(ref);
        if (issue != null) failures.add('${e.id}: "$ref" — $issue');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('named group ids are unique', () {
    final ids = namedGroups.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('each named-group list has contiguous order starting at 1', () {
    for (final list in NamedGroupList.values) {
      final orders = namedGroups
          .where((e) => e.list == list)
          .map((e) => e.order)
          .toList()
        ..sort();
      expect(orders, equals(List.generate(orders.length, (i) => i + 1)),
          reason: '${list.name} orders: $orders');
    }
  });
}
