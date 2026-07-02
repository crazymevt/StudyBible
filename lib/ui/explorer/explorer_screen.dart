import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/explorer_providers.dart';
import '../../app/reader_state.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../common/skeleton.dart';
import 'explorer_common.dart';
import 'explorer_pages.dart';

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
      body: ready.when(
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
                      // Key on the entry so drilling into a new entity starts
                      // its page at the top instead of reusing scroll state.
                      key: ValueKey(trail.last),
                      entry: trail.last,
                    ),
            ),
          ],
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
                                explorerEntityIcon(trail[i].type),
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
                      'Search people, places, events, topics, or a passage '
                      '(e.g. David, En Gedi, John 1)…',
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
        const SizedBox(height: 20),
        Text(
          'One search across the whole study library. Open anything, then '
          'follow the connections — a person to their events, an event to '
          'where it happened, a place to everyone mentioned there, and any '
          'verse straight into the reader.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        if (stats != null) ...[
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(Icons.person_outline, '${stats.people} people'),
              _StatChip(Icons.place_outlined, '${stats.places} places'),
              _StatChip(Icons.flag_outlined, '${stats.events} events'),
              _StatChip(Icons.topic_outlined, '${stats.topics} topics'),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: scheme.primary),
      label: Text(label),
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
          return Center(
            child: Text(
              'No matches. Try a name ("Moses"), a place ("Jericho"), '
              'or a reference ("Acts 9").',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
