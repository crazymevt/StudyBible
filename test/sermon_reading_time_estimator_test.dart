import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/ui/sermons/sermon_reading_time_estimator.dart';

void main() {
  group('bareCitationsInDelta', () {
    test('a citation alone on its line is returned', () {
      final ops = [
        {'insert': 'Turn to '},
        {
          'insert': 'John 3:16',
          'attributes': {'link': 'sbref:John|3|16'},
        },
        {'insert': ' tonight.\n'},
      ];

      final citations = bareCitationsInDelta(ops);

      expect(citations, hasLength(1));
      expect(citations.single.bookName, 'John');
      expect(citations.single.chapter, 3);
      expect(citations.single.verse, 16);
    });

    test('a citation followed by its pasted verse text is not returned', () {
      final ops = [
        {
          'insert': 'John 3:16',
          'attributes': {'link': 'sbref:John|3|16'},
        },
        {
          'insert':
              ' - For God so loved the world, that he gave his only begotten '
              'Son, that whosoever believeth in him should not perish, but '
              'have everlasting life.\n',
        },
      ];

      expect(bareCitationsInDelta(ops), isEmpty);
    });

    test('a legacy 3-part link (no range) is still detected', () {
      final ops = [
        {
          'insert': 'John 3:16',
          'attributes': {'link': 'sbref:John|3|16'},
        },
        {'insert': '\n'},
      ];

      final citations = bareCitationsInDelta(ops);

      expect(citations, hasLength(1));
      expect(citations.single.endChapter, isNull);
      expect(citations.single.endVerse, isNull);
    });

    test('plain prose with no links yields no citations', () {
      final ops = [
        {'insert': 'A sermon with no scripture citations at all.\n'},
      ];

      expect(bareCitationsInDelta(ops), isEmpty);
    });

    test('a citation on its own line is unaffected by a pasted verse on a different line', () {
      final ops = [
        {
          'insert': 'John 3:16',
          'attributes': {'link': 'sbref:John|3|16'},
        },
        {'insert': '\n'},
        {
          'insert':
              'For God so loved the world, that he gave his only begotten '
              'Son, that whosoever believeth in him should not perish, but '
              'have everlasting life.\n',
        },
      ];

      final citations = bareCitationsInDelta(ops);

      expect(citations, hasLength(1));
      expect(citations.single.verse, 16);
    });
  });
}
