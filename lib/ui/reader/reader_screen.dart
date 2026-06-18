import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import 'verse_list_view.dart';
import 'flowing_paragraph_view.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _isFlowing = false;

  @override
  Widget build(BuildContext context) {
    // For our sample DB, bookId is 1 (John)
    final versesAsync = ref.watch(versesForChapterProvider((bookId: 1, chapter: 1)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('John 1'),
        actions: [
          IconButton(
            icon: Icon(_isFlowing ? Icons.format_list_numbered : Icons.notes),
            tooltip: 'Toggle View Mode',
            onPressed: () {
              setState(() {
                _isFlowing = !_isFlowing;
              });
            },
          ),
        ],
      ),
      body: versesAsync.when(
        data: (verses) {
          if (verses.isEmpty) {
            return const Center(child: Text('No verses found.'));
          }
          return _isFlowing
              ? FlowingParagraphView(verses: verses)
              : VerseListView(verses: verses);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
