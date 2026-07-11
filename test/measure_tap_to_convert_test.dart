import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/reference/measure.dart';
import 'package:study_bible/domain/reference/measure_conversion.dart';
import 'package:study_bible/domain/reference/measure_matcher.dart';
import 'package:study_bible/domain/reference/measures_data.dart';
import 'package:study_bible/domain/reference/number_words.dart';

Measure _byId(String id) => measures.firstWhere((m) => m.id == id);

void main() {
  group('parseQuantityBeforeMeasure', () {
    test('single cardinal word', () {
      expect(parseQuantityBeforeMeasure(['six']), 6);
      expect(parseQuantityBeforeMeasure(['thirty']), 30);
    });

    test('digit token', () {
      expect(parseQuantityBeforeMeasure(['3']), 3);
    });

    test('implied one in "an hundred" / bare article', () {
      expect(parseQuantityBeforeMeasure(['an', 'hundred']), 100);
      expect(parseQuantityBeforeMeasure(['a']), 1);
      expect(parseQuantityBeforeMeasure(['an']), 1);
    });

    test('KJV reversed ones-before-tens order', () {
      expect(parseQuantityBeforeMeasure(['four', 'and', 'twenty']), 24);
      expect(parseQuantityBeforeMeasure(['five', 'and', 'twenty']), 25);
      expect(parseQuantityBeforeMeasure(['twenty', 'five']), 25);
    });

    test('archaic score words are absolute, not multipliers', () {
      expect(parseQuantityBeforeMeasure(['threescore', 'and', 'ten']), 70);
      expect(parseQuantityBeforeMeasure(['fourscore']), 80);
    });

    test('compound hundred + tens + ones', () {
      expect(
        parseQuantityBeforeMeasure(['an', 'hundred', 'and', 'twenty', 'and', 'six']),
        126,
      );
      expect(parseQuantityBeforeMeasure(['two', 'thousand']), 2000);
    });

    test('only the trailing contiguous number run counts', () {
      expect(parseQuantityBeforeMeasure(['he', 'made', 'six']), 6);
      expect(parseQuantityBeforeMeasure(['he', 'made']), isNull);
    });

    test('no recognizable number returns null', () {
      expect(parseQuantityBeforeMeasure([]), isNull);
      expect(parseQuantityBeforeMeasure(['golden']), isNull);
    });
  });

  group('matchMeasureWord', () {
    test('matches plain and plural forms, case-insensitively', () {
      expect(matchMeasureWord('cubits')!.id, 'cubit');
      expect(matchMeasureWord('CUBIT')!.id, 'cubit');
      expect(matchMeasureWord('ephahs')!.id, 'ephah');
    });

    test('matches KJV-translated forms, not just transliterations', () {
      expect(matchMeasureWord('penny')!.id, 'denarius');
      expect(matchMeasureWord('pence')!.id, 'denarius');
      expect(matchMeasureWord('mite')!.id, 'lepton');
      expect(matchMeasureWord('mites')!.id, 'lepton');
    });

    test('ambiguous weight/money words default to the money sense', () {
      expect(matchMeasureWord('shekel')!.id, 'shekel-money');
      expect(matchMeasureWord('talents')!.id, 'talent-money');
    });

    test('unrecognized words return null', () {
      expect(matchMeasureWord('mountain'), isNull);
    });
  });

  group('ambiguityNoteFor', () {
    test('flags the shekel/talent money-vs-weight ambiguity', () {
      expect(ambiguityNoteFor(_byId('shekel-money')), isNotNull);
      expect(ambiguityNoteFor(_byId('talent-money')), isNotNull);
    });

    test('is null for unambiguous measures', () {
      expect(ambiguityNoteFor(_byId('cubit')), isNull);
    });
  });

  group('formatMeasureConversion', () {
    test('length: whole feet', () {
      expect(formatMeasureConversion(_byId('cubit'), 6), '9 ft');
    });

    test('length: feet + inches remainder', () {
      expect(formatMeasureConversion(_byId('cubit'), 1), '1 ft 6 in');
    });

    test('length: sub-foot shows inches', () {
      expect(formatMeasureConversion(_byId('handbreadth'), 1), '3 inches');
    });

    test('length: large totals convert to miles', () {
      expect(formatMeasureConversion(_byId('mile'), 2), '1.84 miles');
    });

    test('weight: pounds + ounces remainder', () {
      expect(formatMeasureConversion(_byId('mina'), 1), '1 lb 4.11 oz');
    });

    test('volume: gallons + quarts remainder', () {
      expect(formatMeasureConversion(_byId('ephah'), 1), '5 gal 3.25 qt');
    });

    test('money: singular wage + rough USD estimate', () {
      expect(formatMeasureConversion(_byId('denarius'), 1), "1 day's wage (~\$150)");
    });

    test('money: multiplies quantity and formats with thousands separator', () {
      expect(
        formatMeasureConversion(_byId('shekel-money'), 30),
        "120 days' wages (~\$18,000)",
      );
    });

    test('money: sub-day-wage amounts show decimal precision', () {
      final result = formatMeasureConversion(_byId('lepton'), 2);
      expect(result, contains("days' wages"));
      expect(result, contains('~\$'));
    });
  });
}
