import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/explorer_providers.dart';
import '../../app/reader_state.dart';
import '../../app/topic_providers.dart';
import '../../data/content_store.dart' show Topic;
import '../../domain/explorer/explorer_ref.dart';
import '../../domain/feasts/feast_data.dart' show feasts;
import '../common/skeleton.dart';
import '../tags/tag_palette.dart';
import 'explorer_common.dart';
import 'explorer_pages.dart';

/// Opens [target] in a fresh, full-page [ExplorerScreen] pushed on top of
/// whatever's currently showing — e.g. from a family tree node, or an
/// `sbent:` entity link in a notebook page (see
/// `entity_autolink.dart`'s `handleEntityLinkLaunch`).
///
/// The exploration trail is one global, session-wide stack (see
/// [explorerTrailProvider]'s doc comment), not one per pushed
/// [ExplorerScreen]. If an [ExplorerScreen] is already open somewhere below
/// in the navigation stack (its person page is what led here, directly or
/// indirectly) and this just cleared and reused that same shared trail, the
/// earlier instance would come back showing this new destination instead of
/// whatever it had before once the user backs out of this one. So: save the
/// trail as it stood, hijack it for the new screen, then restore it the
/// moment that screen is popped.
Future<void> openInFreshExplorer(
  BuildContext context,
  WidgetRef ref,
  ExplorerRef target,
) async {
  final notifier = ref.read(explorerTrailProvider.notifier);
  final previousTrail = ref.read(explorerTrailProvider);
  notifier
    ..clear()
    ..open(target);
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ExplorerScreen()),
  );
  notifier.restore(previousTrail);
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
    // Re-sort into the Leviticus 23 calendar order (`feasts`, the domain
    // list) rather than the DB query's alphabetical order — "Day of
    // Atonement" first reads as nonsense next to the actual liturgical
    // sequence.
    final feastOrder = [for (final f in feasts) f.name.toUpperCase()];
    final feastTopics =
        ref.watch(curatedTopicsByCategoryProvider('feast')).asData?.value ??
            const <Topic>[];
    final sortedFeasts = [...feastTopics]
      ..sort((a, b) =>
          feastOrder.indexOf(a.name).compareTo(feastOrder.indexOf(b.name)));
    final stories =
        ref.watch(curatedTopicsByCategoryProvider('story')).asData?.value ??
            const <Topic>[];

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
        if (sortedFeasts.isNotEmpty) ...[
          const SizedBox(height: 20),
          _CuratedTopicsSection(title: 'Feasts', topics: sortedFeasts),
        ],
        if (stories.isNotEmpty) ...[
          const SizedBox(height: 20),
          _CuratedTopicsSection(title: 'Bible Stories', topics: stories),
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

/// A row of curated topics (feasts or well-known stories) on the Explorer
/// home page, for browsing without already knowing what to search for.
/// Lists long enough that an alphabetical scroll gets unwieldy (the hundreds
/// of curated stories, not the handful of feasts) are broken into per-letter
/// groups with a tappable A-Z jump strip above them, instead of one flat wrap.
class _CuratedTopicsSection extends StatefulWidget {
  const _CuratedTopicsSection({required this.title, required this.topics});

  static const _groupThreshold = 20;

  final String title;
  final List<Topic> topics;

  /// The first alphabetic character of [name], for grouping — titles like
  /// `"I KNOW THAT MY REDEEMER LIVES"` start with punctuation, not a letter.
  static String _groupLetter(String name) {
    final m = RegExp('[A-Za-z]').firstMatch(name);
    return m == null ? '#' : name[m.start].toUpperCase();
  }

  @override
  State<_CuratedTopicsSection> createState() => _CuratedTopicsSectionState();
}

class _CuratedTopicsSectionState extends State<_CuratedTopicsSection> {
  // One GlobalKey per letter header, kept stable across rebuilds so the jump
  // strip can scroll to it — created lazily since which letters appear is
  // fixed for the life of this widget (the topic list doesn't change).
  final _letterKeys = <String, GlobalKey>{};

  void _jumpTo(String letter) {
    final ctx = _letterKeys[letter]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 8),
        if (widget.topics.length > _CuratedTopicsSection._groupThreshold)
          _buildGrouped(context)
        else
          _buildWrap(widget.topics),
      ],
    );
  }

  Widget _buildGrouped(BuildContext context) {
    final byLetter = <String, List<Topic>>{};
    for (final t in widget.topics) {
      byLetter
          .putIfAbsent(_CuratedTopicsSection._groupLetter(t.name), () => [])
          .add(t);
    }
    final letters = byLetter.keys.toList()..sort();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 2,
          runSpacing: 2,
          children: [
            for (final letter in letters)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _jumpTo(letter),
                child: SizedBox(
                  width: kMinInteractiveDimension,
                  height: kMinInteractiveDimension,
                  child: Center(
                    child: Text(
                      letter,
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (final letter in letters) ...[
          Padding(
            key: _letterKeys.putIfAbsent(letter, () => GlobalKey()),
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              letter,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          _buildWrap(byLetter[letter]!),
        ],
      ],
    );
  }

  Widget _buildWrap(List<Topic> topics) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final t in topics) ExplorerRefChip(ExplorerRef.topic(t.id, t.name)),
        ],
      );
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
