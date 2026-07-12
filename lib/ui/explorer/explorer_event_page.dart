part of 'explorer_pages.dart';

// --- Event ---

class _EventPage extends ConsumerWidget {
  const _EventPage({required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(explorerEventDetailProvider(eventId));
    final tags =
        ref.watch(explorerEventTagsProvider(eventId)).asData?.value ??
        const <ExplorerEntityTag>[];
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this event: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Event not found.');
        final sermons =
            ref
                .watch(
                  explorerSermonsProvider(
                    ExplorerRef.event(d.event.id, d.event.title),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final notebookPages =
            ref
                .watch(
                  explorerNotebookPagesProvider(
                    ExplorerRef.event(d.event.id, d.event.title),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        return _PageScroll(
          children: [
            _PageTitle(
              title: d.event.title,
              subtitle: d.event.startYear == null
                  ? null
                  : explorerYearLabel(d.event.startYear!),
              trailing: d.verses.isEmpty
                  ? null
                  : FilledButton.tonalIcon(
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('Read the account'),
                      onPressed: () => explorerOpenVerseInReader(
                        context,
                        ref,
                        d.verses.first.bookName,
                        d.verses.first.chapter,
                        d.verses.first.verse,
                      ),
                    ),
            ),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title: 'The account',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final v in d.verses)
                      ExplorerVerseChip(
                        book: v.bookName,
                        chapter: v.chapter,
                        verse: v.verse,
                      ),
                  ],
                ),
              ),
            if (d.participants.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'Who was there (${d.participants.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in d.participants)
                      ExplorerRefChip(ExplorerRef.person(p.id, p.displayTitle)),
                  ],
                ),
              ),
            if (d.places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: d.places.length == d.placesTotalCount
                    ? 'Where it happened'
                    : 'Where it happened (${d.places.length} of '
                          '${d.placesTotalCount})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(
                      places: [
                        for (final p in d.places)
                          ExplorerMapPlace(p.id, p.name, p.lat, p.lng),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in d.places)
                          ExplorerRefChip(ExplorerRef.place(p.id, p.name)),
                      ],
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
      },
    );
  }
}
