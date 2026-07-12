part of 'explorer_pages.dart';

/// A single prophecy from the pure-Dart `prophecies` dataset: the Old
/// Testament foretelling and its New Testament fulfillment, each with tappable
/// passages that open in the reader. The prophecy/fulfillment text itself is
/// no async — the data is a const list — but the user-content facets
/// (sermons/notebooks referencing this prophecy via an `sbent:` link) are.
class _ProphecyPage extends ConsumerWidget {
  const _ProphecyPage({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (index < 0 || index >= prophecies.length) {
      return const _ErrorBody('Prophecy not found.');
    }
    final prophecy = prophecies[index];
    final otFulfillment = prophecy.category == ProphecyCategory.oldTestament;
    final entityRef = ExplorerRef.prophecy(index, prophecy.title);
    final sermons =
        ref.watch(explorerSermonsProvider(entityRef)).asData?.value ??
        const <SearchResult>[];
    final notebookPages =
        ref.watch(explorerNotebookPagesProvider(entityRef)).asData?.value ??
        const <SearchResult>[];
    return _PageScroll(
      children: [
        _PageTitle(title: prophecy.title, subtitle: prophecy.category.label),
        ExplorerFacetCard(
          icon: Icons.auto_stories_outlined,
          title: 'The Prophecy',
          child: _ProphecySection(
            text: prophecy.prophecyText,
            passages: prophecy.prophecy,
          ),
        ),
        ExplorerFacetCard(
          icon: Icons.check_circle_outline,
          title: otFulfillment ? 'Fulfilled' : 'The Fulfillment',
          child: _ProphecySection(
            text: prophecy.fulfillmentText,
            passages: prophecy.fulfillment,
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
      ],
    );
  }
}

/// A prophecy facet's prose plus its passage chips. Chip parsing mirrors the
/// Prophecies panel: "Book C", "Book C:V", or "Book C:V-V"; a range opens at
/// its first verse but keeps the full reference as its label.
class _ProphecySection extends StatelessWidget {
  const _ProphecySection({required this.text, required this.passages});

  final String text;
  final List<String> passages;

  static final _exp = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        if (passages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final passage in passages)
                  if (_exp.firstMatch(passage.trim()) case final m?)
                    ExplorerVerseChip(
                      book: m.group(1)!.trim(),
                      chapter: int.parse(m.group(2)!),
                      verse: int.tryParse(m.group(3) ?? '') ?? 1,
                      verseEnd: int.tryParse(m.group(4) ?? ''),
                      label: passage,
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Short qualifier for a prophecy chip on a chapter page: whether this chapter
/// carries the foretelling, the fulfillment, or both, plus the verses cited.
String _prophecyRoleLabel(ProphecyChapterHit h) {
  final role = h.foretold && h.fulfilled
      ? 'foretold & fulfilled'
      : h.foretold
      ? 'foretold'
      : 'fulfilled';
  final vs = h.verses.length == 1
      ? 'v. ${h.verses.first}'
      : 'vv. ${h.verses.join(', ')}';
  return '$role · $vs';
}

/// Scroll frame shared by all entity pages: centered, width-capped card list.
