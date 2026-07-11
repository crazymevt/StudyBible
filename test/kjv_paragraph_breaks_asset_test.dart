import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sanity checks over the bundled paragraph-break asset
/// (scripts/build_kjv_paragraphs.dart), so a bad regeneration fails CI instead
/// of surfacing as missing paragraphs — or paragraphs on the wrong verse — in
/// the reader's flowing view.
void main() {
  late List<String> breaks;

  setUpAll(() {
    final raw =
        File('assets/data/kjv_paragraph_breaks.json').readAsStringSync();
    breaks = (jsonDecode(raw) as List).cast<String>();
  });

  test('has a substantial, well-formed set of breaks', () {
    expect(breaks.length, greaterThan(4000));
    final pattern = RegExp(r'^[^|]+\|\d+\|\d+$');
    for (final b in breaks) {
      expect(pattern.hasMatch(b), isTrue, reason: 'malformed entry: $b');
    }
  });

  test('starts at Genesis 1:1, per every paragraphed KJV edition', () {
    expect(breaks, contains('Genesis|1|1'));
  });

  test('excludes Esther — AV and the KJV versification disagree on its '
      'verse divisions', () {
    expect(breaks.where((b) => b.startsWith('Esther|')), isEmpty);
  });

  test('every other canonical book has at least one break', () {
    final books = {for (final b in breaks) b.split('|').first};
    // 66 books, minus Esther (excluded above).
    expect(books.length, 65);
  });
}
