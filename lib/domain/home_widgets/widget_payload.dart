/// Pure builders for the JSON payloads the home-screen widgets render.
///
/// The Flutter side never draws a widget: `HomeWidgetSyncController` (app
/// layer) serializes these maps into the plugin's shared storage and the
/// small native widget UIs read them back. Keep everything here pure Dart —
/// `tool/lint_domain.sh` enforces no Flutter/`dart:io` imports.
library;

import 'package:intl/intl.dart';

import 'widget_deep_link.dart';

/// Rows shown by the two list widgets. Kept small on purpose: a home-screen
/// widget is a glance surface, not a second app.
const int kWidgetListCap = 5;

// ---------------------------------------------------------------------------
// Verse of the day
// ---------------------------------------------------------------------------

/// One curated verse, decoupled from the data layer's `VerseDef` so this
/// stays importable from anywhere.
typedef VerseDaySource = ({String reference, String text});

/// Parses a curated-list reference like `John 3:16`, `Proverbs 3:5-6`, or
/// `1 John 4:19` into its parts (a range keeps only its start verse).
/// Returns null when the shape is unrecognized.
({String bookName, int chapter, int verse})? parseVerseDayReference(
  String reference,
) {
  final lastSpace = reference.lastIndexOf(' ');
  if (lastSpace <= 0) return null;

  final bookName = reference.substring(0, lastSpace);
  final chapterVerse = reference.substring(lastSpace + 1);
  final colon = chapterVerse.indexOf(':');
  if (colon == -1) return null;

  final chapter = int.tryParse(chapterVerse.substring(0, colon));
  final versePart = chapterVerse.substring(colon + 1);
  final dash = versePart.indexOf('-');
  final verse =
      int.tryParse(dash == -1 ? versePart : versePart.substring(0, dash));
  if (chapter == null || chapter < 1 || verse == null || verse < 1) {
    return null;
  }
  return (bookName: bookName, chapter: chapter, verse: verse);
}

/// The full curated list, one entry per verse. The native side picks today's
/// entry with the dashboard's formula — `daysSinceJan1 % length` — so the
/// widget rolls over at midnight forever without the app running.
/// Entries whose reference can't be parsed simply omit `uri` (tap then opens
/// the app without navigating).
Map<String, Object?> buildVerseOfTheDayPayload(List<VerseDaySource> verses) {
  return {
    'verses': [
      for (final v in verses)
        {
          'reference': v.reference,
          'text': v.text,
          if (parseVerseDayReference(v.reference) case final ref?)
            'uri': buildReadVerseUri(
              bookName: ref.bookName,
              chapter: ref.chapter,
              verse: ref.verse,
            ).toString(),
        },
    ],
  };
}

// ---------------------------------------------------------------------------
// Upcoming actions
// ---------------------------------------------------------------------------

typedef ActionSource = ({
  String id,
  String title,
  int? dueAt,
  int? completedAt,
  bool deleted,
});

/// Matches `ActionItemsPanel._dueFormat` so the widget and the in-app list
/// read the same.
final DateFormat _dueFormat = DateFormat('MMM d, y · h:mm a');

/// The next [kWidgetListCap] open actions with a due time, soonest first.
/// `overdue` is computed against [nowMs] at build time; it's refreshed on
/// every app open and on the widget's periodic native update, which is fresh
/// enough for a glance surface.
Map<String, Object?> buildUpcomingActionsPayload(
  List<ActionSource> items, {
  required int nowMs,
}) {
  final upcoming = items
      .where((a) => !a.deleted && a.completedAt == null && a.dueAt != null)
      .toList()
    ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

  return {
    'uri': buildActionsUri().toString(),
    'items': [
      for (final a in upcoming.take(kWidgetListCap))
        {
          'id': a.id,
          'title': a.title,
          'dueLabel': _dueFormat
              .format(DateTime.fromMillisecondsSinceEpoch(a.dueAt!)),
          'overdue': nowMs >= a.dueAt!,
        },
    ],
  };
}

// ---------------------------------------------------------------------------
// Ribbons
// ---------------------------------------------------------------------------

typedef RibbonSource = ({
  String bookName,
  int chapter,
  int verse,
  String label,
  int updatedAt,
});

/// The [kWidgetListCap] most recently placed ribbons, newest first (same
/// ordering as `allBookmarksProvider`). Each row deep-links to its verse.
Map<String, Object?> buildRibbonsPayload(List<RibbonSource> ribbons) {
  final sorted = [...ribbons]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return {
    'items': [
      for (final r in sorted.take(kWidgetListCap))
        {
          'reference': '${r.bookName} ${r.chapter}:${r.verse}',
          'label': r.label,
          'uri': buildReadVerseUri(
            bookName: r.bookName,
            chapter: r.chapter,
            verse: r.verse,
          ).toString(),
        },
    ],
  };
}
