import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/sermon_providers.dart';
import '../../app/shared_prefs.dart';
import '../../app/tag_providers.dart';
import '../../data/user_store.dart';
import '../../domain/natural_compare.dart';
import '../tags/tag_palette.dart';
import 'export_dialog.dart';
import 'series_autocomplete_field.dart';
import 'sermon_editor_screen.dart';
import '../common/breakpoints.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

/// How the sermon list is ordered. "Created" uses the sermon's creation time.
enum _SermonSort { titleAsc, titleDesc, createdDesc, createdAsc }

const Map<_SermonSort, String> _sortLabels = {
  _SermonSort.titleAsc: 'Title (A–Z)',
  _SermonSort.titleDesc: 'Title (Z–A)',
  _SermonSort.createdDesc: 'Newest first',
  _SermonSort.createdAsc: 'Oldest first',
};

/// Sentinel for the "Group by series" toggle in the sort popup menu, which is
/// otherwise populated with [_SermonSort] values.
const _groupBySeriesMenuValue = 'groupBySeries';

/// Actions in a series section header's overflow menu.
enum _SeriesAction { rename, export }

/// Persisted list preferences, so the chosen sort and grouping survive
/// closing the panel (and the app).
const _kSortPrefKey = 'sermonListSort';
const _kGroupBySeriesPrefKey = 'sermonListGroupBySeries';

/// One section of the grouped sermon list: the case-insensitive match key
/// ('' for the no-series group), the display name of the series, and its
/// sermons in list order.
typedef SeriesGroup = ({String key, String name, List<Sermon> sermons});

/// Label for the section holding sermons without a series.
const String kNoSeriesLabel = 'No Series';

/// Groups an already filtered+sorted sermon list into series sections.
///
/// Series names are matched case-insensitively (display name is the first
/// spelling seen). Groups appear in the order of their best-ranked sermon, so
/// the active sort — and pinning — also orders the sections; sermons without
/// a series are collected under [kNoSeriesLabel] at the end.
@visibleForTesting
List<SeriesGroup> groupSermonsBySeries(List<Sermon> sorted) {
  final groups = <String, SeriesGroup>{};
  for (final sermon in sorted) {
    final display = (sermon.series ?? '').trim();
    final key = display.toLowerCase();
    final group = groups.putIfAbsent(
      key,
      () => (
        key: key,
        name: display.isEmpty ? kNoSeriesLabel : display,
        sermons: [],
      ),
    );
    group.sermons.add(sermon);
  }
  final noSeries = groups.remove('');
  return [...groups.values, ?noSeries];
}

/// Reorders [groups] by series name (naturally, so "Week 2" precedes
/// "Week 10"), keeping the no-series group last. Used when a title sort is
/// active: there the best-ranked-sermon order from [groupSermonsBySeries]
/// would scatter the sections (a series is placed by its first sermon's
/// title, not its own name) instead of listing them A–Z.
@visibleForTesting
List<SeriesGroup> sortSeriesGroupsByName(
  List<SeriesGroup> groups, {
  bool descending = false,
}) {
  final named = [
    for (final group in groups)
      if (group.key.isNotEmpty) group,
  ]..sort(
      (a, b) =>
          descending ? naturalCompare(b.name, a.name) : naturalCompare(a.name, b.name),
    );
  return [...named, ...groups.where((g) => g.key.isEmpty)];
}

class SermonsPanel extends ConsumerStatefulWidget {
  const SermonsPanel({super.key});

  @override
  ConsumerState<SermonsPanel> createState() => _SermonsPanelState();
}

class _SermonsPanelState extends ConsumerState<SermonsPanel> {
  final _searchController = TextEditingController();
  String _query = '';
  _SermonSort _sort = _SermonSort.createdDesc;
  bool _groupBySeries = false;
  String? _activeTagId;
  String? _activeTagName;

  /// Series keys ([SeriesGroup.key]) whose sections are collapsed. Session
  /// state only; ignored while a search or tag filter is active so matches
  /// inside a collapsed series still show up.
  final _collapsedSeries = <String>{};

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _sort =
        _SermonSort.values.asNameMap()[prefs.getString(_kSortPrefKey)] ??
        _SermonSort.createdDesc;
    _groupBySeries = prefs.getBool(_kGroupBySeriesPrefKey) ?? false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _titleKey(Sermon s) =>
      (s.title.isEmpty ? 'untitled sermon' : s.title).toLowerCase();

  /// Filters by the search box (matches title, series, or any tag name) and the
  /// pinned tag filter, then sorts by [_sort].
  List<Sermon> _visibleSermons(
    List<Sermon> sermons,
    Map<String, List<TagData>> tagsBySermon,
  ) {
    final raw = _query.trim().toLowerCase();
    final needle = raw.startsWith('#') ? raw.substring(1) : raw;

    final filtered = sermons.where((s) {
      final tags = tagsBySermon[s.id] ?? const <TagData>[];

      if (_activeTagId != null && !tags.any((t) => t.id == _activeTagId)) {
        return false;
      }

      if (needle.isEmpty) return true;
      if (_titleKey(s).contains(needle)) return true;
      if ((s.series ?? '').toLowerCase().contains(needle)) return true;
      return tags.any((t) => t.name.toLowerCase().contains(needle));
    }).toList();

    filtered.sort((a, b) {
      // Pinned sermons always float to the top, whatever the chosen sort.
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      switch (_sort) {
        case _SermonSort.titleAsc:
          return naturalCompare(_titleKey(a), _titleKey(b));
        case _SermonSort.titleDesc:
          return naturalCompare(_titleKey(b), _titleKey(a));
        case _SermonSort.createdDesc:
          return b.createdAt.compareTo(a.createdAt);
        case _SermonSort.createdAsc:
          return a.createdAt.compareTo(b.createdAt);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final activeSermonId = ref.watch(selectedSermonIdProvider);
    if (activeSermonId != null) {
      // Keyed on the sermon id so switching to a different sermon (e.g. from
      // an Explorer backlink while this panel is already open) mounts a
      // fresh editor instead of reusing the old one's State — the editor
      // only loads its content in initState(), so without this key it would
      // keep showing the previous sermon.
      return SermonEditorScreen(
        key: ValueKey(activeSermonId),
        sermonId: activeSermonId,
        isFullScreen: false,
      );
    }

    final sermonsAsync = ref.watch(allSermonsProvider);
    final tagsBySermon =
        ref.watch(sermonTagsProvider).asData?.value ??
        const <String, List<TagData>>{};

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sermons',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<Object>(
                          icon: const Icon(Icons.sort),
                          tooltip: 'Sort',
                          initialValue: _sort,
                          onSelected: (v) {
                            final prefs = ref.read(sharedPreferencesProvider);
                            setState(() {
                              if (v is _SermonSort) {
                                _sort = v;
                                unawaited(
                                  prefs.setString(_kSortPrefKey, v.name),
                                );
                              } else {
                                _groupBySeries = !_groupBySeries;
                                unawaited(
                                  prefs.setBool(
                                    _kGroupBySeriesPrefKey,
                                    _groupBySeries,
                                  ),
                                );
                              }
                            });
                          },
                          itemBuilder: (context) => [
                            for (final entry in _sortLabels.entries)
                              CheckedPopupMenuItem<Object>(
                                value: entry.key,
                                checked: _sort == entry.key,
                                child: Text(entry.value),
                              ),
                            const PopupMenuDivider(),
                            CheckedPopupMenuItem<Object>(
                              value: _groupBySeriesMenuValue,
                              checked: _groupBySeries,
                              child: const Text('Group by series'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_upload),
                          tooltip: 'Export All',
                          onPressed: () {
                            sermonsAsync.whenData((sermons) {
                              if (sermons.isNotEmpty) {
                                ExportDialog.show(context, sermons);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No sermons to export.'),
                                  ),
                                );
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'New Sermon',
                          onPressed: () => _showNewSermonDialog(context, ref),
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
                  ],
                ),
                _buildSearchBar(context),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: sermonsAsync.when(
                data: (sermons) {
                  if (sermons.isEmpty) {
                    return const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No sermons yet',
                      message: 'Tap + to start your first sermon.',
                    );
                  }
                  final visible = _visibleSermons(sermons, tagsBySermon);
                  if (visible.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off,
                      title: 'No matching sermons',
                      message:
                          'Try a different search or clear the tag filter.',
                    );
                  }
                  if (!_groupBySeries) {
                    return ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) => _buildSermonTile(
                        context,
                        visible[index],
                        tagsBySermon[visible[index].id] ?? const <TagData>[],
                      ),
                    );
                  }
                  // Grouped view: flatten the sections into one row list so a
                  // single ListView keeps scrolling (and lazy building) cheap.
                  // While filtering, collapse is suspended (all sections
                  // expanded, headers not tappable) so no match stays hidden.
                  final filtering =
                      _query.trim().isNotEmpty || _activeTagId != null;
                  var groups = groupSermonsBySeries(visible);
                  if (_sort == _SermonSort.titleAsc ||
                      _sort == _SermonSort.titleDesc) {
                    groups = sortSeriesGroupsByName(
                      groups,
                      descending: _sort == _SermonSort.titleDesc,
                    );
                  }
                  final rows = <Object>[];
                  for (final group in groups) {
                    rows.add(group);
                    if (filtering || !_collapsedSeries.contains(group.key)) {
                      rows.addAll(group.sermons);
                    }
                  }
                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, index) => rows[index + 1] is Sermon
                        ? const Divider(height: 1)
                        : const SizedBox.shrink(),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      if (row is SeriesGroup) {
                        return _buildSeriesHeader(
                          context,
                          row,
                          collapsible: !filtering,
                          collapsed:
                              !filtering &&
                              _collapsedSeries.contains(row.key),
                        );
                      }
                      final sermon = row as Sermon;
                      return _buildSermonTile(
                        context,
                        sermon,
                        tagsBySermon[sermon.id] ?? const <TagData>[],
                      );
                    },
                  );
                },
                loading: () => const SkeletonList(),
                error: (e, st) => const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Couldn\'t load sermons',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesHeader(
    BuildContext context,
    SeriesGroup group, {
    required bool collapsible,
    required bool collapsed,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: collapsible
            ? () => setState(() {
                if (!_collapsedSeries.remove(group.key)) {
                  _collapsedSeries.add(group.key);
                }
              })
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 4, 2),
          child: Row(
            children: [
              if (collapsible)
                Icon(
                  collapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.primary,
                )
              else
                const SizedBox(width: 20),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${group.name} (${group.sermons.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<_SeriesAction>(
                iconSize: 18,
                padding: EdgeInsets.zero,
                tooltip: 'Series options',
                onSelected: (action) => switch (action) {
                  _SeriesAction.rename => _renameSeries(group),
                  _SeriesAction.export =>
                    ExportDialog.show(context, group.sermons),
                },
                itemBuilder: (context) => [
                  // The no-series section isn't a series, so there's nothing
                  // to rename.
                  if (group.key.isNotEmpty)
                    const PopupMenuItem(
                      value: _SeriesAction.rename,
                      child: ListTile(
                        leading: Icon(Icons.drive_file_rename_outline),
                        title: Text('Rename Series'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: _SeriesAction.export,
                    child: ListTile(
                      leading: Icon(Icons.file_upload),
                      title: Text('Export Series'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameSeries(SeriesGroup group) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _RenameSeriesDialog(currentName: group.name),
    );
    if (newName == null || newName.trim() == group.name || !mounted) return;

    final count = await ref
        .read(sermonActionProvider)
        .renameSeries(group.name, newName);
    if (!mounted) return;
    // The old key's collapse entry is stale either way (the group now lives
    // under the new name, or merged into an existing one).
    setState(() => _collapsedSeries.remove(group.key));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Renamed series for $count ${count == 1 ? 'sermon' : 'sermons'}.',
        ),
      ),
    );
  }

  Widget _buildSermonTile(
    BuildContext context,
    Sermon sermon,
    List<TagData> tags,
  ) {
    return ListTile(
      title: Text(sermon.title.isEmpty ? 'Untitled Sermon' : sermon.title),
      subtitle: _buildSubtitle(context, sermon, tags),
      // Also when grouped (where the subtitle is only tag chips): the chips
      // can still wrap to a second line, and a two-line subtitle in a
      // single-line-height tile gets clipped.
      isThreeLine: tags.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              sermon.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 20,
            ),
            color: sermon.pinned ? Theme.of(context).colorScheme.primary : null,
            tooltip: sermon.pinned ? 'Unpin' : 'Pin to top',
            onPressed: () => ref
                .read(sermonActionProvider)
                .setPinned(sermon.id, !sermon.pinned),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Delete Sermon',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Sermon'),
                  content: const Text(
                    'Are you sure you want to delete this sermon?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(sermonActionProvider).deleteSermon(sermon.id);
              }
            },
          ),
        ],
      ),
      onTap: () {
        if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
          ref.read(selectedSermonIdProvider.notifier).set(sermon.id);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  SermonEditorScreen(sermonId: sermon.id, isFullScreen: true),
            ),
          );
        }
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search sermons or #tags…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_activeTagId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InputChip(
                avatar: const Icon(Icons.filter_alt, size: 16),
                label: Text('#${_activeTagName ?? ''}'),
                onDeleted: () => setState(() {
                  _activeTagId = null;
                  _activeTagName = null;
                }),
              ),
            ),
          ),
      ],
    );
  }

  /// The tile subtitle: the series name (omitted when the list is grouped by
  /// series — the section header already shows it) plus any tag chips.
  Widget? _buildSubtitle(
    BuildContext context,
    Sermon sermon,
    List<TagData> tags,
  ) {
    final series = (sermon.series?.isNotEmpty ?? false)
        ? sermon.series!
        : kNoSeriesLabel;
    if (tags.isEmpty) return _groupBySeries ? null : Text(series);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (!_groupBySeries) Text(series),
          for (final tag in tags) _TagChip(tag: tag, onTap: () => _pinTag(tag)),
        ],
      ),
    );
  }

  void _pinTag(TagData tag) {
    setState(() {
      _activeTagId = tag.id;
      _activeTagName = tag.name;
    });
  }

  Future<void> _showNewSermonDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String title, String? series})>(
      context: context,
      builder: (context) => const _NewSermonDialog(),
    );
    if (result == null || !context.mounted) return;

    final sermon = await ref
        .read(sermonActionProvider)
        .createSermon(result.title, series: result.series);
    if (!context.mounted) return;

    // Open the editor only after the dialog has fully dismissed (its future has
    // completed). Mounting the editor's QuillEditor while the dialog route was
    // still tearing down corrupted the element tree
    // ("_dependents.isEmpty is not true") and crashed.
    if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
      ref.read(selectedSermonIdProvider.notifier).set(sermon.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SermonEditorScreen(sermonId: sermon.id, isFullScreen: true),
        ),
      );
    }
  }
}

/// A compact, tappable coloured tag chip shown beside a sermon's series.
/// Tapping pins the tag as the list's active filter.
class _TagChip extends StatelessWidget {
  final TagData tag;
  final VoidCallback onTap;

  const _TagChip({required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = tagChipStyle(context, tag.colorHex);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.border),
        ),
        child: Text(
          '#${tag.name}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: style.foreground),
        ),
      ),
    );
  }
}

/// New-sermon dialog. A [StatefulWidget] so its controllers are disposed in
/// [State.dispose] — i.e. after the route is fully removed — rather than the
/// instant `showDialog` returns, which raced the dismiss animation and threw
/// "TextEditingController used after disposed". Returns the entered
/// (title, series) via [Navigator.pop], or null on cancel.
class _NewSermonDialog extends ConsumerStatefulWidget {
  const _NewSermonDialog();

  @override
  ConsumerState<_NewSermonDialog> createState() => _NewSermonDialogState();
}

class _NewSermonDialogState extends ConsumerState<_NewSermonDialog> {
  final _titleController = TextEditingController();
  final _seriesController = TextEditingController();
  final _seriesFocusNode = FocusNode();

  @override
  void dispose() {
    _titleController.dispose();
    _seriesController.dispose();
    _seriesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Sermon'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          SeriesAutocompleteField(
            controller: _seriesController,
            focusNode: _seriesFocusNode,
            options: ref.watch(sermonSeriesNamesProvider),
            decoration: const InputDecoration(labelText: 'Series (Optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          // The raw text is fine here: createSermon normalizes it (trims,
          // blank → null).
          onPressed: () => Navigator.pop(context, (
            title: _titleController.text,
            series: _seriesController.text,
          )),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Prompts for a series' new name, suggesting existing series while typing —
/// picking one merges the two series. A [StatefulWidget] for the same
/// dispose-after-route-teardown reason as [_NewSermonDialog]. Pops with the
/// entered name, or null on cancel.
class _RenameSeriesDialog extends ConsumerStatefulWidget {
  final String currentName;

  const _RenameSeriesDialog({required this.currentName});

  @override
  ConsumerState<_RenameSeriesDialog> createState() =>
      _RenameSeriesDialogState();
}

class _RenameSeriesDialogState extends ConsumerState<_RenameSeriesDialog> {
  late final _nameController = TextEditingController(
    text: widget.currentName,
  );
  final _nameFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Series'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Renames the series on every sermon in "${widget.currentName}". '
            'Renaming to an existing series merges them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SeriesAutocompleteField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            options: ref.watch(sermonSeriesNamesProvider),
            decoration: const InputDecoration(labelText: 'Series name'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Rename')),
      ],
    );
  }
}
