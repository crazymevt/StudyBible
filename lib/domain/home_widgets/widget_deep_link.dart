/// Deep-link URIs carried through the home-screen widgets' click plumbing
/// (`home_widget` delivers them back to Dart; no OS-level URL scheme
/// registration is involved).
library;

const String kWidgetUriScheme = 'studybible';

/// `studybible://read?book=John&chapter=3&verse=16` — opens the reader at a
/// verse. [verse] is optional so a whole-chapter link stays representable.
Uri buildReadVerseUri({
  required String bookName,
  required int chapter,
  int? verse,
}) {
  return Uri(
    scheme: kWidgetUriScheme,
    host: 'read',
    queryParameters: {
      'book': bookName,
      'chapter': '$chapter',
      if (verse != null) 'verse': '$verse',
    },
  );
}

/// `studybible://actions` — opens the journals/actions area.
Uri buildActionsUri() => Uri(scheme: kWidgetUriScheme, host: 'actions');

sealed class WidgetDeepLink {
  const WidgetDeepLink();
}

class ReadVerseDeepLink extends WidgetDeepLink {
  final String bookName;
  final int chapter;
  final int? verse;
  const ReadVerseDeepLink({
    required this.bookName,
    required this.chapter,
    this.verse,
  });
}

class OpenActionsDeepLink extends WidgetDeepLink {
  const OpenActionsDeepLink();
}

/// Parses a URI delivered by a widget tap. Returns null for anything
/// malformed or unrecognized — callers just ignore those.
WidgetDeepLink? parseWidgetDeepLink(Uri uri) {
  if (uri.scheme != kWidgetUriScheme) return null;
  switch (uri.host) {
    case 'read':
      final book = uri.queryParameters['book'];
      final chapter = int.tryParse(uri.queryParameters['chapter'] ?? '');
      if (book == null || book.isEmpty || chapter == null || chapter < 1) {
        return null;
      }
      final verse = int.tryParse(uri.queryParameters['verse'] ?? '');
      return ReadVerseDeepLink(
        bookName: book,
        chapter: chapter,
        verse: (verse != null && verse >= 1) ? verse : null,
      );
    case 'actions':
      return const OpenActionsDeepLink();
    default:
      return null;
  }
}
