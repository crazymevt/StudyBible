import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/reference/covenants_data.dart';
import 'package:study_bible/domain/reference/kings_data.dart';
import 'package:study_bible/domain/reference/measures_data.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';
import 'package:study_bible/domain/scripture/passage_citation.dart';

void main() {
  final byName = <String, SwordVersifiedBook>{
    for (final b in [...kjvVersification.ot, ...kjvVersification.nt]) b.name: b,
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

  test('hand-verified explorerPersonId values are unique', () {
    final kingIds = kingReigns
        .map((k) => k.explorerPersonId)
        .whereType<int>()
        .toList();
    expect(kingIds.toSet().length, kingIds.length,
        reason: 'duplicate explorerPersonId in kingReigns: $kingIds');
  });
}
