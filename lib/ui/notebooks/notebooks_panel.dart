import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/notebook_providers.dart';
import '../../app/tag_providers.dart';
import '../../data/user_store.dart';
import '../tags/tag_editor_dialog.dart';
import '../tags/tag_palette.dart';
import 'notebook_detail_panel.dart';
import 'notebook_icons.dart';
import 'notebook_page_editor_screen.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

/// How the notebook list is ordered.
enum _NotebookSort { titleAsc, titleDesc, updatedDesc, updatedAsc }

const Map<_NotebookSort, String> _sortLabels = {
  _NotebookSort.titleAsc: 'Title (A–Z)',
  _NotebookSort.titleDesc: 'Title (Z–A)',
  _NotebookSort.updatedDesc: 'Recently updated',
  _NotebookSort.updatedAsc: 'Oldest first',
};

/// The Notebooks reader tool. Hosts three views in one panel, chosen by the two
/// selection providers: the notebook list, a selected notebook's page list
/// ([NotebookDetailPanel]), and a selected page's editor
/// ([NotebookPageEditorScreen], inline).
class NotebooksPanel extends ConsumerStatefulWidget {
  const NotebooksPanel({super.key});

  @override
  ConsumerState<NotebooksPanel> createState() => _NotebooksPanelState();
}

class _NotebooksPanelState extends ConsumerState<NotebooksPanel> {
  final _searchController = TextEditingController();
  String _query = '';
  _NotebookSort _sort = _NotebookSort.updatedDesc;
  String? _activeTagId;
  String? _activeTagName;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _titleKey(Notebook n) =>
      (n.title.isEmpty ? 'untitled notebook' : n.title).toLowerCase();

  List<Notebook> _visibleNotebooks(
    List<Notebook> notebooks,
    Map<String, List<TagData>> tagsByNotebook,
  ) {
    final raw = _query.trim().toLowerCase();
    final needle = raw.startsWith('#') ? raw.substring(1) : raw;

    final filtered = notebooks.where((n) {
      final tags = tagsByNotebook[n.id] ?? const <TagData>[];
      if (_activeTagId != null && !tags.any((t) => t.id == _activeTagId)) {
        return false;
      }
      if (needle.isEmpty) return true;
      if (_titleKey(n).contains(needle)) return true;
      return tags.any((t) => t.name.toLowerCase().contains(needle));
    }).toList();

    filtered.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      switch (_sort) {
        case _NotebookSort.titleAsc:
          return _titleKey(a).compareTo(_titleKey(b));
        case _NotebookSort.titleDesc:
          return _titleKey(b).compareTo(_titleKey(a));
        case _NotebookSort.updatedDesc:
          return b.updatedAt.compareTo(a.updatedAt);
        case _NotebookSort.updatedAsc:
          return a.updatedAt.compareTo(b.updatedAt);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Page editor takes precedence, then the notebook's page list, then the
    // notebook list.
    final activePageId = ref.watch(selectedNotebookPageIdProvider);
    if (activePageId != null) {
      // Keyed on the page id so switching to a different page (e.g. from an
      // Explorer backlink while this panel is already open) mounts a fresh
      // editor instead of reusing the old one's State — the editor only loads
      // its content in initState(), so without this key it would keep
      // showing the previous page.
      return NotebookPageEditorScreen(
        key: ValueKey(activePageId),
        pageId: activePageId,
        isFullScreen: false,
      );
    }
    final activeNotebookId = ref.watch(selectedNotebookIdProvider);
    if (activeNotebookId != null) {
      return NotebookDetailPanel(notebookId: activeNotebookId);
    }

    final notebooksAsync = ref.watch(allNotebooksProvider);
    final tagsByNotebook =
        ref.watch(notebookTagsProvider).asData?.value ??
        const <String, List<TagData>>{};

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notebooks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<_NotebookSort>(
                          icon: const Icon(Icons.sort),
                          tooltip: 'Sort',
                          initialValue: _sort,
                          onSelected: (v) => setState(() => _sort = v),
                          itemBuilder: (context) => [
                            for (final entry in _sortLabels.entries)
                              CheckedPopupMenuItem(
                                value: entry.key,
                                checked: _sort == entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'New Notebook',
                          onPressed: () => _showNewNotebookDialog(context),
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
              child: notebooksAsync.when(
                data: (notebooks) {
                  if (notebooks.isEmpty) {
                    return const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No notebooks yet',
                      message: 'Tap + to create your first notebook.',
                    );
                  }
                  final visible = _visibleNotebooks(notebooks, tagsByNotebook);
                  if (visible.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off,
                      title: 'No matching notebooks',
                      message:
                          'Try a different search or clear the tag filter.',
                    );
                  }
                  return ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notebook = visible[index];
                      final tags =
                          tagsByNotebook[notebook.id] ?? const <TagData>[];
                      return _NotebookTile(
                        notebook: notebook,
                        tags: tags,
                        onOpen: () => _openNotebook(notebook.id),
                        onPinTag: _pinTag,
                        onTogglePin: () => ref
                            .read(notebookActionProvider)
                            .setPinned(notebook.id, !notebook.pinned),
                        onEdit: () => _showEditNotebookDialog(context, notebook),
                        onManageTags: () => showDialog(
                          context: context,
                          builder: (_) => TagEditorDialog(
                            entityId: notebook.id,
                            entityType: 'notebook',
                          ),
                        ),
                        onDelete: () => _confirmDelete(context, notebook),
                      );
                    },
                  );
                },
                loading: () => const SkeletonList(),
                error: (e, st) => const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Couldn\'t load notebooks',
                ),
              ),
            ),
          ),
        ],
      ),
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
            hintText: 'Search notebooks or #tags…',
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

  void _pinTag(TagData tag) {
    setState(() {
      _activeTagId = tag.id;
      _activeTagName = tag.name;
    });
  }

  void _openNotebook(String id) {
    ref.read(selectedNotebookIdProvider.notifier).set(id);
  }

  Future<void> _confirmDelete(BuildContext context, Notebook notebook) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notebook'),
        content: Text(
          'Delete "${notebook.title.isEmpty ? 'Untitled Notebook' : notebook.title}" '
          'and all of its pages?',
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
      ref.read(notebookActionProvider).deleteNotebook(notebook.id);
    }
  }

  Future<void> _showNewNotebookDialog(BuildContext context) async {
    final result = await showDialog<_NotebookForm>(
      context: context,
      builder: (context) => const NotebookFormDialog(),
    );
    if (result == null || !context.mounted) return;
    final notebook = await ref
        .read(notebookActionProvider)
        .createNotebook(
          result.title,
          colorHex: result.colorHex,
          iconKey: result.iconKey,
        );
    if (!context.mounted) return;
    _openNotebook(notebook.id);
  }

  Future<void> _showEditNotebookDialog(
    BuildContext context,
    Notebook notebook,
  ) async {
    final result = await showDialog<_NotebookForm>(
      context: context,
      builder: (context) => NotebookFormDialog(existing: notebook),
    );
    if (result == null) return;
    await ref
        .read(notebookActionProvider)
        .updateNotebook(
          notebook.id,
          title: result.title,
          colorHex: Value(result.colorHex),
          iconKey: Value(result.iconKey),
        );
  }
}

/// A single notebook row: cover (color + icon), title, page-count/tag subtitle,
/// and pin/edit/delete actions.
class _NotebookTile extends StatelessWidget {
  final Notebook notebook;
  final List<TagData> tags;
  final VoidCallback onOpen;
  final ValueChanged<TagData> onPinTag;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onManageTags;
  final VoidCallback onDelete;

  const _NotebookTile({
    required this.notebook,
    required this.tags,
    required this.onOpen,
    required this.onPinTag,
    required this.onTogglePin,
    required this.onEdit,
    required this.onManageTags,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cover = tagColorFromHex(notebook.colorHex) ?? scheme.primary;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cover.withValues(alpha: 0.18),
        foregroundColor: cover,
        child: Icon(notebookIconFromKey(notebook.iconKey)),
      ),
      title: Text(
        notebook.title.isEmpty ? 'Untitled Notebook' : notebook.title,
      ),
      subtitle: tags.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in tags)
                    _TagChip(tag: tag, onTap: () => onPinTag(tag)),
                ],
              ),
            ),
      isThreeLine: tags.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              notebook.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 20,
            ),
            color: notebook.pinned ? scheme.primary : null,
            tooltip: notebook.pinned ? 'Unpin' : 'Pin to top',
            onPressed: onTogglePin,
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'tags') onManageTags();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit cover'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'tags',
                child: ListTile(
                  leading: Icon(Icons.label_outline),
                  title: Text('Manage tags'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: onOpen,
    );
  }
}

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

/// Result of the new/edit notebook dialog.
class _NotebookForm {
  final String title;
  final String? colorHex;
  final String? iconKey;
  const _NotebookForm(this.title, this.colorHex, this.iconKey);
}

/// Create/edit dialog for a notebook: title + cover color + cover icon. A
/// [StatefulWidget] so its controller is disposed after the route tears down
/// (mirrors the sermon dialog's controller-lifecycle fix). Exported so the
/// export dialog can be launched from anywhere without re-declaring it.
class NotebookFormDialog extends StatefulWidget {
  final Notebook? existing;
  const NotebookFormDialog({super.key, this.existing});

  @override
  State<NotebookFormDialog> createState() => _NotebookFormDialogState();
}

class _NotebookFormDialogState extends State<NotebookFormDialog> {
  late final TextEditingController _titleController;
  String? _colorHex;
  String? _iconKey;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _colorHex = widget.existing?.colorHex;
    _iconKey = widget.existing?.iconKey;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Notebook' : 'New Notebook'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            Text('Cover colour', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TagSwatchRow(
              selectedHex: _colorHex,
              onSelected: (hex) => setState(() => _colorHex = hex),
            ),
            const SizedBox(height: 16),
            Text('Cover icon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            NotebookIconPicker(
              selectedKey: _iconKey,
              onSelected: (key) => setState(() => _iconKey = key),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            Navigator.pop(
              context,
              _NotebookForm(
                title.isEmpty ? 'Untitled Notebook' : title,
                _colorHex,
                _iconKey,
              ),
            );
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

