import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/achievement_service.dart' show bibleChapters;
import '../../app/book_usage_providers.dart';
import '../../domain/dashboard/book_activity.dart';
import 'book_usage_screen.dart';

Route<void> bookChapterUsageRoute(String bookName) => MaterialPageRoute(
  settings: const RouteSettings(name: 'book_chapter_usage'),
  builder: (_) => BookChapterUsageScreen(bookName: bookName),
);

class BookChapterUsageScreen extends ConsumerWidget {
  final String bookName;

  const BookChapterUsageScreen({super.key, required this.bookName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterCounts =
        ref.watch(bookChapterActivityProvider(bookName)).value ?? {};
    final totalChapters = bibleChapters[bookName] ?? chapterCounts.length;
    final studiedCount =
        chapterCounts.values.where((c) => !c.isEmpty).length;
    final maxTotal = chapterCounts.values.isEmpty
        ? 0
        : chapterCounts.values.map((c) => c.total).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(bookName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$studiedCount of $totalChapters chapters have activity',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: totalChapters,
              itemBuilder: (context, index) {
                final chapter = index + 1;
                final counts = chapterCounts[chapter] ?? const ActivityCounts();
                return _ChapterUsageRow(
                  chapter: chapter,
                  counts: counts,
                  maxTotal: maxTotal,
                  onTap: () => openInReader(context, ref, bookName, chapter),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterUsageRow extends StatelessWidget {
  final int chapter;
  final ActivityCounts counts;
  final int maxTotal;
  final VoidCallback onTap;

  const _ChapterUsageRow({
    required this.chapter,
    required this.counts,
    required this.maxTotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    'Chapter $chapter',
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
