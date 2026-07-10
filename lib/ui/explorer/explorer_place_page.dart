part of 'explorer_pages.dart';

// --- Place ---

class _PlacePage extends ConsumerWidget {
  const _PlacePage({required this.placeId});

  final int placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(explorerPlaceDetailProvider(placeId));
    final tags =
        ref.watch(explorerPlaceTagsProvider(placeId)).asData?.value ??
        const <ExplorerEntityTag>[];
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this place: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Place not found.');
        final dictionary =
            ref
                .watch(explorerEntryDictionaryProvider(d.place.name))
                .asData
                ?.value ??
            const <DictionaryEntryWithDict>[];
        final sermons =
            ref
                .watch(
                  explorerSermonsProvider(
                    ExplorerRef.place(d.place.id, d.place.name),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final notebookPages =
            ref
                .watch(
                  explorerNotebookPagesProvider(
                    ExplorerRef.place(d.place.id, d.place.name),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        return _PageScroll(
          children: [
            _PageTitle(
              title: d.place.name,
              subtitle:
                  '${d.verses.length} '
                  '${d.verses.length == 1 ? 'verse mentions' : 'verses mention'} '
                  'this place',
            ),
            ExplorerMap(
              places: [
                ExplorerMapPlace(
                  d.place.id,
                  d.place.name,
                  d.place.lat,
                  d.place.lng,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (dictionary.isNotEmpty) _DictionaryCard(entries: dictionary),
            if (d.events.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.flag_outlined,
                title: 'Events here (${d.events.length})',
                child: Column(
                  children: [
                    for (final e in d.events)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.title),
                        subtitle: e.startYear == null
                            ? null
                            : Text(explorerYearLabel(e.startYear!)),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => ref
                            .read(explorerTrailProvider.notifier)
                            .open(ExplorerRef.event(e.id, e.title)),
                      ),
                  ],
                ),
              ),
            if (d.people.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'People mentioned here',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in d.people)
                      ExplorerRefChip(ExplorerRef.person(p.id, p.displayTitle)),
                  ],
                ),
              ),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title:
                    'Mentioned in ${d.verses.length} '
                    '${d.verses.length == 1 ? 'verse' : 'verses'}',
                child: ExplorerVerseGroups(
                  refs: [
                    for (final v in d.verses)
                      (book: v.bookName, chapter: v.chapter, verse: v.verse),
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
