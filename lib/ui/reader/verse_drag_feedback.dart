import 'package:flutter/material.dart';
import '../../app/verse_selection.dart';
import '../../domain/scripture/verse_share_format.dart';

/// The floating card shown under the finger while dragging selected verses.
///
/// Shared by every drag source (verse tiles, parallel rows, the action bar's
/// drag handle) so a drag always looks the same regardless of where it
/// started. Shows the reference and a snippet of the first verse so the
/// payload is legible mid-drag, rather than an opaque "3 verse(s)" count.
class VerseDragFeedback extends StatelessWidget {
  final String reference;
  final String snippet;

  const VerseDragFeedback({
    super.key,
    required this.reference,
    required this.snippet,
  });

  factory VerseDragFeedback.fromSelection(VerseSelection sel) {
    return VerseDragFeedback(
      reference: VerseShareFormatter.reference(
        bookName: sel.book,
        chapter: sel.chapter,
        verseNumbers: sel.numbers,
        versionAbbreviation: sel.abbreviation,
      ),
      snippet: sel.verses.isEmpty ? '' : sel.verses.first.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8.0,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drag_indicator,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    reference,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                snippet,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
