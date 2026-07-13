import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/explorer_providers.dart';
import '../../app/reader_state.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../common/skeleton.dart';
import '../tags/tag_palette.dart';
import 'explorer_common.dart';
import 'explorer_pages.dart';

/// Opens [target] in a full-page [ExplorerScreen] pushed on top of whatever's
/// currently showing — e.g. from a family tree node, an "Open in Explorer"
/// button on a Reader panel, or an `sbent:` entity link in a notebook page
/// (see `entity_autolink.dart`'s `handleEntityLinkLaunch`).
///
/// The exploration trail is one global, session-wide stack (see
/// [explorerTrailProvider]'s doc comment), not one per pushed
/// [ExplorerScreen], so this behaves differently depending on whether an
/// [ExplorerScreen] is already open somewhere below in the navigation stack
/// ([insideExplorerProvider]):
///
/// - Nested (already inside an Explorer — e.g. a family tree node opened
///   from a person's Explorer page): reusing the shared trail as-is would
///   make the earlier instance come back showing this new destination
///   instead of whatever it had before. So the trail is saved, hijacked for
///   the new screen, then restored the moment that screen is popped.
/// - Fresh (opened from the Reader or a side panel, with no Explorer open
///   yet): there's nothing to protect, so [target] just extends the
///   persistent trail and is left in place when the screen is popped —
///   backing out, or reopening Explorer later from anywhere, resumes here.
Future<void> openInFreshExplorer(
  BuildContext context,
  WidgetRef ref,
  ExplorerRef target,
) async {
  final trailNotifier = ref.read(explorerTrailProvider.notifier);
  final insideNotifier = ref.read(insideExplorerProvider.notifier);
  final wasNested = ref.read(insideExplorerProvider);
  final previousTrail = wasNested ? ref.read(explorerTrailProvider) : null;

  if (wasNested) {
    trailNotifier
      ..clear()
      ..open(target);
  } else {
    trailNotifier.open(target);
  }

  insideNotifier.set(true);
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ExplorerScreen()),
  );
  insideNotifier.set(wasNested);
  if (wasNested && previousTrail != null) {
    trailNotifier.restore(previousTrail);
  }
}

/// Opens the Explorer with no particular destination — home, or wherever the
/// persistent trail left off. This is the top-level entry point used by the
/// app drawer and the reader toolbar. Tracks [insideExplorerProvider] just
/// like [openInFreshExplorer], so entity detours launched from inside this
/// screen (e.g. a family tree node) know an Explorer is already showing and
/// protect its trail.
Future<void> openExplorer(BuildContext context, WidgetRef ref) async {
  final insideNotifier = ref.read(insideExplorerProvider.notifier);
  final wasInside = ref.read(insideExplorerProvider);
  insideNotifier.set(true);
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ExplorerScreen()),
  );
  insideNotifier.set(wasInside);
}

/// Full-page knowledge-web browser over the bundled study datasets: every
/// person, place, event, topic, and passage is a page, and the pages
/// cross-link so one search can be explored in any direction. Navigation
/// within the Explorer is a breadcrumb trail (session-global, so reopening
/// resumes where the user left off); the app bar back closes the whole screen.
class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trail = ref.watch(explorerTrailProvider);
    final ready = ref.watch(explorerReadyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
          if (trail.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'New search',
              onPressed: () =>
                  ref.read(explorerTrailProvider.notifier).clear(),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ready.when(
          loading: () => const SkeletonList(),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Couldn\'t load the study datasets: $e'),
            ),
          ),
          data: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trail.isNotEmpty) const _BreadcrumbBar(),
              Expanded(
                child: trail.isEmpty
                    ? const _ExplorerHome()
                    : ExplorerEntityPage(
                        // Key on the entry so drilling into a new entity
                        // starts its page at the top instead of reusing
                        // scroll state.
                        key: ValueKey(trail.last),
                        entry: trail.last,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trail: Home, then one crumb per visited entity. Tapping a crumb cuts
/// the trail back to it.
class _BreadcrumbBar extends ConsumerWidget {
  const _BreadcrumbBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trail = ref.watch(explorerTrailProvider);
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return Material(
      color: scheme.surfaceContainer,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              tooltip: 'Back one step',
              onPressed: () =>
                  ref.read(explorerTrailProvider.notifier).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () =>
                          ref.read(explorerTrailProvider.notifier).clear(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        child: Icon(Icons.home_outlined,
                            size: 18, color: scheme.primary),
                      ),
                    ),
                    for (var i = 0; i < trail.length; i++) ...[
                      Icon(Icons.chevron_right,
                          size: 16, color: scheme.onSurfaceVariant),
                      if (i < trail.length - 1)
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => ref
                              .read(explorerTrailProvider.notifier)
                              .truncateTo(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                            child: Text(
                              trail[i].label,
                              style: labelStyle?.copyWith(
                                  color: scheme.primary),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                explorerRefIcon(trail[i]),
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trail[i].label,
                                style: labelStyle?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home: universal search over every entity kind, with the current chapter as
/// a ready-made starting point.
class _ExplorerHome extends ConsumerStatefulWidget {
  const _ExplorerHome();

  @override
  ConsumerState<_ExplorerHome> createState() => _ExplorerHomeState();
}

class _ExplorerHomeState extends ConsumerState<_ExplorerHome> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(explorerSearchQueryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(explorerSearchQueryProvider).trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText:
                      'Search people, places, events, topics, your tags, or '
                      'a passage (e.g. David, En Gedi, #faith, John 1)…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                          onPressed: () {
                            _controller.clear();
                            ref
                                .read(explorerSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => ref
                    .read(explorerSearchQueryProvider.notifier)
                    .setQuery(v),
              ),
            ),
            Expanded(
              child: query.length < 2
                  ? const _HomeIntro()
                  : const _SearchResultsList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeIntro extends ConsumerWidget {
  const _HomeIntro();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final book = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final stats = ref.watch(explorerStatsProvider).asData?.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.menu_book_outlined, color: scheme.primary),
            title: Text('Explore $book $chapter'),
            subtitle: const Text(
                'Everything the datasets know about the chapter you\'re reading'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref
                .read(explorerTrailProvider.notifier)
                .open(ExplorerRef.passage(book, chapter)),
          ),
        ),
        if (stats != null) ...[
          const SizedBox(height: 24),
          Text(
            'BROWSE THE LIBRARY',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.person, 'People'),
                '${stats.people} people',
              ),
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.place, 'Places'),
                '${stats.places} places',
              ),
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.event, 'Events'),
                '${stats.events} events',
              ),
              _StatChip(
                const ExplorerRef.browse(
                    ExplorerEntityType.topic, 'Bible Stories',
                    category: 'story'),
                '${stats.stories} stories',
              ),
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.topic, 'Feasts',
                    category: 'feast'),
                '${stats.feasts} feasts',
              ),
              _StatChip(
                const ExplorerRef.browse(
                    ExplorerEntityType.prophecy, 'Prophecies'),
                '${stats.prophecies} prophecies',
              ),
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.thread, 'Threads'),
                '${stats.threads} threads',
              ),
              _StatChip(
                const ExplorerRef.browse(
                    ExplorerEntityType.topic, 'Tribes of Israel',
                    category: 'tribe'),
                '${stats.tribes} tribes',
              ),
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.topic, 'Apostles',
                    category: 'apostle'),
                '${stats.apostles} apostles',
              ),
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.topic, 'Judges',
                    category: 'judge'),
                '${stats.judges} judges',
              ),
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.topic, 'Prophets',
                    category: 'prophet'),
                '${stats.prophets} prophets',
              ),
              _StatChip(
                const ExplorerRef.browse(ExplorerEntityType.topic, 'Topics'),
                '${stats.topics} topics',
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'One search across the whole study library. Open anything, then '
          'follow the connections — a person to their events, an event to '
          'where it happened, a place to everyone mentioned there, and any '
          'verse straight into the reader. Your own tags are part of the web '
          'too: search a tag to see everything you\'ve filed under it.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// One dataset's size on the home page; tapping opens a browsable index of
/// that whole dataset ([ExplorerIndexPage] via the trail). Reads as a button
/// — leading dataset icon, trailing chevron — so the count is visibly a door
/// into the index, not just a statistic.
class _StatChip extends ConsumerWidget {
  const _StatChip(this.target, this.label);

  /// The browse destination; its label doubles as the breadcrumb crumb
  /// ("People", "Feasts", …).
  final ExplorerRef target;

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(explorerRefIcon(target), size: 16, color: scheme.primary),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right, size: 14, color: scheme.onSurfaceVariant),
        ],
      ),
      tooltip: 'Browse all ${target.label.toLowerCase()}',
      onPressed: () =>
          ref.read(explorerTrailProvider.notifier).open(target),
    );
  }
}

class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(explorerSearchResultsProvider);
    return resultsAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(child: Text('Search failed: $e')),
      data: (r) {
        if (r.isEmpty) {
          final hint = Text(
            r.suggestions.isEmpty
                ? 'No matches. Try a name ("Moses"), a place ("Jericho"), '
                    'or a reference ("Acts 9").'
                : 'No exact matches. Did you mean:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          );
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  hint,
                  if (r.suggestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in r.suggestions)
                          ExplorerRefChip(s.ref),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        final sections = <Widget>[];
        void section(String title, List<ExplorerSearchItem> items) {
          if (items.isEmpty) return;
          sections
            ..add(_ResultsHeader(title))
            ..addAll([for (final item in items) _ResultTile(item)]);
        }

        if (r.passage != null) {
          sections
            ..add(const _ResultsHeader('Passage'))
            ..add(_ResultTile(ExplorerSearchItem(r.passage!)));
        }
        section('People', r.people);
        section('Places', r.places);
        section('Events', r.events);
        section('Topics', r.topics);
        section('Prophecies', r.prophecies);
        section('Threads', r.threads);
        if (r.tags.isNotEmpty) {
          sections
            ..add(const _ResultsHeader('Your Tags'))
            ..addAll([for (final t in r.tags) _TagResultTile(t)]);
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: sections,
        );
      },
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

/// A tag search hit: the leading icon takes the tag's colour so results scan
/// the same way tag chips do elsewhere in the app.
class _TagResultTile extends ConsumerWidget {
  const _TagResultTile(this.hit);

  final ExplorerTagHit hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.label,
        size: 20,
        color: tagColorFromHex(hit.tag.colorHex) ??
            Theme.of(context).colorScheme.primary,
      ),
      title: Text('#${hit.tag.name}'),
      subtitle:
          Text('${hit.itemCount} ${hit.itemCount == 1 ? 'item' : 'items'}'),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => ref
          .read(explorerTrailProvider.notifier)
          .open(ExplorerRef.tag(hit.tag.id, '#${hit.tag.name}')),
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile(this.item);

  final ExplorerSearchItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: Icon(
        explorerEntityIcon(item.ref.type),
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(item.ref.label),
      subtitle: item.subtitle == null
          ? null
          : Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => ref.read(explorerTrailProvider.notifier).open(item.ref),
    );
  }
}
