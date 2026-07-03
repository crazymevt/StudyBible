import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/notebook_providers.dart';
import '../../data/user_store.dart';
import 'notebook_export_dialog.dart';
import 'notebook_icons.dart';
import 'notebook_page_editor_screen.dart';
import '../common/breakpoints.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';
import '../tags/tag_palette.dart';

/// The middle view of the Notebooks tool: the pages inside one notebook, shown
/// as a drag-reorderable list. Back returns to the notebook list; tapping a page
/// opens its editor.
class NotebookDetailPanel extends ConsumerWidget {
  final String notebookId;
  const NotebookDetailPanel({super.key, required this.notebookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebookAsync = ref.watch(notebookByIdProvider(notebookId));
    final pagesAsync = ref.watch(pagesForNotebookProvider(notebookId));
    final notebook = notebookAsync.asData?.value;
    final scheme = Theme.of(context).colorScheme;
    final cover = tagColorFromHex(notebook?.colorHex) ?? scheme.primary;

    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to notebooks',
                  onPressed: () =>
                      ref.read(selectedNotebookIdProvider.notifier).set(null),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cover.withValues(alpha: 0.18),
                  foregroundColor: cover,
                  child: Icon(
                    notebookIconFromKey(notebook?.iconKey),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notebook == null
                        ? 'Notebook'
                        : (notebook.title.isEmpty
                              ? 'Untitled Notebook'
                              : notebook.title),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.file_upload),
                  tooltip: 'Export Notebook',
                  onPressed: notebook == null
                      ? null
                      : () => NotebookExportDialog.show(context, notebook),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'New Page',
                  onPressed: () => _addPage(context, ref),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: pagesAsync.when(
              data: (pages) {
                if (pages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.note_add_outlined,
                    title: 'No pages yet',
                    message: 'Tap + to add your first page.',
                  );
                }
                return ReorderableListView.builder(
                  itemCount: pages.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      _reorder(ref, pages, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return _PageTile(
                      key: ValueKey(page.id),
                      page: page,
                      index: index,
                      onTap: () => _openPage(context, ref, page.id),
                      onRename: () => _renamePage(context, ref, page),
                      onDelete: () => _confirmDeletePage(context, ref, page),
                    );
                  },
                );
              },
              loading: () => const SkeletonList(),
              error: (e, st) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Couldn\'t load pages',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPage(BuildContext context, WidgetRef ref) async {
    final page = await ref.read(notebookActionProvider).createPage(notebookId);
    if (!context.mounted) return;
    _openPage(context, ref, page.id);
  }

  /// Opens a page's editor. On wide layouts the editor renders inline in the
  /// panel (beside the reader); on narrow layouts it is pushed as a full-screen
  /// route instead of rendered inline — the mobile tools drawer hosts this panel
  /// inside a DraggableScrollableSheet, and mounting QuillEditor's overlay
  /// inside that sliver corrupts the element tree (mirrors SermonsPanel).
  void _openPage(BuildContext context, WidgetRef ref, String pageId) {
    if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
      ref.read(selectedNotebookPageIdProvider.notifier).set(pageId);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              NotebookPageEditorScreen(pageId: pageId, isFullScreen: true),
        ),
      );
    }
  }

  void _reorder(
    WidgetRef ref,
    List<NotebookPage> pages,
    int oldIndex,
    int newIndex,
  ) {
    // onReorderItem already adjusts newIndex for the removed item, so insert
    // directly at newIndex.
    final ids = pages.map((p) => p.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    ref.read(notebookActionProvider).reorderPages(ids);
  }

  Future<void> _renamePage(
    BuildContext context,
    WidgetRef ref,
    NotebookPage page,
  ) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _RenamePageDialog(initial: page.title),
    );
    if (title == null) return;
    await ref.read(notebookActionProvider).updatePage(page.id, title: title);
  }

  Future<void> _confirmDeletePage(
    BuildContext context,
    WidgetRef ref,
    NotebookPage page,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text(
          'Delete "${page.title.isEmpty ? 'Untitled Page' : page.title}"?',
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
      ref.read(notebookActionProvider).deletePage(page.id);
    }
  }
}

class _PageTile extends StatelessWidget {
  final NotebookPage page;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PageTile({
    super.key,
    required this.page,
    required this.index,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final preview = page.contentPlain?.trim().replaceAll('\n', ' ') ?? '';
    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
      title: Text(page.title.isEmpty ? 'Untitled Page' : page.title),
      subtitle: preview.isEmpty
          ? null
          : Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      // Plain IconButtons WITHOUT tooltips: a ReorderableListView reparents the
      // dragged row, and any OverlayPortal-based widget in it (Tooltip — which a
      // PopupMenuButton always builds) is activated during a layout-driven
      // rebuild, calling markNeedsLayout mid-layout and crashing. Keeping the row
      // free of tooltips avoids that.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onRename,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _RenamePageDialog extends StatefulWidget {
  final String initial;
  const _RenamePageDialog({required this.initial});

  @override
  State<_RenamePageDialog> createState() => _RenamePageDialogState();
}

class _RenamePageDialogState extends State<_RenamePageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _controller.text.trim();
    Navigator.pop(context, t.isEmpty ? 'Untitled Page' : t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Page'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Title'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
