import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/content_manager_providers.dart';

void main() {
  group('recommendedPh4Modules', () {
    final abbrs = recommendedPh4Modules.map((m) => m.abbr).toList();

    test('covers the curated starter set', () {
      expect(
        abbrs,
        containsAll(<String>[
          'ESVGSB',
          'MHWBC.commentaries',
          'Pool-c.commentaries',
          'KJV-s.subheadings',
          'KJVD.dictionary',
          'VineOT.dictionary',
          'VineNT.dictionary',
          'Noah.dictionary',
          'Webster.dictionary',
        ]),
      );
    });

    test('Berean abbr uses the curly apostrophe ph4 expects (U+2019)', () {
      // ph4.org spells the download code "BSB’22"; a straight apostrophe would
      // silently fail to resolve against the catalog.
      expect(abbrs, contains('BSB’22'));
      expect(
        abbrs,
        isNot(contains("BSB'22")),
      ); // straight quote must not creep in
    });

    test('the Bible is installed before its study resources', () {
      // Commentaries/dictionaries anchor to a translation, so a Bible must lead.
      expect(abbrs.first, 'BSB\u{2019}22');
    });

    test('excludes AV — the KJV now ships bundled with the app', () {
      expect(abbrs, isNot(contains('AV')));
    });

    test('includes the King James subheadings the reader defaults to', () {
      // downloadRecommended() auto-selects this module as the subheadings
      // source once the batch finishes; keep the two in sync.
      expect(abbrs, contains('KJV-s.subheadings'));
    });

    test('entries are unique', () {
      expect(abbrs.toSet().length, abbrs.length);
    });
  });
}
