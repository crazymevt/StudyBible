import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/explorer/fuzzy_suggest.dart';

void main() {
  group('boundedEditDistance', () {
    test('classic edit operations each cost one', () {
      expect(boundedEditDistance('john', 'john', 3), 0);
      expect(boundedEditDistance('jon', 'john', 3), 1); // insertion
      expect(boundedEditDistance('johnn', 'john', 3), 1); // deletion
      expect(boundedEditDistance('jahn', 'john', 3), 1); // substitution
      expect(boundedEditDistance('jhon', 'john', 3), 1); // transposition
    });

    test('caps at maxDistance + 1 instead of computing the true distance', () {
      expect(boundedEditDistance('nebuchadnezzar', 'ziph', 2), 3);
      // Length difference alone can prove the bound is exceeded.
      expect(boundedEditDistance('ab', 'abcdefgh', 3), 4);
    });

    test('empty strings degrade to plain length', () {
      expect(boundedEditDistance('', 'abc', 5), 3);
      expect(boundedEditDistance('abc', '', 5), 3);
    });
  });

  group('fuzzySuggest', () {
    FuzzyCandidate<String> c(String name, {int weight = 0}) =>
        FuzzyCandidate(name, [name], weight: weight);

    test('finds names within the length-scaled tolerance, nearest first', () {
      final hits = fuzzySuggest('Nebucadnezzar', [
        c('Nebuchadnezzar'),
        c('Nebuzaradan'),
        c('Ziph'),
      ]);
      expect(hits.first.item, 'Nebuchadnezzar');
      expect(hits.first.distance, 1);
      expect(hits.map((h) => h.item), isNot(contains('Ziph')));
    });

    test('short queries tolerate only one edit', () {
      expect(fuzzySuggest('Sual', [c('Saul')]).single.distance, 1);
      expect(fuzzySuggest('Sxxl', [c('Saul')]), isEmpty);
    });

    test('queries under three characters suggest nothing', () {
      expect(fuzzySuggest('ab', [c('ab')]), isEmpty);
    });

    test('multi-word names match through their individual words, but words '
        'under four letters are not matchable alone', () {
      final mary = FuzzyCandidate('Mary Magdalene', ['Mary Magdalene']);
      expect(fuzzySuggest('Magdelene', [mary]).single.item, 'Mary Magdalene');
      final ur = FuzzyCandidate('Ur of the Chaldees', ['Ur of the Chaldees']);
      expect(fuzzySuggest('Caldees', [ur]).single.item, 'Ur of the Chaldees');
      // "of"/"the" aren't variants, so nothing for a near-"the" query to
      // land on; a 1-edit tolerance on connectives would match everything.
      expect(fuzzySuggest('thee', [ur]), isEmpty);
    });

    test('distance ties rank by weight, then name', () {
      // All three are one substitution from the query.
      final hits = fuzzySuggest('Jabal', [
        c('Jubal', weight: 1),
        c('Zabal', weight: 5),
        c('Cabal', weight: 1),
      ]);
      expect(hits.map((h) => h.item).toList(), ['Zabal', 'Cabal', 'Jubal']);
    });

    test('every name variant of a candidate is tried', () {
      final person = FuzzyCandidate(
        'Nebuchadnezzar',
        ['Nebuchadnezzar', 'Nebuchadrezzar'],
      );
      expect(fuzzySuggest('Nebuchadrezar', [person]).single.distance, 1);
    });
  });
}
