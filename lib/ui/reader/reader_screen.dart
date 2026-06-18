import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/sync_service.dart';
import 'verse_list_view.dart';
import 'flowing_paragraph_view.dart';
import 'parallel_view.dart';
import 'verse_action_bar.dart';
import 'study_pane.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _isFlowing = false;

  void _showVersionPicker() async {
    final availableVersions = await ref.read(versionsProvider.future);
    
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(builder: (context, ref, child) {
          final activeVersions = ref.watch(activeVersionsProvider);
          return ListView.builder(
            itemCount: availableVersions.length,
            itemBuilder: (context, index) {
              final version = availableVersions[index];
              final isActive = activeVersions.contains(version.id);
              return CheckboxListTile(
                title: Text('${version.name} (${version.id})'),
                value: isActive,
                onChanged: (checked) {
                  ref.read(activeVersionsProvider.notifier).toggle(version.id);
                },
              );
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final parallelVersesAsync = ref.watch(parallelVersesProvider);
    final bookName = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final savedHighlightsAsync = ref.watch(chapterHighlightsProvider);
    final savedHighlights = savedHighlightsAsync.value ?? <int, String>{};
    final selectedVerses = ref.watch(selectedVersesProvider);
    final activeVersions = ref.watch(activeVersionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$bookName $chapter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Highlights',
            onPressed: () async {
              try {
                await ref.read(syncServiceProvider).sync();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync complete!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sync failed: $e')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Versions',
            onPressed: _showVersionPicker,
          ),
          IconButton(
            icon: Icon(_isFlowing ? Icons.format_list_numbered : Icons.notes),
            tooltip: 'Toggle View Mode',
            onPressed: () {
              setState(() {
                _isFlowing = !_isFlowing;
              });
            },
          ),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu_book),
                tooltip: 'Study Pane',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            }
          ),
        ],
      ),
      endDrawer: const StudyPane(),
      body: parallelVersesAsync.when(
        data: (versesMap) {
          if (versesMap.isEmpty) {
            return const Center(child: Text('No verses found.'));
          }

          if (activeVersions.length == 1) {
            final versionId = activeVersions.first;
            final verses = versesMap[versionId] ?? [];
            return _isFlowing
                ? FlowingParagraphView(
                    verses: verses,
                    selectedVerses: selectedVerses,
                    savedHighlights: savedHighlights,
                    onVerseTap: (verseId) => ref.read(selectedVersesProvider.notifier).toggle(verseId),
                  )
                : VerseListView(
                    verses: verses,
                    selectedVerses: selectedVerses,
                    savedHighlights: savedHighlights,
                    onVerseTap: (verseId) => ref.read(selectedVersesProvider.notifier).toggle(verseId),
                  );
          } else {
            return ParallelView(
              versesMap: versesMap,
              isFlowing: _isFlowing,
              selectedVerses: selectedVerses,
              savedHighlights: savedHighlights,
              onVerseTap: (verseId) => ref.read(selectedVersesProvider.notifier).toggle(verseId),
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: selectedVerses.isNotEmpty ? const VerseActionBar() : null,
    );
  }
}
