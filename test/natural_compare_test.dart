import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/natural_compare.dart';

void main() {
  group('naturalCompare', () {
    test('orders embedded numbers by value, not lexicographically', () {
      final titles = ['Part 10', 'Part 2', 'Part 1']..sort(naturalCompare);
      expect(titles, ['Part 1', 'Part 2', 'Part 10']);
    });

    test('is case-insensitive', () {
      expect(naturalCompare('advent', 'Romans'), isNegative);
      expect(naturalCompare('Romans', 'advent'), isPositive);
    });

    test('falls back to plain order for equal strings and number ties', () {
      expect(naturalCompare('same', 'same'), 0);
      // "07" and "7" are numerically equal; the tie-break must still be
      // deterministic (non-zero, and consistent in both directions).
      final tie = naturalCompare('Part 07', 'Part 7');
      expect(tie, isNot(0));
      expect(naturalCompare('Part 7', 'Part 07'), -tie);
    });

    test('shorter string sorts first when one is a prefix of the other', () {
      expect(naturalCompare('Week', 'Week 2'), isNegative);
    });

    test('numbers sort before letters (code-unit order preserved)', () {
      final list = ['b', '2', 'a', '10']..sort(naturalCompare);
      expect(list, ['2', '10', 'a', 'b']);
    });
  });
}
