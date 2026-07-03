import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../data/importer/mybible_verse_parser.dart';
import '../../domain/scripture/verse_share_format.dart';

/// The block of text an [InsertScriptureDialog] resolves to: a reference line
/// (e.g. "John 3:16 (ESV)") and the cleaned verse text. The reference is
/// inserted first so the editor's reference auto-linker turns it into a link.
class InsertScriptureResult {
  final String reference;
  final String body;
  const InsertScriptureResult(this.reference, this.body);

  String get combined => '$reference\n$body';
}

/// Picks a book, chapter, and verse range from the primary Bible version and
/// returns the reference + verse text to insert into a notebook page. Reuses the
/// same content providers and verse-cleaning as the reader.
class InsertScriptureDialog extends ConsumerStatefulWidget {
  const InsertScriptureDialog({super.key});

  static Future<InsertScriptureResult?> show(BuildContext context) {
    return showDialog<InsertScriptureResult>(
      context: context,
      builder: (_) => const InsertScriptureDialog(),
    );
  }

  @override
  ConsumerState<InsertScriptureDialog> createState() =>
      _InsertScriptureDialogState();
}

class _InsertScriptureDialogState extends ConsumerState<InsertScriptureDialog> {
  int? _bookId;
  String? _bookName;
  int _chapter = 1;
  int _startVerse = 1;
  int? _endVerse; // null = single verse

  @override
  Widget build(BuildContext context) {
    final versionId = ref.watch(primaryVersionIdProvider);
    if (versionId == null) {
      return const AlertDialog(
        title: Text('Insert Scripture'),
        content: Text('No Bible version is installed.'),
      );
    }
    final booksAsync = ref.watch(booksForVersionProvider(versionId));

    return AlertDialog(
      title: const Text('Insert Scripture'),
      content: SizedBox(
        width: 360,
        child: booksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (books) {
            if (books.isEmpty) return const Text('No books available.');
            // Default the book on first build.
            _bookId ??= books.first.id;
            _bookName ??= books.first.name;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _bookId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Book'),
                  items: [
                    for (final b in books)
                      DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ],
                  onChanged: (id) {
                    if (id == null) return;
                    setState(() {
                      _bookId = id;
                      _bookName = books.firstWhere((b) => b.id == id).name;
                      _chapter = 1;
                      _startVerse = 1;
                      _endVerse = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildChapterRow(),
                const SizedBox(height: 12),
                _buildVerseRow(),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _insert, child: const Text('Insert')),
      ],
    );
  }

  Widget _buildChapterRow() {
    final bookId = _bookId;
    if (bookId == null) return const SizedBox.shrink();
    final countAsync = ref.watch(chapterCountProvider(bookId));
    return countAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (count) {
        final chapter = _chapter.clamp(1, count);
        return DropdownButtonFormField<int>(
          initialValue: chapter,
          decoration: const InputDecoration(labelText: 'Chapter'),
          items: [
            for (var c = 1; c <= count; c++)
              DropdownMenuItem(value: c, child: Text('$c')),
          ],
          onChanged: (c) {
            if (c == null) return;
            setState(() {
              _chapter = c;
              _startVerse = 1;
              _endVerse = null;
            });
          },
        );
      },
    );
  }

  Widget _buildVerseRow() {
    final bookId = _bookId;
    if (bookId == null) return const SizedBox.shrink();
    final versesAsync = ref.watch(
      versesForChapterProvider((bookId: bookId, chapter: _chapter)),
    );
    return versesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (verses) {
        if (verses.isEmpty) return const Text('No verses in this chapter.');
        final numbers = (verses.map((v) => v.verse).toList()..sort());
        final start = numbers.contains(_startVerse) ? _startVerse : numbers.first;
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: start,
                decoration: const InputDecoration(labelText: 'From verse'),
                items: [
                  for (final n in numbers)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) {
                  if (n == null) return;
                  setState(() {
                    _startVerse = n;
                    if (_endVerse != null && _endVerse! < n) _endVerse = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _endVerse,
                decoration: const InputDecoration(labelText: 'To (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  for (final n in numbers.where((n) => n >= start))
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) => setState(() => _endVerse = n),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _insert() async {
    final bookId = _bookId;
    final bookName = _bookName;
    if (bookId == null || bookName == null) return;
    final verses = await ref.read(
      versesForChapterProvider((bookId: bookId, chapter: _chapter)).future,
    );
    final abbr = ref.read(primaryVersionAbbreviationProvider);
    final end = _endVerse ?? _startVerse;
    final selected =
        verses.where((v) => v.verse >= _startVerse && v.verse <= end).toList()
          ..sort((a, b) => a.verse.compareTo(b.verse));
    if (selected.isEmpty || !mounted) return;

    final reference = VerseShareFormatter.reference(
      bookName: bookName,
      chapter: _chapter,
      verseNumbers: [for (final v in selected) v.verse],
      versionAbbreviation: abbr,
    );
    final body = selected
        .map((v) => mybibleVersePlainText(v.textContent).trim())
        .join(' ');

    Navigator.pop(context, InsertScriptureResult(reference, body));
  }
}
