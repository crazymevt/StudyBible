part of 'explorer_pages.dart';

/// A single thematic thread from the pure-Dart `threads` dataset: the walk's
/// overview, then every stop in canonical order with its passage and
/// connective note. "Walk this thread" (and each stop's "walk from here")
/// hands the thread to the reader's walk chip — see `thread_walk_chip.dart`.
/// The user-content facets (sermons/notebooks/tags) are async, same as the
/// prophecy page.
class _ThreadPage extends ConsumerWidget {
  const _ThreadPage({required this.index});

  final int index;

  void _walkFrom(BuildContext context, WidgetRef ref, int stop) {
    // start() sends the reader to the stop (module + location + nav
    // highlight, no verse selection — same behavior as a sermon route);
    // unwinding the Explorer route makes it visible.
    ref.read(threadWalkProvider.notifier).start(index, stop: stop);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (index < 0 || index >= threads.length) {
      return const _ErrorBody('Thread not found.');
    }
    final thread = threads[index];
    final walk = ref.watch(threadWalkProvider);
    final walkingThis = walk?.threadIndex == index;
    final entityRef = ExplorerRef.thread(index, thread.title);
    final sermons =
        ref.watch(explorerSermonsProvider(entityRef)).asData?.value ??
        const <SearchResult>[];
    final notebookPages =
        ref.watch(explorerNotebookPagesProvider(entityRef)).asData?.value ??
        const <SearchResult>[];
    final tags =
        ref.watch(explorerThreadTagsProvider(index)).asData?.value ??
        const <ExplorerEntityTag>[];
    final scheme = Theme.of(context).colorScheme;
    return _PageScroll(
      children: [
        _PageTitle(
          title: thread.title,
          subtitle: '${thread.category.label} · ${thread.stops.length} stops',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            thread.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.directions_walk),
            label: Text(
              walkingThis
                  ? 'Continue the walk · stop ${walk!.stop + 1} of '
                      '${thread.stops.length}'
                  : 'Walk this thread',
            ),
            onPressed: () =>
                _walkFrom(context, ref, walkingThis ? walk!.stop : 0),
          ),
        ),
        ExplorerFacetCard(
          icon: Icons.route_outlined,
          title: 'The stops',
          child: Column(
            children: [
              for (var i = 0; i < thread.stops.length; i++)
                _ThreadStopTile(
                  number: i + 1,
                  stop: thread.stops[i],
                  active: walkingThis && walk!.stop == i,
                  onWalkFrom: () => _walkFrom(context, ref, i),
                ),
            ],
          ),
        ),
        if (sermons.isNotEmpty)
          ExplorerFacetCard(
            icon: Icons.co_present_outlined,
            title: 'Your sermons (${sermons.length})',
            child: Column(
              children: [for (final s in sermons) _TaggedItemTile(item: s)],
            ),
          ),
        if (notebookPages.isNotEmpty)
          ExplorerFacetCard(
            icon: Icons.library_books_outlined,
            title: 'Your notebooks (${notebookPages.length})',
            child: Column(
              children: [
                for (final n in notebookPages) _TaggedItemTile(item: n),
              ],
            ),
          ),
        if (tags.isNotEmpty) _EntityTagsCard(tags: tags),
      ],
    );
  }
}

/// One stop of the walk: numbered marker, headline, passage chip, and the
/// connective note. The stop the active walk is currently on is highlighted;
/// the trailing action starts (or restarts) the walk from this stop.
class _ThreadStopTile extends StatelessWidget {
  const _ThreadStopTile({
    required this.number,
    required this.stop,
    required this.active,
    required this.onWalkFrom,
  });

  final int number;
  final ThreadStop stop;
  final bool active;
  final VoidCallback onWalkFrom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final citation = PassageCitation.tryParse(stop.passage);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: active
          ? BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor:
                active ? scheme.primary : scheme.surfaceContainerHighest,
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  stop.note,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                if (citation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ExplorerVerseChip(
                        book: citation.book,
                        chapter: citation.chapter,
                        verse: citation.verse ?? 1,
                        verseEnd: citation.endVerse,
                        label: stop.passage,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.directions_walk, size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: 'Walk from here',
            color: scheme.primary,
            onPressed: onWalkFrom,
          ),
        ],
      ),
    );
  }
}
