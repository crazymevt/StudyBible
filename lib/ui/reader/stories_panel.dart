import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/topic_providers.dart';
import '../../data/content_store.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../common/breakpoints.dart';
import '../common/skeleton.dart';
import '../explorer/explorer_screen.dart';

/// Bible Stories: a searchable list of the hand-curated story topics (see
/// curated_topics_data.dart), each with a summary and its passage(s).
class StoriesPanel extends ConsumerStatefulWidget {
  const StoriesPanel({super.key});

  @override
  ConsumerState<StoriesPanel> createState() => _StoriesPanelState();
}

class _StoriesPanelState extends ConsumerState<StoriesPanel> {
  final _controller = TextEditingController();
  String _query = '';
  int? _selectedTopicId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToRef(TopicReference r) {
    final verse = r.verse ?? 1;
    ref.read(selectedBookNameProvider.notifier).set(r.bookName);
    ref.read(selectedChapterProvider.notifier).set(r.chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(verse);
    ref.read(selectedVersesProvider.notifier).clear();
    if (r.verse != null) ref.read(selectedVersesProvider.notifier).toggle(verse);
    ref.read(navigationControllerProvider).recordHistory(verse: verse);

    if (MediaQuery.sizeOf(context).width <= Breakpoints.compact) {
      ref.read(activeToolProvider.notifier).close();
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  Future<void> _openSeeAlso(String name) async {
    final id = await ref.read(topicIdByNameProvider(name).future);
    if (!mounted || id == null) return;
    setState(() => _selectedTopicId = id);
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _selectedTopicId;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (selectedId != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back to results',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _selectedTopicId = null),
                          ),
                        Text(
                          'Bible Stories',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: () {
                        ref.read(activeToolProvider.notifier).close();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search stories (e.g. Creation, Exodus)…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _selectedTopicId = null;
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedId != null
                ? _StoryDetailView(topicId: selectedId, onRefTap: _goToRef, onSeeAlso: _openSeeAlso)
                : _StoryList(
                    query: _query,
                    onSelect: (id) => setState(() => _selectedTopicId = id),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StoryList extends ConsumerWidget {
  const _StoryList({required this.query, required this.onSelect});

  final String query;
  final void Function(int topicId) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(curatedTopicsByCategoryProvider('story'));
    return stories.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(child: Text('Could not load stories: $e')),
      data: (topics) {
        final q = query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? topics
            : topics.where((t) => t.name.toLowerCase().contains(q)).toList();

        if (filtered.isEmpty) {
          return Center(child: Text('No stories matching "$query".'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final topic = filtered[i];
            return ListTile(
              dense: true,
              title: Text(_titleCase(topic.name)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => onSelect(topic.id),
            );
          },
        );
      },
    );
  }
}

class _StoryDetailView extends ConsumerWidget {
  const _StoryDetailView({
    required this.topicId,
    required this.onRefTap,
    required this.onSeeAlso,
  });

  final int topicId;
  final void Function(TopicReference) onRefTap;
  final void Function(String) onSeeAlso;

  String _refLabel(TopicReference r) {
    var s = '${r.bookName} ${r.chapter}';
    if (r.verse != null) {
      s += ':${r.verse}';
      if (r.verseEnd != null) s += '-${r.verseEnd}';
    }
    return s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(topicDetailProvider(topicId));
    final scheme = Theme.of(context).colorScheme;
    return detail.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (d) {
        if (d == null) return const SizedBox.shrink();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: d.entries.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _titleCase(d.topic.name),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.explore_outlined),
                      tooltip: 'Open in Explorer',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => openInFreshExplorer(
                        context,
                        ref,
                        ExplorerRef.topic(d.topic.id, _titleCase(d.topic.name)),
                      ),
                    ),
                  ],
                ),
              );
            }
            final ev = d.entries[i - 1];
            final see = ev.entry.seeAlso?.split('\n') ?? const [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ev.entry.description.isNotEmpty)
                    Text(
                      ev.entry.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (ev.refs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ev.refs
                            .map((r) => ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(_refLabel(r)),
                                  onPressed: () => onRefTap(r),
                                ))
                            .toList(),
                      ),
                    ),
                  for (final s in see)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        onTap: () => onSeeAlso(s),
                        child: Text(
                          'See also ${_titleCase(s)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Story topics are stored upper-cased; show them in title case for display.
String _titleCase(String s) {
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
