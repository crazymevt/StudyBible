import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/sermons/sermon_reading_time.dart';

void main() {
  group('countWords', () {
    test('counts whitespace-separated words', () {
      expect(countWords('For God so loved the world'), 6);
    });

    test('empty or whitespace-only text is zero words', () {
      expect(countWords(''), 0);
      expect(countWords('   \n  '), 0);
    });

    test('collapses runs of whitespace', () {
      expect(countWords('one   two\nthree'), 3);
    });
  });

  group('estimateReadingTime', () {
    test('zero words takes no time', () {
      expect(estimateReadingTime(0), Duration.zero);
    });

    test('scales with the words-per-minute rate', () {
      final estimate = estimateReadingTime(130, wordsPerMinute: 130);
      expect(estimate, const Duration(minutes: 1));
    });

    test('uses the default rate when unspecified', () {
      final estimate = estimateReadingTime(kSermonWordsPerMinute * 2);
      expect(estimate, const Duration(minutes: 2));
    });
  });
}
