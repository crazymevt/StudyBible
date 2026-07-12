part of 'explorer_providers.dart';

// --- Verse preview (ExplorerVerseChip's bottom sheet) ---

/// A verse (or short range) hydrated for the Explorer's preview sheet.
class ExplorerVersePreview {
  const ExplorerVersePreview({
    required this.versionAbbreviation,
    required this.verses,
  });

  /// Abbreviation of the version the text came from (the primary version).
  final String versionAbbreviation;

  /// The requested verses in order, markup stripped.
  final List<({int verse, String text})> verses;
}

/// The primary version's text for one verse reference (or an inclusive
/// `verse`–`verseEnd` range within a chapter), cleaned of inline MyBible
/// markup — powers the preview sheet an [ExplorerVerseChip] opens, so a
/// reference can be skimmed without leaving the Explorer. Null when no
/// version is active, the book name doesn't resolve in it, or the verses
/// don't exist there (versification differences).
final explorerVersePreviewProvider =
    FutureProvider.family<
      ExplorerVersePreview?,
      ({String book, int chapter, int verse, int verseEnd})
    >((ref, args) async {
      final active = ref.watch(activeVersionsProvider);
      if (active.isEmpty) return null;
      final versionId = active.first; // Primary version
      final book = await ref.watch(
        bookByNameProvider((versionId: versionId, name: args.book)).future,
      );
      if (book == null) return null;

      final store = ref.watch(contentStoreProvider);
      final rows =
          await (store.select(store.verses)
                ..where(
                  (v) =>
                      v.bookId.equals(book.id) &
                      v.chapter.equals(args.chapter) &
                      v.verse.isBetweenValues(args.verse, args.verseEnd),
                )
                ..orderBy([(v) => OrderingTerm.asc(v.verse)]))
              .get();
      if (rows.isEmpty) return null;

      final parser = MyBibleVerseParser();
      String clean(String textContent) => parser
          .parseVerse(textContent)
          .where((s) => !s.isFootnote)
          .map((s) => s.text)
          .join('')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final versions = await ref.watch(versionsProvider.future);
      String abbreviation = versionId;
      for (final v in versions) {
        if (v.id == versionId) {
          abbreviation = v.abbreviation;
          break;
        }
      }

      return ExplorerVersePreview(
        versionAbbreviation: abbreviation,
        verses: [
          for (final row in rows)
            (verse: row.verse, text: clean(row.textContent)),
        ],
      );
    });
