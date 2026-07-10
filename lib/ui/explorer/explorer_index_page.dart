import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/explorer_providers.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../common/skeleton.dart';
import 'explorer_common.dart';

/// How an index page orders its entries. [rank] means "most mentioned"
/// (verse counts) for people and places, timeline order for events, and
/// calendar order for feasts; plain topics and stories have no meaningful
/// rank and only offer [alpha].
enum _IndexSort { alpha, rank }

/// A browsable listing of every entity of one kind — the page behind each of
/// the Explorer home's dataset chips, so the datasets can be explored without
/// already knowing a name to search for. Alphabetical mode adds a letter
/// strip that filters the list to one initial (3,000 people are more
/// browsable a letter at a time); rank mode lists the most-mentioned
/// entities first (timeline order for events, calendar order for feasts).
class ExplorerIndexPage extends ConsumerStatefulWidget {
  const ExplorerIndexPage({super.key, required this.kind, this.category});

  /// One of the id-addressed entity kinds (person/place/event/topic), per
  /// [ExplorerRef.browse]'s contract.
  final ExplorerEntityType kind;

  /// Curated topic category ('feast' or 'story') this index is restricted
  /// to; null for every kind but topics — see [ExplorerRef.browse].
  final String? category;

  @override
  ConsumerState<ExplorerIndexPage> createState() => _ExplorerIndexPageState();
}

class _ExplorerIndexPageState extends ConsumerState<ExplorerIndexPage> {
  /// Whether a category has its own curated, non-alphabetical order rather
  /// than plain A-Z (the feasts calendar, tribes' birth order, etc.).
  static const _naturallyOrderedCategories = {
    'feast',
    'tribe',
    'apostle',
    'judge',
    'prophet',
  };

  /// Whether the provider's given order is itself a meaningful browse order
  /// (the events timeline, the feasts calendar) rather than plain A-Z.
  bool get _natural =>
      widget.kind == ExplorerEntityType.event ||
      _naturallyOrderedCategories.contains(widget.category);

  // Naturally-ordered kinds default to that order; everything else to A-Z.
  late _IndexSort _sort = _natural ? _IndexSort.rank : _IndexSort.alpha;

  /// Initial letter the alphabetical view is filtered to; null shows all.
  String? _letter;

  String get _noun => switch (widget.category) {
        'feast' => 'feasts',
        'story' => 'stories',
        'tribe' => 'tribes',
        'apostle' => 'apostles',
        'judge' => 'judges',
        'prophet' => 'prophets',
        _ => switch (widget.kind) {
            ExplorerEntityType.person => 'people',
            ExplorerEntityType.place => 'places',
            ExplorerEntityType.event => 'events',
            ExplorerEntityType.prophecy => 'prophecies',
            _ => 'topics',
          },
      };

  /// Whether a second sort exists at all — plain topics and stories are
  /// alphabetical only.
  bool get _hasRankSort =>
      _natural ||
      widget.kind == ExplorerEntityType.person ||
      widget.kind == ExplorerEntityType.place;

  String get _rankLabel => switch (widget.category) {
        'feast' => 'Calendar',
        'tribe' || 'apostle' || 'judge' || 'prophet' => 'Traditional order',
        _ => switch (widget.kind) {
            ExplorerEntityType.event => 'Timeline',
            _ => 'Most verses',
          },
      };

  /// The first alphabetic character of [label] — story titles like
  /// `"I KNOW THAT MY REDEEMER LIVES"` start with punctuation, not a letter.
  static String _groupLetter(String label) {
    final m = RegExp('[A-Za-z]').firstMatch(label);
    return m == null ? '#' : label[m.start].toUpperCase();
  }

  /// A-Z comparison key that skips leading punctuation, so a quoted title
  /// sorts under its [_groupLetter] instead of ahead of every "A" entry on
  /// its opening quote (which is where the DB's plain ORDER BY puts it).
  static String _sortKey(String label) =>
      label.replaceFirst(RegExp('^[^A-Za-z0-9]+'), '').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(explorerIndexProvider(
        (kind: widget.kind, category: widget.category)));
    // Major/Minor/Other grouping — only the Prophets category has one today.
    final sections = widget.category == 'prophet'
        ? ref.watch(prophetSectionsProvider)
        : null;
    return entriesAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Couldn\'t load this index: $e'),
        ),
      ),
      data: (all) => _buildIndex(context, all, sections),
    );
  }

  Widget _buildIndex(
    BuildContext context,
    List<ExplorerIndexEntry> all,
    Map<String, String>? sections,
  ) {
    // A-Z always re-sorts with the punctuation-blind key (the provider's
    // SQL ordering puts quoted titles before "A"); rank keeps the given
    // order for naturally-ordered kinds (events, feasts).
    final List<ExplorerIndexEntry> entries;
    if (_sort == _IndexSort.alpha) {
      entries = [...all]..sort(
          (a, b) => _sortKey(a.ref.label).compareTo(_sortKey(b.ref.label)));
    } else {
      entries = _natural
          ? all
          : ([...all]..sort((a, b) {
              final w = b.weight.compareTo(a.weight);
              if (w != 0) return w;
              return _sortKey(a.ref.label).compareTo(_sortKey(b.ref.label));
            }));
    }

    final alpha = _sort == _IndexSort.alpha;
    final letters = <String>[];
    if (alpha) {
      for (final e in entries) {
        final l = _groupLetter(e.ref.label);
        if (letters.isEmpty || letters.last != l) letters.add(l);
      }
    }
    final visible = !alpha || _letter == null
        ? entries
        : [
            for (final e in entries)
              if (_groupLetter(e.ref.label) == _letter) e,
          ];

    // Flattened list rows: a String is a group header, anything else an
    // entry. In A-Z mode that's a letter header (skipped once filtered to
    // one letter); in rank mode, a category with its own [sections] lookup
    // (Prophets' Major/Minor/Other) gets the same treatment instead — the
    // list is already in that curated block order, so a header just marks
    // where the section value changes as we walk it.
    final rows = <Object>[];
    if (alpha && _letter == null) {
      String? current;
      for (final e in visible) {
        final l = _groupLetter(e.ref.label);
        if (l != current) {
          current = l;
          rows.add(l);
        }
        rows.add(e);
      }
    } else if (!alpha && sections != null) {
      String? current;
      for (final e in visible) {
        final s = sections[e.ref.label];
        if (s != current) {
          current = s;
          if (s != null) rows.add(s);
        }
        rows.add(e);
      }
    } else {
      rows.addAll(visible);
    }

    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${all.length} $_noun',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  if (_hasRankSort)
                    SegmentedButton<_IndexSort>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: [
                        const ButtonSegment(
                          value: _IndexSort.alpha,
                          label: Text('A–Z'),
                        ),
                        ButtonSegment(
                          value: _IndexSort.rank,
                          label: Text(_rankLabel),
                        ),
                      ],
                      selected: {_sort},
                      onSelectionChanged: (s) =>
                          setState(() => _sort = s.first),
                    ),
                ],
              ),
            ),
            if (alpha && letters.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    for (final letter in letters)
                      _LetterButton(
                        letter,
                        selected: _letter == letter,
                        onTap: () => setState(
                            () => _letter = _letter == letter ? null : letter),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final row = rows[i];
                  if (row is String) return _GroupHeader(row);
                  final entry = row as ExplorerIndexEntry;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      explorerBrowseIcon(widget.kind, widget.category),
                      size: 20,
                      color: scheme.primary,
                    ),
                    title: Text(entry.ref.label),
                    subtitle: entry.subtitle == null
                        ? null
                        : Text(
                            entry.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => ref
                        .read(explorerTrailProvider.notifier)
                        .open(entry.ref),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tap target in the letter strip; the selected letter is filled so the
/// active filter is visible at a glance.
class _LetterButton extends StatelessWidget {
  const _LetterButton(
    this.letter, {
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: kMinInteractiveDimension,
        height: kMinInteractiveDimension,
        decoration: selected
            ? BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Center(
          child: Text(
            letter,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      selected ? scheme.onPrimaryContainer : scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

/// A group header row — a letter in A-Z mode, a Major/Minor/Other section
/// label in rank mode for categories that have one. Just a styled `Text`;
/// nothing here is letter-specific.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
