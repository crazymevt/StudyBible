import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/scripture/passage_citation.dart';

/// The anchored, one-citation-per-string grammar shared by every curated
/// dataset (prophecies, feasts, Reference tables, topics) and the reader's
/// passage navigation. These cases pin the behaviour the five former inline
/// copies relied on so the shared parser can't silently drift from it.
void main() {
  group('tryParse', () {
    test('whole-chapter citation leaves verse and endVerse null', () {
      final c = PassageCitation.tryParse('Leviticus 16')!;
      expect(c.book, 'Leviticus');
      expect(c.chapter, 16);
      expect(c.verse, isNull);
      expect(c.endVerse, isNull);
    });

    test('single verse', () {
      final c = PassageCitation.tryParse('Micah 5:2')!;
      expect(c.book, 'Micah');
      expect(c.chapter, 5);
      expect(c.verse, 2);
      expect(c.endVerse, isNull);
    });

    test('same-chapter verse range', () {
      final c = PassageCitation.tryParse('Isaiah 53:5-6')!;
      expect(c.book, 'Isaiah');
      expect(c.chapter, 53);
      expect(c.verse, 5);
      expect(c.endVerse, 6);
    });

    test('multi-word book name is not swallowed by the lazy book group', () {
      final c = PassageCitation.tryParse('Song of Solomon 2:1')!;
      expect(c.book, 'Song of Solomon');
      expect(c.chapter, 2);
      expect(c.verse, 1);
    });

    test('numbered book name', () {
      final c = PassageCitation.tryParse('2 Kings 18:1-6')!;
      expect(c.book, '2 Kings');
      expect(c.chapter, 18);
      expect(c.verse, 1);
      expect(c.endVerse, 6);
    });

    test('leading and trailing whitespace is ignored', () {
      final c = PassageCitation.tryParse('  John 3:16  ')!;
      expect(c.book, 'John');
      expect(c.chapter, 3);
      expect(c.verse, 16);
    });

    test('returns null for a non-citation string', () {
      expect(PassageCitation.tryParse('Genesis'), isNull);
      expect(PassageCitation.tryParse(''), isNull);
      expect(PassageCitation.tryParse('not a reference'), isNull);
    });
  });

  group('parse', () {
    test('parses a valid citation', () {
      expect(PassageCitation.parse('Matthew 20:2').chapter, 20);
    });

    test('throws FormatException on an unparseable string', () {
      expect(() => PassageCitation.parse('Genesis'),
          throwsA(isA<FormatException>()));
    });
  });

  test('toString round-trips the three citation shapes', () {
    expect(PassageCitation.tryParse('Leviticus 16').toString(), 'Leviticus 16');
    expect(PassageCitation.tryParse('Micah 5:2').toString(), 'Micah 5:2');
    expect(
        PassageCitation.tryParse('Isaiah 53:5-6').toString(), 'Isaiah 53:5-6');
  });
}
