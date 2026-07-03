import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_store.dart';
import '../tags/tag_editor_dialog.dart';
import 'package:uuid/uuid.dart';

class AttachmentConfigDialog extends ConsumerStatefulWidget {
  final MediaAttachment attachment;
  final List<AttachmentReference> existingReferences;

  const AttachmentConfigDialog({
    super.key,
    required this.attachment,
    this.existingReferences = const [],
  });

  @override
  ConsumerState<AttachmentConfigDialog> createState() => _AttachmentConfigDialogState();
}

class _AttachmentConfigDialogState extends ConsumerState<AttachmentConfigDialog> {
  late TextEditingController _titleController;
  final List<AttachmentReference> _references = [];
  
  String? _newRefBook;
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _verseController = TextEditingController();

  static const List<String> _allBooks = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
    'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings',
    '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job',
    'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah',
    'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel',
    'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah',
    'Haggai', 'Zechariah', 'Malachi', 'Matthew', 'Mark', 'Luke', 'John',
    'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians',
    'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians',
    '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
    'Hebrews', 'James', '1 Peter', '2 Peter', '1 John', '2 John',
    '3 John', 'Jude', 'Revelation',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.attachment.title ?? widget.attachment.filename);
    _references.addAll(widget.existingReferences);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _chapterController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  void _addReference() {
    if (_newRefBook == null || _chapterController.text.isEmpty) return;
    
    final chapter = int.tryParse(_chapterController.text);
    if (chapter == null) return;
    
    final verseStr = _verseController.text.trim();
    if (verseStr.isEmpty) {
      // Add chapter level reference
      setState(() {
        _references.add(AttachmentReference(
          id: const Uuid().v4(),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          deviceId: '', // Will be updated on save
          deleted: false,
          attachmentId: widget.attachment.id,
          bookName: _newRefBook!,
          chapter: chapter,
          verse: null,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
        _verseController.clear();
      });
    } else {
      // Handle range or single verse
      final parts = verseStr.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start != null && end != null && start <= end) {
          setState(() {
            for (int v = start; v <= end; v++) {
              _references.add(AttachmentReference(
                id: const Uuid().v4(),
                updatedAt: DateTime.now().millisecondsSinceEpoch,
                deviceId: '',
                deleted: false,
                attachmentId: widget.attachment.id,
                bookName: _newRefBook!,
                chapter: chapter,
                verse: v,
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ));
            }
            _verseController.clear();
          });
        }
      } else {
        final verse = int.tryParse(verseStr);
        if (verse != null) {
          setState(() {
            _references.add(AttachmentReference(
              id: const Uuid().v4(),
              updatedAt: DateTime.now().millisecondsSinceEpoch,
              deviceId: '',
              deleted: false,
              attachmentId: widget.attachment.id,
              bookName: _newRefBook!,
              chapter: chapter,
              verse: verse,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ));
            _verseController.clear();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text('Configure Attachment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Scripture References', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _references.length,
                itemBuilder: (context, index) {
                  final refItem = _references[index];
                  return ListTile(
                    dense: true,
                    title: Text('${refItem.bookName} ${refItem.chapter}${refItem.verse != null ? ':${refItem.verse}' : ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        setState(() {
                          _references.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _allBooks.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _newRefBook = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Book', isDense: true, border: OutlineInputBorder()),
                        onChanged: (val) {
                          final match = _allBooks.firstWhere(
                            (b) => b.toLowerCase() == val.toLowerCase(),
                            orElse: () => '',
                          );
                          _newRefBook = match.isNotEmpty ? match : val;
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _chapterController,
                    decoration: const InputDecoration(labelText: 'Ch', isDense: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _verseController,
                    decoration: const InputDecoration(labelText: 'Vs (e.g. 1-4)', isDense: true, border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addReference,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.local_offer_outlined, size: 18),
                  label: const Text('Manage Tags'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => TagEditorDialog(
                        entityId: widget.attachment.id,
                        entityType: 'media_attachment',
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'title': _titleController.text,
                          'references': _references,
                        });
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}
