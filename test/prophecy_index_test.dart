import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/prophecy/prophecy_data.dart';
import 'package:study_bible/domain/prophecy/prophecy_index.dart';

void main() {
  final index = buildProphecyChapterIndex();

  test('a chapter maps to the prophecies that cite it', () {
    // Born in Bethlehem: Micah 5:2 (foretold) → Matthew 2:1 (fulfilled).
    final micah = index[prophecyChapterKey('Micah', 5)] ?? const [];
    final born = micah.where((h) => h.title == 'Born in Bethlehem');
    expect(born, isNotEmpty);
    expect(born.first.foretold, isTrue);
    expect(born.first.fulfilled, isFalse);
    expect(born.first.verses, contains(2));

    final matt2 = index[prophecyChapterKey('Matthew', 2)] ?? const [];
    final bornFulfilled = matt2.where((h) => h.title == 'Born in Bethlehem');
    expect(bornFulfilled, isNotEmpty);
    expect(bornFulfilled.first.fulfilled, isTrue);
    expect(bornFulfilled.first.foretold, isFalse);
  });

  test('every prophecy is reachable from at least one chapter', () {
    final reachable = <int>{};
    for (final hits in index.values) {
      for (final h in hits) {
        reachable.add(h.index);
      }
    }
    expect(reachable.length, prophecies.length);
  });

  test('index resolves references only to real, in-range indices', () {
    for (final hits in index.values) {
      for (final h in hits) {
        expect(h.index, inInclusiveRange(0, prophecies.length - 1));
        expect(h.verses, isNotEmpty);
        expect(h.foretold || h.fulfilled, isTrue);
      }
    }
  });

  group('searchProphecies', () {
    test('matches by title, with prefix hits ranked first', () {
      final hits = searchProphecies('bethlehem');
      expect(hits.map((h) => h.title), contains('Born in Bethlehem'));

      // A query that is a title prefix should surface that title at the top.
      final born = searchProphecies('born');
      expect(born.first.title.toLowerCase(), startsWith('born'));
    });

    test('matches by reference string', () {
      final hits = searchProphecies('Micah 5');
      expect(hits.map((h) => h.title), contains('Born in Bethlehem'));
    });

    test('matches prose only for queries of 4+ chars', () {
      // "gall" appears in a fulfillment paraphrase but no title/ref.
      expect(searchProphecies('gall'), isNotEmpty);
      // Under 4 chars, prose is not searched (avoids common-word floods).
      final short = searchProphecies('of');
      expect(short.every((h) => h.title.toLowerCase().contains('of')), isTrue);
    });

    test('returns nothing for sub-2-char queries and respects the limit', () {
      expect(searchProphecies('a'), isEmpty);
      expect(searchProphecies('the', limit: 3).length, lessThanOrEqualTo(3));
    });

    test('every hit points to a real index whose title matches', () {
      for (final h in searchProphecies('Lord', limit: 100)) {
        expect(h.index, inInclusiveRange(0, prophecies.length - 1));
        expect(prophecies[h.index].title, h.title);
      }
    });
  });
}
