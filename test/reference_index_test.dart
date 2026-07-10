import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/reference/covenants_data.dart';
import 'package:study_bible/domain/reference/kings_data.dart';
import 'package:study_bible/domain/reference/measures_data.dart';
import 'package:study_bible/domain/reference/named_groups_data.dart';
import 'package:study_bible/domain/reference/reference_index.dart';

void main() {
  final index = buildReferenceChapterIndex();

  test('a chapter maps to the Reference entries that cite it', () {
    // David's citations include "1 Samuel 16:13".
    final hits = index[referenceChapterKey('1 Samuel', 16)] ?? const [];
    final david = hits.where((h) => h.title == 'David');
    expect(david, isNotEmpty);
    expect(david.first.kind, ReferenceKind.kingReign);
    expect(david.first.explorerPersonId, 991);
    expect(david.first.verses, contains(13));
  });

  test('a hit citing the same chapter twice merges its verses into one entry', () {
    // Athaliah cites both "2 Kings 11:1-3" and "2 Kings 11:13-16".
    final hits = index[referenceChapterKey('2 Kings', 11)] ?? const [];
    final athaliah = hits.where((h) => h.title == 'Athaliah').toList();
    expect(athaliah, hasLength(1));
    expect(athaliah.first.verses, containsAll([1, 13]));
  });

  test('every dataset entry is reachable from at least one chapter', () {
    final reachableKingIds = <String>{};
    final reachableMeasureIds = <String>{};
    final reachableCovenantIds = <String>{};
    final reachableNamedGroupIds = <String>{};
    for (final hits in index.values) {
      for (final h in hits) {
        switch (h.kind) {
          case ReferenceKind.kingReign:
            reachableKingIds.add(h.title);
          case ReferenceKind.measure:
            reachableMeasureIds.add(h.title);
          case ReferenceKind.covenant:
            reachableCovenantIds.add(h.title);
          case ReferenceKind.namedGroup:
            reachableNamedGroupIds.add(h.title);
        }
      }
    }
    expect(reachableKingIds.length, kingReigns.length);
    expect(reachableMeasureIds.length, measures.length);
    expect(reachableCovenantIds.length, covenants.length);
    expect(reachableNamedGroupIds.length, namedGroups.length);
  });

  test('explorerPersonId only appears where the source data set it', () {
    for (final hits in index.values) {
      for (final h in hits) {
        if (h.explorerPersonId != null) {
          expect(h.explorerPersonId, greaterThan(0));
        }
      }
    }
  });
}
