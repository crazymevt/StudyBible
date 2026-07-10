part of 'explorer_pages.dart';

// --- Person ---

class _PersonPage extends ConsumerWidget {
  const _PersonPage({required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(personDetailProvider(personId));
    final placesAsync = ref.watch(explorerPersonPlacesProvider(personId));
    final stories =
        ref.watch(explorerPersonStoriesProvider(personId)).asData?.value ??
        const <ExplorerTopicHit>[];
    final tags =
        ref.watch(explorerPersonTagsProvider(personId)).asData?.value ??
        const <ExplorerEntityTag>[];
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this person: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Person not found.');
        final p = d.person;
        final sermons =
            ref
                .watch(
                  explorerSermonsProvider(
                    ExplorerRef.person(p.id, p.displayTitle),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final notebookPages =
            ref
                .watch(
                  explorerNotebookPagesProvider(
                    ExplorerRef.person(p.id, p.displayTitle),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final years = <String>[
          if (p.birthYear != null && p.deathYear != null)
            '${explorerYearLabel(p.birthYear!)} – ${explorerYearLabel(p.deathYear!)}'
          else if (p.birthYear != null)
            'born ${explorerYearLabel(p.birthYear!)}'
          else if (p.deathYear != null)
            'died ${explorerYearLabel(p.deathYear!)}',
        ];
        final subtitle = [
          if (p.gender != null) p.gender!,
          ...years,
          if (d.groups.isNotEmpty) d.groups.join(', '),
          if (p.alsoCalled != null) 'also called ${p.alsoCalled}',
        ].join(' · ');

        final family = <(String, List<BiblePerson>)>[
          if (d.father != null) ('Father', [d.father!]),
          if (d.mother != null) ('Mother', [d.mother!]),
          if (d.partners.isNotEmpty)
            (d.partners.length == 1 ? 'Spouse' : 'Spouses', d.partners),
          if (d.siblings.isNotEmpty) ('Siblings', d.siblings),
          if (d.children.isNotEmpty) ('Children', d.children),
        ];

        final places = placesAsync.asData?.value ?? const <Place>[];

        return _PageScroll(
          children: [
            _PageTitle(title: p.displayTitle, subtitle: subtitle),
            if (p.bio != null)
              ExplorerFacetCard(
                icon: Icons.auto_stories_outlined,
                title: 'Biography — Easton\'s Bible Dictionary',
                child: _ExpandableText(p.bio!),
              ),
            if (family.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.family_restroom,
                title: 'Family',
                trailing:
                    d.father == null && d.mother == null && d.children.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.account_tree_outlined),
                        tooltip: 'View family tree',
                        onPressed: () =>
                            Navigator.of(context).push(familyTreeRoute(p.id)),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (label, people) in family)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 72,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final person in people)
                                    ExplorerRefChip(
                                      ExplorerRef.person(
                                        person.id,
                                        person.displayTitle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (d.events.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.flag_outlined,
                title: 'Events (${d.events.length})',
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
                            .open(ExplorerRef.event(e.eventId, e.title)),
                      ),
                  ],
                ),
              ),
            if (stories.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.topic_outlined,
                title: 'Their stories',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in stories)
                      ExplorerRefChip(ExplorerRef.topic(s.id, s.name)),
                  ],
                ),
              ),
            if (places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Places in their story',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(
                      journeyPersonId: personId,
                      places: [
                        for (final pl in places)
                          ExplorerMapPlace(pl.id, pl.name, pl.lat, pl.lng),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final pl in places)
                          ExplorerRefChip(ExplorerRef.place(pl.id, pl.name)),
                      ],
                    ),
                  ],
                ),
              ),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title:
                    'Appears in ${d.verses.length} '
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
