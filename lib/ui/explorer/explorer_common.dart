import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/explorer_providers.dart';
import '../../app/reader_state.dart';
import '../../app/search_providers.dart';
import '../../app/sermon_providers.dart';
import '../../app/notebook_providers.dart';
import '../../app/tag_providers.dart';
import '../../app/user_providers.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../common/breakpoints.dart';
import '../common/place_marker_map.dart';
import '../journals/journal_editor_panel.dart';
import '../journals/journals_list_panel.dart';
import '../reader/atlas_screen.dart';
import '../sermons/sermon_editor_screen.dart';
import '../notebooks/notebook_page_editor_screen.dart';
import '../tags/tag_palette.dart';

/// Formats an ISO year for display: negative years are BC.
String explorerYearLabel(int year) => year < 0 ? '${-year} BC' : 'AD $year';

IconData explorerEntityIcon(ExplorerEntityType type) => switch (type) {
      ExplorerEntityType.person => Icons.person_outline,
      ExplorerEntityType.place => Icons.place_outlined,
      ExplorerEntityType.event => Icons.flag_outlined,
      ExplorerEntityType.topic => Icons.topic_outlined,
      ExplorerEntityType.passage => Icons.menu_book_outlined,
      ExplorerEntityType.tag => Icons.label_outline,
      ExplorerEntityType.browse => Icons.list_alt_outlined,
      ExplorerEntityType.prophecy => Icons.auto_awesome_outlined,
    };

/// Icon for a browse index: curated topic categories get their own icons;
/// every other kind borrows its entity icon.
IconData explorerBrowseIcon(ExplorerEntityType kind, String? category) =>
    switch (category) {
      'feast' => Icons.celebration_outlined,
      'story' => Icons.auto_stories_outlined,
      'tribe' => Icons.groups_outlined,
      'apostle' => Icons.diversity_3_outlined,
      'judge' => Icons.gavel_outlined,
      'prophet' => Icons.record_voice_over_outlined,
      _ => explorerEntityIcon(kind),
    };

/// Like [explorerEntityIcon], but a browse ref borrows the icon of what it
/// lists — a "People" crumb should look like a person, not a list.
IconData explorerRefIcon(ExplorerRef ref) => ref.browseKind == null
    ? explorerEntityIcon(ref.type)
    : explorerBrowseIcon(ref.browseKind!, ref.browseCategory);

/// Jump the reader to a verse and unwind back to the shell so it's visible.
void explorerOpenVerseInReader(
  BuildContext context,
  WidgetRef ref,
  String book,
  int chapter,
  int verse,
) {
  // The Explorer can be opened from any module (e.g. the dashboard); the
  // shell must be showing the reader once the route unwinds.
  ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
  ref.read(selectedBookNameProvider.notifier).set(book);
  ref.read(selectedChapterProvider.notifier).set(chapter);
  ref.read(targetVerseToScrollProvider.notifier).set(verse);
  ref.read(selectedVersesProvider.notifier).clear();
  ref.read(selectedVersesProvider.notifier).toggle(verse);
  ref.read(navigationControllerProvider).recordHistory(verse: verse);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Opens a tagged item from the tag page in its home module: verses and notes
/// jump the reader, sermons open the sermon editor, journals the journal
/// editor, prayers the Prayers tab. Like [explorerOpenVerseInReader], the
/// Explorer route is unwound so the destination is visible.
void explorerOpenTaggedItem(
  BuildContext context,
  WidgetRef ref,
  SearchResult item,
) {
  final nav = Navigator.of(context);
  final isPhone = MediaQuery.sizeOf(context).width <= Breakpoints.compact;
  switch (item.type) {
    case 'verse':
    case 'note':
      if (item.book == null || item.chapter == null) return;
      final firstSelected = item.selectedVerses?.split(',').first.trim();
      final verse = item.verse ?? int.tryParse(firstSelected ?? '') ?? 1;
      explorerOpenVerseInReader(context, ref, item.book!, item.chapter!, verse);
    case 'sermon':
      if (isPhone) {
        nav.popUntil((route) => route.isFirst);
        nav.push(MaterialPageRoute(
          builder: (_) => SermonEditorScreen(
              sermonId: item.referenceId, isFullScreen: true),
        ));
      } else {
        ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
        ref.read(selectedSermonIdProvider.notifier).set(item.referenceId);
        ref.read(activeToolProvider.notifier).openTool(ActiveTool.sermons);
        nav.popUntil((route) => route.isFirst);
      }
    case 'journal':
      ref.read(selectedJournalIdProvider.notifier).setId(item.referenceId);
      final store = ref.read(userStoreProvider);
      final dateNotifier = ref.read(selectedJournalDateProvider.notifier);
      (store.select(store.journals)
            ..where((j) => j.id.equals(item.referenceId)))
          .getSingleOrNull()
          .then((journal) {
        if (journal != null) {
          dateNotifier.setDate(
              DateTime.fromMillisecondsSinceEpoch(journal.updatedAt).toLocal());
        }
      });
      ref.read(journalsActiveTabProvider.notifier).setTab(
          JournalsActiveTab.journals);
      ref.read(appModuleProvider.notifier).setModule(AppModule.journalsPrayers);
      nav.popUntil((route) => route.isFirst);
      if (isPhone) {
        nav.push(MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Journal Editor')),
            body: const JournalEditorPanel(),
          ),
        ));
      }
    case 'prayer':
      ref.read(journalsActiveTabProvider.notifier).setTab(
          JournalsActiveTab.prayers);
      ref.read(appModuleProvider.notifier).setModule(AppModule.journalsPrayers);
      nav.popUntil((route) => route.isFirst);
    case 'notebookPage':
      if (isPhone) {
        nav.popUntil((route) => route.isFirst);
        nav.push(MaterialPageRoute(
          builder: (_) => NotebookPageEditorScreen(
              pageId: item.referenceId, isFullScreen: true),
        ));
      } else {
        ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
        ref.read(selectedNotebookPageIdProvider.notifier).set(item.referenceId);
        ref.read(activeToolProvider.notifier).openTool(ActiveTool.notebooks);
        nav.popUntil((route) => route.isFirst);
      }
    case 'notebook':
      ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
      ref.read(selectedNotebookPageIdProvider.notifier).set(null);
      ref.read(selectedNotebookIdProvider.notifier).set(item.referenceId);
      ref.read(activeToolProvider.notifier).openTool(ActiveTool.notebooks);
      nav.popUntil((route) => route.isFirst);
  }
}

/// One facet of an entity page: a card with an icon-and-title header and the
/// facet's content below.
class ExplorerFacetCard extends StatelessWidget {
  const ExplorerFacetCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Like [ExplorerFacetCard], but the whole card collapses behind its header
/// instead of always showing its content — for facets (e.g. cross-references)
/// that can otherwise dominate the page.
class ExplorerCollapsibleFacetCard extends StatelessWidget {
  const ExplorerCollapsibleFacetCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(icon, size: 18, color: scheme.primary),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }
}

/// A chip that drills into another Explorer entity.
class ExplorerRefChip extends ConsumerWidget {
  const ExplorerRefChip(this.target, {super.key, this.subtitle});

  final ExplorerRef target;

  /// Optional qualifier rendered after the label, de-emphasized.
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(
        explorerRefIcon(target),
        size: 16,
        color: scheme.primary,
      ),
      label: subtitle == null
          ? Text(target.label)
          : Text.rich(
              TextSpan(
                text: target.label,
                children: [
                  TextSpan(
                    text: '  $subtitle',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
      onPressed: () => ref.read(explorerTrailProvider.notifier).open(target),
    );
  }
}

/// A chip that drills into a tag's Explorer page, tinted with the tag's
/// colour like tag chips elsewhere in the app.
class ExplorerTagChip extends ConsumerWidget {
  const ExplorerTagChip(this.tag, {super.key, this.subtitle});

  final TagData tag;

  /// Optional qualifier rendered after the name, de-emphasized.
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = tagChipStyle(context, tag.colorHex);
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: style.background,
      side: BorderSide(color: style.border),
      label: subtitle == null
          ? Text('#${tag.name}',
              style: TextStyle(color: style.foreground))
          : Text.rich(
              TextSpan(
                text: '#${tag.name}',
                style: TextStyle(color: style.foreground),
                children: [
                  TextSpan(
                    text: '  $subtitle',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
      onPressed: () => ref
          .read(explorerTrailProvider.notifier)
          .open(ExplorerRef.tag(tag.id, '#${tag.name}')),
    );
  }
}

/// A chip that previews a verse in a bottom sheet, so an entity's mentions
/// can be skimmed without leaving the Explorer; the sheet's "Open in reader"
/// keeps the old jump one tap away.
class ExplorerVerseChip extends ConsumerWidget {
  const ExplorerVerseChip({
    super.key,
    required this.book,
    required this.chapter,
    required this.verse,
    this.verseEnd,
    this.label,
  });

  final String book;
  final int chapter;
  final int verse;

  /// Last verse of an inclusive range starting at [verse]; null for a single
  /// verse. Only widens the preview — opening in the reader still lands on
  /// [verse].
  final int? verseEnd;

  /// Chip text; defaults to the full "Book chapter:verse" reference.
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(label ?? '$book $chapter:$verse'),
      // No label forwarded: chip labels can be shorthand ("24:2"); the sheet
      // titles itself with the canonical full reference instead.
      onPressed: () => showExplorerVersePreview(
        context,
        book: book,
        chapter: chapter,
        verse: verse,
        verseEnd: verseEnd,
      ),
    );
  }
}

/// Bottom-sheet preview of a verse (or an inclusive range within a chapter)
/// in the primary version — see [ExplorerVerseChip]. [label] overrides the
/// default full-reference title.
Future<void> showExplorerVersePreview(
  BuildContext context, {
  required String book,
  required int chapter,
  required int verse,
  int? verseEnd,
  String? label,
}) {
  final end = verseEnd == null || verseEnd <= verse ? verse : verseEnd;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => _ExplorerVersePreviewSheet(
      book: book,
      chapter: chapter,
      verse: verse,
      verseEnd: end,
      label:
          label ??
          (end == verse
              ? '$book $chapter:$verse'
              : '$book $chapter:$verse–$end'),
    ),
  );
}

class _ExplorerVersePreviewSheet extends ConsumerWidget {
  const _ExplorerVersePreviewSheet({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.verseEnd,
    required this.label,
  });

  final String book;
  final int chapter;
  final int verse;
  final int verseEnd;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final previewAsync = ref.watch(
      explorerVersePreviewProvider((
        book: book,
        chapter: chapter,
        verse: verse,
        verseEnd: verseEnd,
      )),
    );
    final preview = previewAsync.asData?.value;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (preview != null)
                  Text(
                    preview.versionAbbreviation,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: previewAsync.isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : preview == null
                        ? Text(
                            'This passage isn\'t available in your primary '
                            'Bible.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          )
                        : Text.rich(
                            TextSpan(
                              children: [
                                for (final v in preview.verses) ...[
                                  TextSpan(
                                    text: '${v.verse} ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  TextSpan(text: '${v.text} '),
                                ],
                              ],
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.6),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.menu_book, size: 18),
                label: const Text('Open in reader'),
                // Unwinds to the shell, which also dismisses this sheet.
                onPressed: () =>
                    explorerOpenVerseInReader(context, ref, book, chapter, verse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Verse references grouped one-expansion-tile-per-book, so entities with
/// hundreds of mentions stay scannable. [refs] must be in canonical order.
class ExplorerVerseGroups extends StatelessWidget {
  const ExplorerVerseGroups({super.key, required this.refs});

  final List<({String book, int chapter, int verse})> refs;

  @override
  Widget build(BuildContext context) {
    final byBook = <String, List<({String book, int chapter, int verse})>>{};
    for (final r in refs) {
      byBook.putIfAbsent(r.book, () => []).add(r);
    }
    return Column(
      children: [
        for (final entry in byBook.entries)
          ExpansionTile(
            dense: true,
            tilePadding: EdgeInsets.zero,
            title: Text('${entry.key} (${entry.value.length})'),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in entry.value)
                        ExplorerVerseChip(
                          book: r.book,
                          chapter: r.chapter,
                          verse: r.verse,
                          label: '${r.chapter}:${r.verse}',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// A marker the Explorer map can plot; tapping drills into the place.
class ExplorerMapPlace {
  final int id;
  final String name;
  final double lat;
  final double lng;
  const ExplorerMapPlace(this.id, this.name, this.lat, this.lng);
}

/// Small embedded map for place/event/person pages, offline-tolerant like the
/// Places panel: markers render even when the tile background can't load.
/// Expandable to the fullscreen Atlas — by default seeded with these same
/// points, or with [journeyPersonId]'s animated journey when set (used by the
/// person page, where "expand" means "show their journey", not just these
/// points).
class ExplorerMap extends ConsumerWidget {
  const ExplorerMap({super.key, required this.places, this.journeyPersonId});

  final List<ExplorerMapPlace> places;

  /// When set, expanding this map opens the Atlas directly in journey mode
  /// for this person, instead of the generic points-seeded browse view.
  final int? journeyPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (places.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PlaceMarkerMap(
          key: ValueKey(places.map((p) => p.id).join(',')),
          points: [for (final p in places) MapPoint(p.id, p.name, p.lat, p.lng)],
          initialZoom: 7,
          onTapPoint: (mp) => ref
              .read(explorerTrailProvider.notifier)
              .open(ExplorerRef.place(mp.id, mp.name)),
          onExpand: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => journeyPersonId != null
                  ? AtlasScreen(initialPersonId: journeyPersonId)
                  : AtlasScreen(
                      initialPoints: [
                        for (final p in places)
                          MapPoint(p.id, p.name, p.lat, p.lng),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
