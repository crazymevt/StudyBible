import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/ui/common/reference_autolink.dart';

Book _book(String name) => Book(
  id: 43,
  versionId: 'KJV',
  name: name,
  bookOrder: 43,
  testament: 'NT',
);

void main() {
  final john = _book('John');

  test('round-trips a single verse (no range)', () {
    final url = buildReferenceUrl(john, 3, 16);
    final parsed = parseReferenceUrl(url)!;
    expect(parsed.bookName, 'John');
    expect(parsed.chapter, 3);
    expect(parsed.verse, 16);
    expect(parsed.endChapter, isNull);
    expect(parsed.endVerse, isNull);
  });

  test('round-trips a same-chapter range', () {
    final url = buildReferenceUrl(john, 3, 16, endChapter: 3, endVerse: 18);
    final parsed = parseReferenceUrl(url)!;
    expect(parsed.chapter, 3);
    expect(parsed.verse, 16);
    expect(parsed.endChapter, 3);
    expect(parsed.endVerse, 18);
  });

  test('round-trips a cross-chapter range', () {
    final url = buildReferenceUrl(john, 1, 1, endChapter: 2, endVerse: 3);
    final parsed = parseReferenceUrl(url)!;
    expect(parsed.chapter, 1);
    expect(parsed.verse, 1);
    expect(parsed.endChapter, 2);
    expect(parsed.endVerse, 3);
  });

  test('parses a legacy 3-part link with no range info', () {
    final parsed = parseReferenceUrl('sbref:John|3|16')!;
    expect(parsed.bookName, 'John');
    expect(parsed.chapter, 3);
    expect(parsed.verse, 16);
    expect(parsed.endChapter, isNull);
    expect(parsed.endVerse, isNull);
  });

  test('rejects non-sbref urls', () {
    expect(parseReferenceUrl('https://example.com'), isNull);
  });
}
