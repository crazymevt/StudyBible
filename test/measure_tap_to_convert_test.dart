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

  group('isNumberWord', () {
    test('recognizes cardinal, multiplier, connector, and digit tokens', () {
      expect(isNumberWord('six'), isTrue);
      expect(isNumberWord('hundred'), isTrue);
      expect(isNumberWord('and'), isTrue);
      expect(isNumberWord('3'), isTrue);
      expect(isNumberWord('CUBITS'), isFalse);
    });
  });

  group('resolveMeasureNearWord', () {
    test('tap directly on the unit word behaves as before', () {
      final resolved = resolveMeasureNearWord('cubits', ['six'], []);
      expect(resolved!.measure.id, 'cubit');
      expect(resolved.quantity, 6);
      expect(resolved.unitWord, 'cubits');
    });

    test('tap on the quantity word finds the unit ahead of it', () {
      final resolved = resolveMeasureNearWord('six', [], ['cubits', 'long']);
      expect(resolved!.measure.id, 'cubit');
      expect(resolved.quantity, 6);
      expect(resolved.unitWord, 'cubits');
    });

    test('tap in the middle of a compound number still finds the unit', () {
      // "six hundred and fifty cubits" — tap on "and".
      final resolved = resolveMeasureNearWord(
        'and',
        ['six', 'hundred'],
        ['fifty', 'cubits', 'long'],
      );
      expect(resolved!.measure.id, 'cubit');
      expect(resolved.quantity, 650);
      expect(resolved.unitWord, 'cubits');
    });

    test('tap on a bare article resolves quantity 1', () {
      final resolved = resolveMeasureNearWord('a', [], ['cubit']);
      expect(resolved!.measure.id, 'cubit');
      expect(resolved.quantity, 1);
    });

    test('a number not followed by a unit word resolves to nothing', () {
      // "forty days and forty nights" — tap on "forty".
      expect(resolveMeasureNearWord('forty', [], ['days', 'and', 'forty', 'nights']), isNull);
    });

    test('a plain word that is neither a unit nor a number resolves to nothing', () {
      expect(resolveMeasureNearWord('mountain', ['the', 'great'], ['stood', 'firm']), isNull);
    });

    test('"shekels of brass" resolves to the weight sense, not money', () {
      // 1 Samuel 17:5 — Goliath's coat of mail, tap on "shekels".
      final resolved = resolveMeasureNearWord(
        'shekels',
        ['the', 'weight', 'of', 'the', 'coat', 'was', 'five', 'thousand'],
        ['of', 'brass'],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 5000);
    });

    test('"shekels of iron" also resolves to the weight sense', () {
      // 1 Samuel 17:7 — Goliath's spear head.
      final resolved = resolveMeasureNearWord('shekels', ['six', 'hundred'], ['of', 'iron']);
      expect(resolved!.measure.id, 'shekel-weight');
    });

    test('tap on the quantity number before "shekels of brass" still disambiguates', () {
      final resolved = resolveMeasureNearWord(
        'five',
        [],
        ['thousand', 'shekels', 'of', 'brass'],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 5000);
    });

    test('"shekels of silver" stays the money sense', () {
      final resolved = resolveMeasureNearWord('shekels', ['thirty'], ['of', 'silver']);
      expect(resolved!.measure.id, 'shekel-money');
    });

    test('bare "shekels" with no following material stays the money default', () {
      final resolved = resolveMeasureNearWord('shekels', ['thirty'], []);
      expect(resolved!.measure.id, 'shekel-money');
    });

    test('"shekel weight" resolves to the weight sense standing alone', () {
      // Genesis 24:22 — "an earring ... of half a shekel weight".
      final resolved = resolveMeasureNearWord('shekel', ['half', 'a'], ['weight']);
      expect(resolved!.measure.id, 'shekel-weight');
    });

    test('"shekels weight of gold" resolves to the weight sense', () {
      // Genesis 24:22 — "two bracelets ... of ten shekels weight of gold".
      final resolved = resolveMeasureNearWord('shekels', ['ten'], ['weight', 'of', 'gold']);
      expect(resolved!.measure.id, 'shekel-weight');
    });

    test('tap on the quantity number before "shekels weight" still disambiguates', () {
      final resolved = resolveMeasureNearWord('ten', [], ['shekels', 'weight', 'of', 'gold']);
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 10);
    });

    test('"of pure myrrh five hundred shekels" resolves to weight (Exodus 30:23)', () {
      final resolved = resolveMeasureNearWord(
        'shekels',
        ['take', 'thou', 'also', 'unto', 'thee', 'principal', 'spices', 'of', 'pure', 'myrrh', 'five', 'hundred'],
        [],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 500);
    });

    test('a restated quantity still resolves to weight once the ingredient was named earlier', () {
      // "...and of sweet cinnamon half so much, even two hundred and fifty
      // shekels..." — the ingredient sits well before the actual number,
      // separated by a comparison clause.
      final resolved = resolveMeasureNearWord(
        'shekels',
        [
          'of', 'pure', 'myrrh', 'five', 'hundred', 'shekels', 'and',
          'of', 'sweet', 'cinnamon', 'half', 'so', 'much', 'even',
          'two', 'hundred', 'and', 'fifty',
        ],
        [],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 250);
    });

    test('tap on the quantity number before the ingredient-list "shekels" also resolves to weight', () {
      final resolved = resolveMeasureNearWord(
        'five',
        ['of', 'pure', 'myrrh'],
        ['hundred', 'shekels'],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 500);
    });

    test('an unrelated "of <name>" before a money amount does not false-positive', () {
      // Genesis 23:16 — "...in the audience of the sons of Heth, four
      // hundred shekels of silver..." must stay the money sense.
      final resolved = resolveMeasureNearWord(
        'shekels',
        ['in', 'the', 'audience', 'of', 'the', 'sons', 'of', 'heth', 'four', 'hundred'],
        ['of', 'silver'],
      );
      expect(resolved!.measure.id, 'shekel-money');
    });

    test('"the weight whereof was ... shekels" resolves to weight (Numbers 7:19)', () {
      final resolved = resolveMeasureNearWord(
        'shekels',
        [
          'he', 'offered', 'for', 'his', 'offering', 'one', 'silver', 'charger',
          'the', 'weight', 'whereof', 'was', 'an', 'hundred', 'and', 'thirty',
        ],
        ['one', 'silver', 'bowl', 'of', 'seventy', 'shekels'],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 130);
    });

    test('"golden spoon of ten shekels" resolves to weight (Numbers 7:32)', () {
      // The metal describes the object, not the shekels directly, and it's
      // the adjective form "golden" rather than the noun "gold".
      final resolved = resolveMeasureNearWord(
        'shekels',
        ['one', 'golden', 'spoon', 'of', 'ten'],
        ['full', 'of', 'incense'],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 10);
    });

    test('"and a" separates a distinct item — silver stays money (Joshua 7:21)', () {
      // "...and two hundred shekels of silver, and a wedge of gold of fifty
      // shekels weight..." — the gold wedge's "weight"/"gold" markers must
      // not leak backward onto the unrelated silver amount.
      final resolved = resolveMeasureNearWord(
        'shekels',
        ['when', 'i', 'saw', 'among', 'the', 'spoils', 'a', 'goodly', 'babylonish', 'garment', 'and', 'two', 'hundred'],
        ['of', 'silver', 'and', 'a', 'wedge', 'of', 'gold', 'of', 'fifty', 'shekels', 'weight'],
      );
      expect(resolved!.measure.id, 'shekel-money');
      expect(resolved.quantity, 200);
    });

    test('the gold wedge past that same "and a" still resolves to weight (Joshua 7:21)', () {
      final resolved = resolveMeasureNearWord(
        'shekels',
        [
          'when', 'i', 'saw', 'among', 'the', 'spoils', 'a', 'goodly', 'babylonish', 'garment', 'and', 'two',
          'hundred', 'shekels', 'of', 'silver', 'and', 'a', 'wedge', 'of', 'gold', 'of', 'fifty',
        ],
        ['weight', 'then', 'i', 'coveted', 'them'],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 50);
    });

    test('a later bare shekel figure inherits the verse\'s weight framing (Numbers 7:19)', () {
      // "...one silver bowl of seventy shekels..." has no marker of its own
      // — it reads as weight only because "the weight whereof was" already
      // set that context earlier in the same verse.
      final resolved = resolveMeasureNearWord(
        'shekels',
        [
          'the', 'weight', 'whereof', 'was', 'an', 'hundred', 'and', 'thirty', 'shekels',
          'one', 'silver', 'bowl', 'of', 'seventy',
        ],
        ['after', 'the', 'shekel', 'of', 'the', 'sanctuary'],
      );
      expect(resolved!.measure.id, 'shekel-weight');
      expect(resolved.quantity, 70);
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
