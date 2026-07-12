part of 'explorer_pages.dart';

// --- Topic ---

class _TopicPage extends ConsumerWidget {
  const _TopicPage({required this.topicId});

  final int topicId;

  Future<void> _openSeeAlso(WidgetRef ref, String name) async {
    final id = await ref.read(topicIdByNameProvider(name).future);
    if (id != null) {
      ref
          .read(explorerTrailProvider.notifier)
          .open(ExplorerRef.topic(id, name.trim().toUpperCase()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(topicDetailProvider(topicId));
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this topic: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Topic not found.');
        final dictionary =
            ref
                .watch(explorerEntryDictionaryProvider(d.topic.name))
                .asData
                ?.value ??
            const <DictionaryEntryWithDict>[];
        final sermons =
            ref
                .watch(
                  explorerSermonsProvider(
                    ExplorerRef.topic(d.topic.id, d.topic.name),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final notebookPages =
            ref
                .watch(
                  explorerNotebookPagesProvider(
                    ExplorerRef.topic(d.topic.id, d.topic.name),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final passageFacets =
            ref
                .watch(explorerTopicPassageFacetsProvider(topicId))
                .asData
                ?.value ??
            const <ExplorerTopicLocationFacets>[];
        final multiLocation = passageFacets.length > 1;
        final places = _mergeTopicPlaces(passageFacets);
        final videoGroups = _mergeTopicVideoGroups(passageFacets);
        final attachments = _mergeTopicAttachments(passageFacets);
        final namedGroupPersonId = ref.watch(
          namedGroupPersonIdsProvider,
        )['${d.topic.category}|${d.topic.name}'];
        return _PageScroll(
          children: [
            _PageTitle(
              title: d.topic.name,
              subtitle: switch (d.topic.category) {
                'feast' => 'Bible feast',
                'story' => 'Bible story',
                'tribe' => 'One of the 12 Tribes of Israel',
                'apostle' => 'One of the 12 Apostles',
                'judge' => 'A Judge of Israel',
                'prophet' => 'A Major or Minor Prophet',
                _ => 'Nave\'s Topical Bible',
              },
            ),
            if (namedGroupPersonId != null)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'Person',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ExplorerRefChip(
                      ExplorerRef.person(namedGroupPersonId, d.topic.name),
                    ),
                  ],
                ),
              ),
            if (dictionary.isNotEmpty) _DictionaryCard(entries: dictionary),
            for (final ev in d.entries)
              ExplorerFacetCard(
                icon: Icons.notes,
                title: ev.entry.description,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ev.refs.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final r in ev.refs)
                            ExplorerVerseChip(
                              book: r.bookName,
                              chapter: r.chapter,
                              verse: r.verse ?? 1,
                              verseEnd: r.verseEnd,
                              label: r.verse == null
                                  ? '${r.bookName} ${r.chapter}'
                                  : '${r.bookName} ${r.chapter}:${r.verse}'
                                        '${r.verseEnd != null ? '–${r.verseEnd}' : ''}',
                            ),
                        ],
                      ),
                    if (ev.entry.seeAlso != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in ev.entry.seeAlso!.split('\n'))
                            ActionChip(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              avatar: const Icon(Icons.link, size: 16),
                              label: Text('See also: $s'),
                              onPressed: () => _openSeeAlso(ref, s),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            if (places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Places (${places.length})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(
                      places: [
                        for (final p in places)
                          ExplorerMapPlace(p.id, p.name, p.lat, p.lng),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in places)
                          ExplorerRefChip(
                            ExplorerRef.place(p.id, p.name),
                            // A merged verse list only makes sense within a
                            // single chapter — see [_mergeTopicPlaces].
                            subtitle: multiLocation
                                ? null
                                : 'v. ${p.verses.join(', ')}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            for (final group in videoGroups)
              ExplorerFacetCard(
                icon: Icons.play_circle_outline,
                title: '${group.collection.name} (${group.items.length})',
                child: Column(
                  children: [
                    for (final item in group.items) MediaVideoTile(item: item),
                  ],
                ),
              ),
            if (attachments.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.attachment_outlined,
                title: 'Your media (${attachments.length})',
                child: Column(
                  children: [
                    for (final a in attachments) _AttachmentTile(attachment: a),
                  ],
                ),
              ),
            if (passageFacets.any((f) => f.commentaries.isNotEmpty))
              ExplorerFacetCard(
                icon: Icons.import_contacts_outlined,
                title: 'Commentaries',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in passageFacets)
                      if (f.commentaries.isNotEmpty) ...[
                        if (multiLocation)
                          _TopicLocationLabel(f.book, f.chapter),
                        for (final section in f.commentaries)
                          _CommentarySection(section: section),
                      ],
                  ],
                ),
              ),
            if (passageFacets.any((f) => f.crossRefGroups.isNotEmpty))
              ExplorerCollapsibleFacetCard(
                icon: Icons.compare_arrows_outlined,
                title:
                    'Cross-references '
                    '(${passageFacets.fold(0, (n, f) => n + f.crossRefGroups.fold(0, (m, g) => m + g.refs.length))})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in passageFacets)
                      if (f.crossRefGroups.isNotEmpty) ...[
                        if (multiLocation)
                          _TopicLocationLabel(f.book, f.chapter),
                        for (final group in f.crossRefGroups)
                          _CrossRefGroupTile(group: group),
                      ],
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
            if (passageFacets.any((f) => f.notes.isNotEmpty))
              ExplorerFacetCard(
                icon: Icons.edit_note_outlined,
                title: 'Your notes',
                child: Column(
                  children: [
                    for (final f in passageFacets)
                      if (f.notes.isNotEmpty)
                        for (final n in f.notes)
                          _PassageNoteTile(
                            book: f.book,
                            chapter: f.chapter,
                            note: n,
                          ),
                  ],
                ),
              ),
            if (passageFacets.any((f) => f.tags.isNotEmpty))
              ExplorerFacetCard(
                icon: Icons.label_outline,
                title: 'Your tags',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in passageFacets)
                      if (f.tags.isNotEmpty) ...[
                        if (multiLocation)
                          _TopicLocationLabel(f.book, f.chapter),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in f.tags)
                              ExplorerTagChip(
                                t.tag,
                                subtitle: 'v. ${t.verses.join(', ')}',
                              ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
