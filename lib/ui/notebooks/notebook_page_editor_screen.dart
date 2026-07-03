import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/notebook_providers.dart';
import '../../app/revision_common.dart';
import '../../app/user_providers.dart';
import '../../data/logging.dart';
import '../../data/user_store.dart';
import '../common/breakpoints.dart';
import '../common/quill_dictation.dart';
import '../common/reference_autolink.dart';
import '../common/speech_input_button.dart';
import '../tags/tag_editor_dialog.dart';
import 'insert_scripture_dialog.dart';
import 'notebook_export_dialog.dart';
import 'notebook_page_revisions_dialog.dart';

/// Secondary actions collapsed into the editor's overflow menu on narrow
/// layouts (phones, the inline panel beside the reader).
enum _PageAction { insertScripture, tags, revisions, export }

/// Rich-text editor for a single [NotebookPage]. A close clone of
/// SermonEditorScreen (autosave, reference auto-linking, remote-conflict banner,
/// revision history) minus presentation/outline/series, plus an Insert
/// Scripture action. Renders inline in the notebooks panel (`isFullScreen:
/// false`) beside the reader, or as a pushed full-screen route.
class NotebookPageEditorScreen extends ConsumerStatefulWidget {
  final String pageId;
  final bool isFullScreen;

  const NotebookPageEditorScreen({
    super.key,
    required this.pageId,
    this.isFullScreen = true,
  });

  @override
  ConsumerState<NotebookPageEditorScreen> createState() =>
      _NotebookPageEditorScreenState();
}

class _NotebookPageEditorScreenState
    extends ConsumerState<NotebookPageEditorScreen> {
  late QuillController _controller;
  bool _isInitialized = false;
  final _titleController = TextEditingController();

  int _loadedUpdatedAt = 0;
  bool _internalWrite = false;
  bool _conflictDetected = false;
  NotebookPage? _incomingRemote;
  bool _fullScreenChildOpen = false;
  Timer? _autolinkDebounce;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    final store = ref.read(userStoreProvider);
    final page = await (store.select(
      store.notebookPages,
    )..where((t) => t.id.equals(widget.pageId))).getSingleOrNull();
    if (page != null) {
      _titleController.text = page.title;
      _loadedUpdatedAt = page.updatedAt;

      _controller = QuillController(
        document: Document.fromJson(_decodeContent(page.content)),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _controller.addListener(_savePageContent);
      _controller.addListener(_scheduleAutolink);
      _titleController.addListener(_savePageMetadata);

      setState(() => _isInitialized = true);
    }
  }

  List<dynamic> _decodeContent(String content) {
    try {
      return jsonDecode(content) as List<dynamic>;
    } catch (e, stack) {
      logError(e, stack, context: 'NotebookPageEditor: parse content');
      return [
        {'insert': '\n'},
      ];
    }
  }

  String _currentContentJson() =>
      jsonEncode(_controller.document.toDelta().toJson());

  void _scheduleAutolink() {
    _autolinkDebounce?.cancel();
    _autolinkDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted || _conflictDetected || _internalWrite) return;
      applyReferenceAutolinks(_controller, autolinkBooks(ref));
    });
  }

  Future<void> _savePageContent() async {
    if (_conflictDetected || _internalWrite) return;
    final ts = await ref
        .read(notebookActionProvider)
        .updatePage(widget.pageId, content: _currentContentJson());
    _loadedUpdatedAt = ts;
  }

  Future<void> _savePageMetadata() async {
    if (_conflictDetected || _internalWrite) return;
    final ts = await ref
        .read(notebookActionProvider)
        .updatePage(widget.pageId, title: _titleController.text);
    _loadedUpdatedAt = ts;
  }

  void _applyPageToEditor(NotebookPage page) {
    _controller.removeListener(_savePageContent);
    _controller.removeListener(_scheduleAutolink);
    _controller.dispose();

    _controller = QuillController(
      document: Document.fromJson(_decodeContent(page.content)),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.addListener(_savePageContent);
    _controller.addListener(_scheduleAutolink);
    _titleController.text = page.title;
    _loadedUpdatedAt = page.updatedAt;
  }

  void _onPageChanged(NotebookPage? page) {
    if (page == null ||
        _internalWrite ||
        _conflictDetected ||
        _fullScreenChildOpen) {
      return;
    }
    if (page.deleted || page.updatedAt <= _loadedUpdatedAt) return;
    final changed =
        page.content != _currentContentJson() ||
        page.title != _titleController.text;
    if (changed) {
      setState(() {
        _conflictDetected = true;
        _incomingRemote = page;
      });
    } else {
      _loadedUpdatedAt = page.updatedAt;
    }
  }

  Future<void> _keepMine() async {
    final remote = _incomingRemote;
    if (remote == null) return;
    _internalWrite = true;
    await ref
        .read(notebookPageRevisionActionProvider)
        .saveRevision(
          pageId: widget.pageId,
          title: remote.title,
          content: remote.content,
          label: 'Version from another device',
          kind: RevisionKind.conflict,
        );
    final ts = await ref
        .read(notebookActionProvider)
        .updatePage(
          widget.pageId,
          title: _titleController.text,
          content: _currentContentJson(),
        );
    _loadedUpdatedAt = ts;
    _internalWrite = false;
    if (mounted) {
      setState(() {
        _conflictDetected = false;
        _incomingRemote = null;
      });
    }
  }

  Future<void> _useTheirs() async {
    final remote = _incomingRemote;
    if (remote == null) return;
    _internalWrite = true;
    await ref
        .read(notebookPageRevisionActionProvider)
        .saveRevision(
          pageId: widget.pageId,
          title: _titleController.text,
          content: _currentContentJson(),
          label: 'Your version before reload',
          kind: RevisionKind.restore,
        );
    setState(() => _applyPageToEditor(remote));
    _internalWrite = false;
    if (mounted) {
      setState(() {
        _conflictDetected = false;
        _incomingRemote = null;
      });
    }
  }

  Future<void> _openFullScreen() async {
    _fullScreenChildOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NotebookPageEditorScreen(pageId: widget.pageId, isFullScreen: true),
      ),
    );
    if (!mounted) {
      _fullScreenChildOpen = false;
      return;
    }
    final store = ref.read(userStoreProvider);
    final page = await (store.select(
      store.notebookPages,
    )..where((t) => t.id.equals(widget.pageId))).getSingleOrNull();
    if (!mounted) {
      _fullScreenChildOpen = false;
      return;
    }
    final changed = page != null && page.updatedAt > _loadedUpdatedAt;
    _internalWrite = true;
    setState(() {
      if (changed) _applyPageToEditor(page);
      _conflictDetected = false;
      _incomingRemote = null;
    });
    _internalWrite = false;
    _fullScreenChildOpen = false;
  }

  Future<void> _openRevisions() async {
    final restored = await NotebookPageRevisionsDialog.show(
      context,
      pageId: widget.pageId,
      currentTitle: _titleController.text,
      currentContent: _currentContentJson(),
    );
    if (restored == null || !mounted) return;

    _internalWrite = true;
    await ref
        .read(notebookPageRevisionActionProvider)
        .restoreRevision(restored.id);
    final store = ref.read(userStoreProvider);
    final page = await (store.select(
      store.notebookPages,
    )..where((t) => t.id.equals(widget.pageId))).getSingleOrNull();
    if (page != null && mounted) {
      setState(() => _applyPageToEditor(page));
    }
    _internalWrite = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revision restored')),
      );
    }
  }

  Future<void> _insertScripture() async {
    final result = await InsertScriptureDialog.show(context);
    if (result == null || !mounted) return;
    final index = _controller.selection.baseOffset.clamp(
      0,
      _controller.document.length - 1,
    );
    // Insert on its own paragraph. Compose through the controller so the save
    // and autolink listeners fire (the autolinker turns the reference into a
    // link on its next pass).
    final delta = Delta()
      ..retain(index)
      ..insert('${result.combined}\n');
    _controller.compose(delta, _controller.selection, ChangeSource.local);
  }

  Future<void> _exportPage() async {
    final store = ref.read(userStoreProvider);
    final page = await (store.select(
      store.notebookPages,
    )..where((t) => t.id.equals(widget.pageId))).getSingleOrNull();
    if (page == null || !mounted) return;
    final notebook = await (store.select(
      store.notebooks,
    )..where((t) => t.id.equals(page.notebookId))).getSingleOrNull();
    if (notebook == null || !mounted) return;
    NotebookExportDialog.show(context, notebook, onlyPages: [page]);
  }

  void _manageTags() {
    showDialog(
      context: context,
      builder: (_) =>
          TagEditorDialog(entityId: widget.pageId, entityType: 'notebookPage'),
    );
  }

  void _handleAction(_PageAction action) {
    switch (action) {
      case _PageAction.insertScripture:
        _insertScripture();
      case _PageAction.tags:
        _manageTags();
      case _PageAction.revisions:
        _openRevisions();
      case _PageAction.export:
        _exportPage();
    }
  }

  Widget _buildOverflowMenu() {
    return PopupMenuButton<_PageAction>(
      tooltip: 'More',
      onSelected: _handleAction,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _PageAction.insertScripture,
          child: ListTile(
            leading: Icon(Icons.menu_book),
            title: Text('Insert Scripture'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _PageAction.tags,
          child: ListTile(
            leading: Icon(Icons.label),
            title: Text('Manage Tags'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _PageAction.revisions,
          child: ListTile(
            leading: Icon(Icons.history),
            title: Text('Revision History'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _PageAction.export,
          child: ListTile(
            leading: Icon(Icons.file_upload),
            title: Text('Export Page'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _autolinkDebounce?.cancel();
    if (_isInitialized) {
      _controller.removeListener(_savePageContent);
      _controller.removeListener(_scheduleAutolink);
      _controller.dispose();
      _titleController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.isFullScreen
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const Center(child: CircularProgressIndicator());
    }

    ref.listen<AsyncValue<NotebookPage?>>(
      notebookPageByIdProvider(widget.pageId),
      (prev, next) => _onPageChanged(next.value),
    );

    final editorBody = LayoutBuilder(
      builder: (context, constraints) {
        const titleFieldHeight = 68.0;
        const twoRowToolbarHeight = 96.0;
        const minEditorHeight = 140.0;
        final bannerHeight = _conflictDetected ? 88.0 : 0.0;
        final multiRowToolbar =
            constraints.maxHeight >=
            bannerHeight + titleFieldHeight + twoRowToolbarHeight + minEditorHeight;

        return Column(
          children: [
            if (_conflictDetected) _buildConflictBanner(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: QuillSimpleToolbar(
                    controller: _controller,
                    config: QuillSimpleToolbarConfig(
                      multiRowsDisplay: multiRowToolbar,
                    ),
                  ),
                ),
                SpeechInputButton(
                  onResult: (t) => insertDictatedText(_controller, t),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QuillEditor.basic(
                    controller: _controller,
                    config: QuillEditorConfig(
                      customLinkPrefixes: referenceLinkPrefixes,
                      customRecognizerBuilder: referenceRecognizerBuilder(
                        ref,
                        context,
                      ),
                      onLaunchUrl: (url) =>
                          handleReferenceLaunch(ref, context, url),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.isFullScreen) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          title: const Text('Edit Page'),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu_book),
              tooltip: 'Insert Scripture',
              onPressed: _insertScripture,
            ),
            if (context.isPhone)
              _buildOverflowMenu()
            else ...[
              IconButton(
                icon: const Icon(Icons.label),
                tooltip: 'Manage Tags',
                onPressed: _manageTags,
              ),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Revision History',
                onPressed: _openRevisions,
              ),
              IconButton(
                icon: const Icon(Icons.file_upload),
                tooltip: 'Export Page',
                onPressed: _exportPage,
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: editorBody,
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to pages',
                  onPressed: () => ref
                      .read(selectedNotebookPageIdProvider.notifier)
                      .set(null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Page',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu_book),
                  tooltip: 'Insert Scripture',
                  onPressed: _insertScripture,
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Full Screen',
                  onPressed: _openFullScreen,
                ),
                _buildOverflowMenu(),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: editorBody),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: scheme.errorContainer,
      leading: Icon(Icons.sync_problem, color: scheme.onErrorContainer),
      content: Text(
        'This page was changed on another device while you had it open. '
        'Pick which version to keep — the other is saved to revision history '
        'either way.',
        style: TextStyle(color: scheme.onErrorContainer),
      ),
      actions: [
        TextButton(onPressed: _useTheirs, child: const Text('Use their version')),
        TextButton(onPressed: _keepMine, child: const Text('Keep mine')),
      ],
    );
  }
}
