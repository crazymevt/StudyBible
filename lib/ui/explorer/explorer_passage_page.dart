part of 'explorer_pages.dart';

// --- Passage ---

class _PassagePage extends ConsumerWidget {
  const _PassagePage({required this.book, required this.chapter});

  final String book;
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(
      explorerPassageOverviewProvider((book: book, chapter: chapter)),
    );
    final commentaries =
        ref
            .watch(
              explorerPassageCommentariesProvider((
                book: book,
                chapter: chapter,
              )),
            )
            .asData
            ?.value ??
        const <ExplorerCommentarySection>[];
    final crossRefGroups =
        ref
            .watch(
              explorerPassageCrossReferencesProvider((
                book: book,
                chapter: chapter,
              )),
            )
            .asData
            ?.value ??
        const <ExplorerCrossRefGroup>[];
    final passageSermons =
        ref
            .watch(explorerSermonsProvider(ExplorerRef.passage(book, chapter)))
            .asData
            ?.value ??
        const <SearchResult>[];
    final passageNotebookPages =
        ref
            .watch(
              explorerNotebookPagesProvider(ExplorerRef.passage(book, chapter)),
            )
            .asData
            ?.value ??
        const <SearchResult>[];
    final notes =
        ref
            .watch(
              chapterNotesFamilyProvider((bookName: book, chapter: chapter)),
            )
            .asData
            ?.value ??
        const <Note>[];
    final passageTags =
        ref
            .watch(explorerPassageTagsProvider((book: book, chapter: chapter)))
            .asData
            ?.value ??
        const <ExplorerPassageTag>[];
    final videoGroups = ref.watch(
      chapterMediaProvider((book: book, chapter: chapter)),
    );
    final attachments =
        ref
            .watch(chapterAttachmentsProvider((book: book, chapter: chapter)))
            .asData
            ?.value ??
        const <MediaAttachment>[];
    final prophecyHits =
        ref.watch(prophecyChapterIndexProvider)[prophecyChapterKey(
          book,
          chapter,
        )] ??
        const <ProphecyChapterHit>[];
    final referenceHits =
        ref.watch(referenceChapterIndexProvider)[referenceChapterKey(
          book,
          chapter,
        )] ??
        const <ReferenceChapterHit>[];
    return overviewAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this passage: $e'),
      data: (d) {
        return _PageScroll(
          children: [
            _PageTitle(
              title: '$book $chapter',
              trailing: FilledButton.tonalIcon(
                icon: const Icon(Icons.menu_book, size: 18),
                label: const Text('Open in reader'),
                onPressed: () =>
                    explorerOpenVerseInReader(context, ref, book, chapter, 1),
              ),
            ),
            if (d.isEmpty &&
                commentaries.isEmpty &&
                crossRefGroups.isEmpty &&
                passageSermons.isEmpty &&
                passageNotebookPages.isEmpty &&
                notes.isEmpty &&
                passageTags.isEmpty &&
                videoGroups.isEmpty &&
                attachments.isEmpty &&
                prophecyHits.isEmpty &&
                referenceHits.isEmpty)
              const _ErrorBody(
                'The datasets don\'t tag anything in this chapter yet.',
              ),
            if (d.people.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'People (${d.people.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in d.people)
                      ExplorerRefChip(
                        ExplorerRef.person(p.id, p.displayTitle),
                        subtitle: 'v. ${p.verses.join(', ')}',
                      ),
                  ],
                ),
              ),
            if (d.places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Places (${d.places.length})',
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
                          ExplorerRefChip(
                            ExplorerRef.place(p.id, p.name),
                            subtitle: 'v. ${p.verses.join(', ')}',
                          ),
                      ],
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
                            .open(ExplorerRef.event(e.id, e.title)),
                      ),
                  ],
                ),
              ),
            if (d.topics.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.topic_outlined,
                title: 'Topics (${d.topics.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in d.topics)
                      ExplorerRefChip(ExplorerRef.topic(t.id, t.name)),
                  ],
                ),
              ),
            if (prophecyHits.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Prophecies (${prophecyHits.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final h in prophecyHits)
                      ExplorerRefChip(
                        ExplorerRef.prophecy(h.index, h.title),
                        subtitle: _prophecyRoleLabel(h),
                      ),
                  ],
                ),
              ),
            if (referenceHits.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.table_chart_outlined,
                title: 'Reference (${referenceHits.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final h in referenceHits)
                      h.explorerPersonId != null
                          ? ExplorerRefChip(
                              ExplorerRef.person(h.explorerPersonId!, h.title),
                              subtitle: h.kind.label,
                            )
                          : Chip(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              avatar: const Icon(Icons.table_chart, size: 16),
                              label: Text.rich(
                                TextSpan(
                                  text: h.title,
                                  children: [
                                    TextSpan(
                                      text: '  ${h.kind.label}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
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
            if (commentaries.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.import_contacts_outlined,
                title: 'Commentaries (${commentaries.length})',
                child: Column(
                  children: [
                    for (final section in commentaries)
                      _CommentarySection(section: section),
                  ],
                ),
              ),
            if (crossRefGroups.isNotEmpty)
              ExplorerCollapsibleFacetCard(
                icon: Icons.compare_arrows_outlined,
                title:
                    'Cross-references '
                    '(${crossRefGroups.fold(0, (n, g) => n + g.refs.length)})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in crossRefGroups)
                      _CrossRefGroupTile(group: group),
                  ],
                ),
              ),
            if (passageSermons.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.co_present_outlined,
                title: 'Your sermons (${passageSermons.length})',
                child: Column(
                  children: [
                    for (final s in passageSermons) _TaggedItemTile(item: s),
                  ],
                ),
              ),
            if (passageNotebookPages.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.library_books_outlined,
                title: 'Your notebooks (${passageNotebookPages.length})',
                child: Column(
                  children: [
                    for (final n in passageNotebookPages)
                      _TaggedItemTile(item: n),
                  ],
                ),
              ),
            if (notes.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.edit_note_outlined,
                title: 'Your notes (${notes.length})',
                child: Column(
                  children: [
                    for (final n in notes)
                      _PassageNoteTile(book: book, chapter: chapter, note: n),
                  ],
                ),
              ),
            if (passageTags.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.label_outline,
                title: 'Your tags (${passageTags.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in passageTags)
                      ExplorerTagChip(
                        t.tag,
                        subtitle: 'v. ${t.verses.join(', ')}',
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One source verse's cross-references, capped so a single heavily
/// cross-referenced verse (common in Psalms/Gospels) can't dominate the card.
class _CrossRefGroupTile extends StatelessWidget {
  const _CrossRefGroupTile({required this.group});

  final ExplorerCrossRefGroup group;

  static const _maxShown = 6;

  @override
  Widget build(BuildContext context) {
    final shown = group.refs.take(_maxShown).toList();
    final remaining = group.refs.length - shown.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'v. ${group.verse}',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final xref in shown)
                ExplorerVerseChip(
                  book: xref.targetBookName,
                  chapter: xref.targetChapter,
                  verse: xref.targetVerse,
                ),
              if (remaining > 0)
                Text(
                  '+$remaining more',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One commentary module's chapter entries, collapsed behind the module name
/// so several installed commentaries stay scannable.
class _CommentarySection extends StatelessWidget {
  const _CommentarySection({required this.section});

  final ExplorerCommentarySection section;

  @override
  Widget build(BuildContext context) {
    final count = section.entries.length;
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      title: Text(section.commentary.name),
      subtitle: Text('$count ${count == 1 ? 'entry' : 'entries'}'),
      children: [
        for (final entry in section.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.verse != null && entry.verse! > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'Verse ${entry.verse}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                HtmlWidget(entry.textContent),
              ],
            ),
          ),
      ],
    );
  }
}

/// The "Dictionary" facet card for a place or topic: the matching headword
/// entry from every installed dictionary, grouped by module. Definitions are
/// HTML (SWORD/MyBible), so they render through [HtmlWidget]. Only built when
/// [entries] is non-empty, so a page with no dictionary hits shows no card.
class _DictionaryCard extends StatelessWidget {
  const _DictionaryCard({required this.entries});

  final List<DictionaryEntryWithDict> entries;

  @override
  Widget build(BuildContext context) {
    // Group by dictionary, preserving first-seen order.
    final byDictionary = <int, List<DictionaryEntry>>{};
    final dictionaries = <int, Dictionary>{};
    for (final e in entries) {
      dictionaries[e.dictionary.id] = e.dictionary;
      byDictionary.putIfAbsent(e.dictionary.id, () => []).add(e.entry);
    }
    final single = byDictionary.length == 1;
    return ExplorerFacetCard(
      icon: Icons.book_outlined,
      title: 'Dictionary',
      child: Column(
        children: [
          for (final id in byDictionary.keys)
            _DictionarySection(
              dictionaryName: dictionaries[id]!.name,
              entries: byDictionary[id]!,
              initiallyExpanded: single,
            ),
        ],
      ),
    );
  }
}

/// One dictionary module's matching entries, collapsed behind the module name
/// (auto-expanded when it's the only module) to mirror [_CommentarySection].
class _DictionarySection extends StatelessWidget {
  const _DictionarySection({
    required this.dictionaryName,
    required this.entries,
    required this.initiallyExpanded,
  });

  final String dictionaryName;
  final List<DictionaryEntry> entries;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final count = entries.length;
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: initiallyExpanded,
      title: Text(dictionaryName),
      subtitle: Text('$count ${count == 1 ? 'entry' : 'entries'}'),
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    entry.word,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                HtmlWidget(entry.definition),
              ],
            ),
          ),
      ],
    );
  }
}

/// A small "Book Chapter" subheader above one location's share of a topic's
/// aggregated facet card — only shown when the topic cites more than one
/// chapter (see [_TopicPage]'s `multiLocation`), so a single-chapter feast or
/// story reads exactly like the passage page it borrows these cards from.
class _TopicLocationLabel extends StatelessWidget {
  const _TopicLocationLabel(this.book, this.chapter);

  final String book;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(
        '$book $chapter',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Merges a topic's per-chapter places into one deduped, name-ordered list —
/// the map/chips on the topic page plot every chapter's markers together. A
/// place's merged `verses` list mixes verse numbers across whatever chapters
/// it appeared in, so it's only meaningful (and only shown) when the topic
/// has just one location — see the `multiLocation` check where this is used.
List<PlaceInPassage> _mergeTopicPlaces(
  List<ExplorerTopicLocationFacets> facets,
) {
  final byId = <int, PlaceInPassage>{};
  for (final f in facets) {
    for (final p in f.places) {
      final existing = byId[p.id];
      if (existing == null) {
        byId[p.id] = PlaceInPassage(
          id: p.id,
          name: p.name,
          lat: p.lat,
          lng: p.lng,
          verses: [...p.verses],
        );
      } else {
        existing.verses.addAll(p.verses);
      }
    }
  }
  return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}

/// Merges a topic's per-chapter video groups into one group per collection,
/// de-duplicating items a story's overlapping chapters would otherwise list
/// twice (matched by youtube id/slug, falling back to title).
List<MediaGroup> _mergeTopicVideoGroups(
  List<ExplorerTopicLocationFacets> facets,
) {
  final merged = <String, MediaGroup>{};
  final seenKeys = <String, Set<String>>{};
  for (final f in facets) {
    for (final g in f.videoGroups) {
      final keys = seenKeys.putIfAbsent(g.collection.name, () => {});
      final newItems = [
        for (final item in g.items)
          if (keys.add(item.id ?? item.slug ?? item.title)) item,
      ];
      if (newItems.isEmpty) continue;
      final existing = merged[g.collection.name];
      merged[g.collection.name] = MediaGroup(
        collection: g.collection,
        items: existing == null ? newItems : [...existing.items, ...newItems],
      );
    }
  }
  return merged.values.toList();
}

/// Merges a topic's per-chapter media attachments, de-duplicating by id (an
/// attachment tagged to more than one of a story's chapters would otherwise
/// appear once per chapter).
List<MediaAttachment> _mergeTopicAttachments(
  List<ExplorerTopicLocationFacets> facets,
) {
  final byId = <String, MediaAttachment>{};
  for (final f in facets) {
    for (final a in f.attachments) {
      byId[a.id] = a;
    }
  }
  return byId.values.toList();
}
