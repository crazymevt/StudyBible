import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/dashboard/book_activity.dart';

void main() {
  const order = ['Genesis', 'Exodus', 'Leviticus'];

  group('rankBookActivity', () {
    test('zero-fills books missing from counts', () {
      final ranked = rankBookActivity(order, {
        'Genesis': const ActivityCounts(highlights: 3),
      });
      expect(ranked, hasLength(3));
      expect(ranked.map((r) => r.bookName), contains('Leviticus'));
      final leviticus = ranked.firstWhere((r) => r.bookName == 'Leviticus');
      expect(leviticus.counts.isEmpty, isTrue);
    });

    test('ranks by total descending', () {
      final ranked = rankBookActivity(order, {
        'Genesis': const ActivityCounts(highlights: 1),
        'Exodus': const ActivityCounts(highlights: 5),
        'Leviticus': const ActivityCounts(notes: 2),
      });
      expect(ranked.map((r) => r.bookName), ['Exodus', 'Leviticus', 'Genesis']);
    });

    test('ties break by canonical reading order', () {
      final ranked = rankBookActivity(order, {
        'Exodus': const ActivityCounts(highlights: 2),
        'Genesis': const ActivityCounts(notes: 2),
      });
      // Both total 2; Genesis precedes Exodus in canonical order.
      expect(ranked.first.bookName, 'Genesis');
      expect(ranked[1].bookName, 'Exodus');
    });

    test('all-zero input still ties on canonical order', () {
      final ranked = rankBookActivity(order, {});
      expect(ranked.map((r) => r.bookName), order);
    });
  });

  group('mostUsedBook', () {
    test('returns null when every book is at zero', () {
      final ranked = rankBookActivity(order, {});
      expect(mostUsedBook(ranked), isNull);
    });

    test('returns null for an empty ranking', () {
      expect(mostUsedBook(const []), isNull);
    });

    test('returns the top-ranked book when activity exists', () {
      final ranked = rankBookActivity(order, {
        'Exodus': const ActivityCounts(highlights: 5),
      });
      expect(mostUsedBook(ranked)?.bookName, 'Exodus');
    });
  });

  group('ActivityCounts', () {
    test('total sums all five categories', () {
      const counts = ActivityCounts(
        highlights: 1,
        notes: 2,
        sermonRefs: 3,
        notebookRefs: 4,
        taggedVerses: 5,
      );
      expect(counts.total, 15);
      expect(counts.isEmpty, isFalse);
    });

    test('default counts are empty', () {
      expect(const ActivityCounts().isEmpty, isTrue);
    });
  });
}
