// ignore_for_file: deprecated_member_use
import 'package:drift/drift.dart' show OrderingTerm, OrderingMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/user_providers.dart';
import '../../data/export/notebook_exporter.dart';
import '../../data/export/sermon_exporter.dart' show ExportFormat, ExportAction;
import '../../data/user_store.dart';

/// Format picker + save/print/share actions for exporting a notebook (or a
/// single page, via [onlyPages]) through [NotebookExporter].
class NotebookExportDialog extends ConsumerStatefulWidget {
  final Notebook notebook;
  final List<NotebookPage>? onlyPages;

  const NotebookExportDialog({
    super.key,
    required this.notebook,
    this.onlyPages,
  });

  static Future<void> show(
    BuildContext context,
    Notebook notebook, {
    List<NotebookPage>? onlyPages,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          NotebookExportDialog(notebook: notebook, onlyPages: onlyPages),
    );
  }

  @override
  ConsumerState<NotebookExportDialog> createState() =>
      _NotebookExportDialogState();
}

class _NotebookExportDialogState extends ConsumerState<NotebookExportDialog> {
  bool _isExporting = false;
  ExportFormat _format = ExportFormat.pdf;

  /// Loads the ordered, non-deleted pages of the notebook (or the caller-scoped
  /// [onlyPages] when exporting a single page).
  Future<List<NotebookPage>> _loadPages() async {
    final only = widget.onlyPages;
    if (only != null) return only;
    final store = ref.read(userStoreProvider);
    return (store.select(store.notebookPages)
          ..where((t) => t.notebookId.equals(widget.notebook.id))
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<void> _export(ExportAction action) async {
    setState(() => _isExporting = true);
    try {
      final pages = await _loadPages();
      if (!mounted) return;
      await NotebookExporter.exportNotebook(
        context,
        widget.notebook,
        pages,
        _format,
        action,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final single = widget.onlyPages?.length == 1;
    return AlertDialog(
      title: Text(single ? 'Export Page' : 'Export Notebook'),
      content: _isExporting
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ExportFormat>(
                  title: const Text('PDF'),
                  subtitle: const Text('Formatted, print-ready'),
                  value: ExportFormat.pdf,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                ),
                RadioListTile<ExportFormat>(
                  title: const Text('Markdown'),
                  subtitle: const Text('Headings, lists, bold/italic'),
                  value: ExportFormat.markdown,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                ),
                RadioListTile<ExportFormat>(
                  title: const Text('HTML'),
                  subtitle: const Text('Retains rich formatting'),
                  value: ExportFormat.html,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                ),
                RadioListTile<ExportFormat>(
                  title: const Text('Plain Text'),
                  subtitle: const Text('Raw unformatted text'),
                  value: ExportFormat.text,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                ),
              ],
            ),
      actions: [
        if (!_isExporting) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _export(ExportAction.save),
            child: const Text('Save to Folder'),
          ),
          TextButton.icon(
            onPressed: () => _export(ExportAction.print),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          ElevatedButton(
            onPressed: () => _export(ExportAction.share),
            child: const Text('Share'),
          ),
        ],
      ],
    );
  }
}
