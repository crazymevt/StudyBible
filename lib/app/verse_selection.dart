import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/importer/mybible_verse_parser.dart';
import '../domain/scripture/verse_share_format.dart';
import 'reader_state.dart';
import 'app_state.dart';
import 'content_providers.dart';

typedef VerseSelection = ({
  String book,
  int chapter,
  List<int> numbers,
  List<ShareVerse> verses,
  String? abbreviation,
});

VerseSelection? collectSelection(WidgetRef ref) {
  final versesMap = ref.read(parallelVersesProvider).value;
  if (versesMap == null || versesMap.isEmpty) return null;
  final verses = versesMap.values.first;

  final selected = ref.read(selectedVersesProvider).toList()..sort();
  final selectedModels =
      verses.where((v) => selected.contains(v.verse)).toList()
        ..sort((a, b) => a.verse.compareTo(b.verse));
  if (selectedModels.isEmpty) return null;

  final parser = MyBibleVerseParser();
  final shareVerses = <ShareVerse>[
    for (final v in selectedModels)
      (
        number: v.verse,
        text: parser
            .parseVerse(v.textContent)
            .map((s) => s.text)
            .join('')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
      ),
  ];

  return (
    book: ref.read(selectedBookNameProvider),
    chapter: ref.read(selectedChapterProvider),
    numbers: selected,
    verses: shareVerses,
    abbreviation: ref.read(primaryVersionAbbreviationProvider),
  );
}

String formatSelection(WidgetRef ref, VerseSelection sel) {
  final format = ref.read(verseShareFormatProvider);
  return VerseShareFormatter.format(
    bookName: sel.book,
    chapter: sel.chapter,
    verses: sel.verses,
    versionAbbreviation: sel.abbreviation,
    format: format,
  );
}
