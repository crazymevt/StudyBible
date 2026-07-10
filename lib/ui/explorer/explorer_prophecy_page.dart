part of 'explorer_pages.dart';

/// A single prophecy from the pure-Dart `prophecies` dataset: the Old
/// Testament foretelling and its New Testament fulfillment, each with tappable
/// passages that open in the reader. No async — the data is a const list.
class _ProphecyPage extends StatelessWidget {
  const _ProphecyPage({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= prophecies.length) {
      return const _ErrorBody('Prophecy not found.');
    }
    final prophecy = prophecies[index];
    final otFulfillment = prophecy.category == ProphecyCategory.oldTestament;
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
