part of 'explorer_pages.dart';

// --- Tag ---

class _TagPage extends ConsumerWidget {
  const _TagPage({required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(explorerTagDetailProvider(tagId));
    final crossRefs = ref
        .watch(explorerTagCrossRefsProvider(tagId))
        .asData
        ?.value;
    final commentaries =
        ref.watch(explorerTagCommentariesProvider(tagId)).asData?.value ??
        const <ExplorerCommentarySection>[];
    final crossRefGroups =
        ref.watch(explorerTagCrossReferencesProvider(tagId)).asData?.value ??
        const <ExplorerCrossRefGroup>[];
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this tag: $e'),
      data: (d) {
        if (d == null) {
          // Tags are user data: unlike the bundled entities, one can vanish
          // from under its breadcrumb (deleted here or on a synced device).
          return const _ErrorBody(
            'This tag no longer exists — it may have been deleted, '
            'possibly on another device.',
          );
        }
        return _PageScroll(
          children: [
            _PageTitle(title: '#${d.tag.name}', subtitle: 'Your tag'),
            if (d.isEmpty)
              const _ErrorBody('Nothing is filed under this tag yet.'),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title: 'Tagged verses (${d.verses.length})',
                child: Column(
                  children: [
                    for (final v in d.verses) _TaggedItemTile(item: v),
                  ],
                ),
              ),
            if (crossRefs != null && crossRefs.people.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'People in these verses (${crossRefs.people.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in crossRefs.people)
                      ExplorerRefChip(
                        ExplorerRef.person(p.id, p.label),
                        subtitle: _tagRefCountLabel(p.verseCount),
                      ),
                  ],
                ),
              ),
            if (crossRefs != null && crossRefs.places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Places in these verses (${crossRefs.places.length})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(
                      places: [
                        for (final p in crossRefs.places)
                          ExplorerMapPlace(p.id, p.label, p.lat!, p.lng!),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in crossRefs.places)
                          ExplorerRefChip(
                            ExplorerRef.place(p.id, p.label),
                            subtitle: _tagRefCountLabel(p.verseCount),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            if (crossRefs != null && crossRefs.events.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.flag_outlined,
                title: 'Events in these verses (${crossRefs.events.length})',
                child: Column(
                  children: [
                    for (final e in crossRefs.events)
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
            if (crossRefs != null && crossRefs.topics.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.topic_outlined,
                title: 'Topics in these verses (${crossRefs.topics.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in crossRefs.topics)
                      ExplorerRefChip(
                        ExplorerRef.topic(t.id, t.label),
                        subtitle: _tagRefCountLabel(t.verseCount),
                      ),
                  ],
                ),
              ),
            if (d.passages.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.travel_explore,
                title: 'Explore their chapters',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in d.passages)
                      ExplorerRefChip(ExplorerRef.passage(p.book, p.chapter)),
                  ],
                ),
              ),
            if (d.media.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.attachment_outlined,
                title: 'Media (${d.media.length})',
                child: Column(
                  children: [
                    for (final m in d.media) _AttachmentTile(attachment: m),
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
            if (d.notes.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.edit_note_outlined,
                title: 'Notes (${d.notes.length})',
                child: Column(
                  children: [for (final n in d.notes) _TaggedItemTile(item: n)],
                ),
              ),
            if (d.sermons.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.co_present_outlined,
                title: 'Sermons (${d.sermons.length})',
                child: Column(
                  children: [
                    for (final s in d.sermons) _TaggedItemTile(item: s),
                  ],
                ),
              ),
            if (d.notebooks.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.library_books_outlined,
                title: 'Notebooks (${d.notebooks.length})',
                child: Column(
                  children: [
                    for (final n in d.notebooks) _TaggedItemTile(item: n),
                  ],
                ),
              ),
            if (d.journals.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.edit_document,
                title: 'Journals (${d.journals.length})',
                child: Column(
                  children: [
                    for (final j in d.journals) _TaggedItemTile(item: j),
                  ],
                ),
              ),
            if (d.prayers.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.volunteer_activism_outlined,
                title: 'Prayers (${d.prayers.length})',
                child: Column(
                  children: [
                    for (final p in d.prayers) _TaggedItemTile(item: p),
                  ],
                ),
              ),
            if (d.related.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.label_outline,
                title: 'Related tags',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in d.related)
                      ExplorerTagChip(
                        t.tag,
                        subtitle:
                            '${t.itemCount} shared ${t.itemCount == 1 ? 'item' : 'items'}',
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

/// One item filed under a tag; tapping opens it in its home module (reader,
/// sermon editor, journal editor, or the Prayers tab).
class _TaggedItemTile extends ConsumerWidget {
  const _TaggedItemTile({required this.item});

  final SearchResult item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: item.textContent.trim().isEmpty
          ? null
          : Text(
              item.textContent,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => explorerOpenTaggedItem(context, ref, item),
    );
  }
}

/// Subtitle for a person/place chip on the tag page: how many of the tag's
/// verses mention that entity.
String _tagRefCountLabel(int count) =>
    '$count ${count == 1 ? 'verse' : 'verses'}';

/// A user-uploaded media attachment (image/PDF), shown on the tag and passage
/// pages. Tapping opens the same in-app image or PDF viewer the reader's Media
/// panel uses (only images/PDFs are attachable, so no external-handler fallback
/// is needed).
class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final MediaAttachment attachment;

  Future<File> _resolveFile() async {
    final dir = await appDataDir();
    return File(p.join(dir.path, 'media_attachments', attachment.filename));
  }

  Future<void> _open(BuildContext context) async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found locally. It may still be syncing.'),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final title = attachment.title ?? attachment.filename;
    if (attachment.mimeType.startsWith('image/')) {
      showDialog(
        context: context,
        builder: (_) => ImageViewerDialog(title: title, file: file),
      );
    } else if (attachment.mimeType == 'application/pdf') {
      showDialog(
        context: context,
        builder: (_) => PdfViewerDialog(title: title, file: file),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.mimeType.startsWith('image/');
    final sizeKb = (attachment.sizeBytes / 1024).toStringAsFixed(1);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(attachment.title ?? attachment.filename),
      subtitle: Text('$sizeKb KB'),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => _open(context),
    );
  }
}

/// The "Your tags" facet card on person/place/event pages: the tags you've
/// put on verses where the entity appears, most shared verses first. Chips
/// drill into the tag's page.
class _EntityTagsCard extends StatelessWidget {
  const _EntityTagsCard({required this.tags});

  final List<ExplorerEntityTag> tags;

  @override
  Widget build(BuildContext context) {
    return ExplorerFacetCard(
      icon: Icons.label_outline,
      title: 'Your tags',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final t in tags)
            ExplorerTagChip(
              t.tag,
              subtitle:
                  '${t.refs.length} ${t.refs.length == 1 ? 'verse' : 'verses'}',
            ),
        ],
      ),
    );
  }
}

/// A user note anchored in this chapter; tapping jumps the reader to the
/// note's verse.
class _PassageNoteTile extends ConsumerWidget {
  const _PassageNoteTile({
    required this.book,
    required this.chapter,
    required this.note,
  });

  final String book;
  final int chapter;
  final Note note;

  String get _label {
    final selected = note.selectedVerses;
    if (selected != null) {
      return selected.contains(',') ? 'Verses $selected' : 'Verse $selected';
    }
    if (note.verse != null) return 'Verse ${note.verse}';
    return 'Chapter note';
  }

  /// The verse the reader should land on: the explicit anchor, else the first
  /// of the selected verses, else the chapter top.
  int get _targetVerse {
    if (note.verse != null) return note.verse!;
    final first = note.selectedVerses?.split(',').first.trim();
    return int.tryParse(first ?? '') ?? 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        _label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        note.content,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () =>
          explorerOpenVerseInReader(context, ref, book, chapter, _targetVerse),
    );
  }
}
