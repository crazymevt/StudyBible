import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/achievement_service.dart' show bibleChapters;
import '../../app/book_usage_providers.dart';
import '../../app/reader_state.dart';
import '../../app/app_state.dart';
import '../../domain/dashboard/book_activity.dart';
import 'book_chapter_usage_screen.dart';

/// Category colors shared by the book list and the chapter drill-down so the
/// two screens read as one system.
const highlightActivityColor = Colors.amber;
const noteActivityColor = Colors.blue;
const sermonActivityColor = Colors.deepPurple;
const notebookActivityColor = Colors.teal;
const tagActivityColor = Colors.pink;

/// Sets the reader's selection to [book]/[chapter], switches to the Reader
/// module, and pops every pushed dashboard route so the module switch is
/// actually visible (this screen and any drill-down above it are pushed via
/// MaterialPageRoute, not shown as dialogs over the dashboard).
void openInReader(
  BuildContext context,
  WidgetRef ref,
  String book,
  int chapter,
) {
  ref.read(selectedBookNameProvider.notifier).set(book);
  ref.read(selectedChapterProvider.notifier).set(chapter);
  ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

enum _BookSort { readingOrder, mostUsed, leastUsed }

Route<void> bookUsageRoute() => MaterialPageRoute(
  settings: const RouteSettings(name: 'book_usage'),
  builder: (_) => const BookUsageScreen(),
);

class BookUsageScreen extends ConsumerStatefulWidget {
  const BookUsageScreen({super.key});

  @override
  ConsumerState<BookUsageScreen> createState() => _BookUsageScreenState();
}

class _BookUsageScreenState extends ConsumerState<BookUsageScreen> {
  _BookSort _sort = _BookSort.readingOrder;

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(bookActivityBreakdownProvider).value ?? {};
    final canonicalOrder = [
      for (final book in bibleChapters.keys)
        RankedBookActivity(book, breakdown[book] ?? const ActivityCounts()),
    ];
    final studiedCount = canonicalOrder.where((r) => !r.counts.isEmpty).length;
    final maxTotal = canonicalOrder.isEmpty
        ? 0
        : canonicalOrder.map((r) => r.counts.total).reduce((a, b) => a > b ? a : b);

    final ordered = switch (_sort) {
      _BookSort.readingOrder => canonicalOrder,
      _BookSort.mostUsed => ref.watch(rankedBookActivityProvider),
      _BookSort.leastUsed => ref.watch(rankedBookActivityProvider).reversed.toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Usage'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$studiedCount of ${canonicalOrder.length} books have '
                    'activity — ${canonicalOrder.length - studiedCount} '
                    'have none yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                DropdownButton<_BookSort>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: _BookSort.readingOrder,
                      child: Text('Reading Order'),
                    ),
                    DropdownMenuItem(
                      value: _BookSort.mostUsed,
                      child: Text('Most Used'),
                    ),
                    DropdownMenuItem(
                      value: _BookSort.leastUsed,
                      child: Text('Least Used'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ordered.length,
              itemBuilder: (context, index) {
                final entry = ordered[index];
                return _BookUsageRow(
                  entry: entry,
                  maxTotal: maxTotal,
                  onTap: () => Navigator.of(context)
                      .push(bookChapterUsageRoute(entry.bookName)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookUsageRow extends StatelessWidget {
  final RankedBookActivity entry;
  final int maxTotal;
  final VoidCallback onTap;

  const _BookUsageRow({
    required this.entry,
    required this.maxTotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counts = entry.counts;
    final isEmpty = counts.isEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.bookName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isEmpty
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                if (isEmpty)
                  Text(
                    'Not studied yet',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    '${counts.total}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ActivityBar(counts: counts, maxTotal: maxTotal),
            if (!isEmpty) ...[
              const SizedBox(height: 6),
              ActivityChips(counts: counts),
            ],
          ],
        ),
      ),
    );
  }
}

/// A proportional stacked bar: overall length ∝ [counts.total] relative to
/// [maxTotal] across the whole list, segments proportioned within the book's
/// own total. Zero-activity books render an outlined empty placeholder
/// instead of an easy-to-miss zero-length bar.
class ActivityBar extends StatelessWidget {
  final ActivityCounts counts;
  final int maxTotal;

  const ActivityBar({super.key, required this.counts, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    const height = 10.0;
    if (counts.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final fraction = maxTotal == 0 ? 0.0 : counts.total / maxTotal;
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * fraction.clamp(0.05, 1.0);
        return Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: barWidth,
              height: height,
              child: Row(
                children: [
                  if (counts.highlights > 0)
                    Expanded(
                      flex: counts.highlights,
                      child: Container(color: highlightActivityColor),
                    ),
                  if (counts.notes > 0)
                    Expanded(
                      flex: counts.notes,
                      child: Container(color: noteActivityColor),
                    ),
                  if (counts.sermonRefs > 0)
                    Expanded(
                      flex: counts.sermonRefs,
                      child: Container(color: sermonActivityColor),
                    ),
                  if (counts.notebookRefs > 0)
                    Expanded(
                      flex: counts.notebookRefs,
                      child: Container(color: notebookActivityColor),
                    ),
                  if (counts.taggedVerses > 0)
                    Expanded(
                      flex: counts.taggedVerses,
                      child: Container(color: tagActivityColor),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ActivityChips extends StatelessWidget {
  final ActivityCounts counts;

  const ActivityChips({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        if (counts.highlights > 0)
          _chip(highlightActivityColor, '${counts.highlights} highlights'),
        if (counts.notes > 0) _chip(noteActivityColor, '${counts.notes} notes'),
        if (counts.sermonRefs > 0)
          _chip(sermonActivityColor, '${counts.sermonRefs} sermons'),
        if (counts.notebookRefs > 0)
          _chip(notebookActivityColor, '${counts.notebookRefs} notebook'),
        if (counts.taggedVerses > 0)
          _chip(tagActivityColor, '${counts.taggedVerses} tagged'),
      ],
    );
  }

  Widget _chip(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}
