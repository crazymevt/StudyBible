import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/importer/mybible_verse_parser.dart';

void main() {
  // The parser is stateful per instance (it tracks open italic/Jesus-words/etc.
  // tags), so each test uses a fresh instance.
  group('MyBibleVerseParser', () {
    test('returns a single plain-text segment for untagged input', () {
      final segments = MyBibleVerseParser().parseVerse('In the beginning');
      expect(segments, hasLength(1));
      expect(segments.single.text, 'In the beginning');
      expect(segments.single.isItalic, isFalse);
      expect(segments.single.isJesusWords, isFalse);
    });

    test('marks text inside <i> as italic', () {
      final segments = MyBibleVerseParser().parseVerse('say <i>now</i> here');
      expect(segments.map((s) => s.text), ['say ', 'now', ' here']);
      expect(segments[0].isItalic, isFalse);
      expect(segments[1].isItalic, isTrue);
      expect(segments[2].isItalic, isFalse);
    });

    test('marks text inside <t> and <j> as Jesus words', () {
      final t = MyBibleVerseParser().parseVerse('<t>I am</t> he');
      expect(t[0].text, 'I am');
      expect(t[0].isJesusWords, isTrue);
      expect(t[1].isJesusWords, isFalse);

      final j = MyBibleVerseParser().parseVerse('<j>Follow me</j>');
      expect(j.single.text, 'Follow me');
      expect(j.single.isJesusWords, isTrue);
    });

    test('extracts an inline Strong\'s number from <S n="...">', () {
      final segments = MyBibleVerseParser().parseVerse('<S n="1254">created');
      expect(segments[0].strongs, '1254');
      expect(segments[0].text, isEmpty);
      expect(segments[1].text, 'created');
    });

    test('captures a standalone Strong\'s number as strongs, not text', () {
      final segments = MyBibleVerseParser().parseVerse('<S>430</S>God');
      expect(segments[0].strongs, '430');
      expect(segments[1].text, 'God');
      // The number itself is never emitted as visible text.
      expect(segments.where((s) => s.text == '430'), isEmpty);
    });

    test('marks text inside <f> as a footnote', () {
      final segments = MyBibleVerseParser().parseVerse('word<f>see note</f>');
      expect(segments[0].text, 'word');
      expect(segments[1].isFootnote, isTrue);
      expect(segments[1].footnoteText, 'see note');
    });

    test('emits paragraph and line breaks', () {
      final pb = MyBibleVerseParser().parseVerse('a<pb/>b');
      expect(pb.map((s) => s.isParagraphBreak), [false, true, false]);
      expect([pb[0].text, pb[2].text], ['a', 'b']);

      final br = MyBibleVerseParser().parseVerse('a<br/>b');
      expect(br[1].isLineBreak, isTrue);
    });

    test('decodes HTML entities', () {
      final segments =
          MyBibleVerseParser().parseVerse('Shadrach &amp; &lt;name&gt;');
      expect(segments.single.text, 'Shadrach & <name>');
    });

    test('returns an empty list for an empty string', () {
      expect(MyBibleVerseParser().parseVerse(''), isEmpty);
    });

    test('keeps formatting state across a combined verse', () {
      final segments = MyBibleVerseParser()
          .parseVerse('And <t>God said,<i> Let</i> there be</t> light');
      expect(segments.map((s) => s.text),
          ['And ', 'God said,', ' Let', ' there be', ' light']);
      // " Let" is both Jesus words and italic; the trailing " light" is neither.
      final letSeg = segments.firstWhere((s) => s.text == ' Let');
      expect(letSeg.isJesusWords, isTrue);
      expect(letSeg.isItalic, isTrue);
      expect(segments.last.isJesusWords, isFalse);
      expect(segments.last.isItalic, isFalse);
    });
  });
}
