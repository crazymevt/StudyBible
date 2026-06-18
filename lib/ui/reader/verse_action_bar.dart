import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import 'note_editor.dart';

class VerseActionBar extends ConsumerWidget {
  const VerseActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVerses = ref.watch(selectedVersesProvider);
    if (selectedVerses.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 8.0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedVerses.length} verse${selectedVerses.length > 1 ? 's' : ''} selected',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ref.read(selectedVersesProvider.notifier).clear(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const _ColorSwatch(color: Colors.yellowAccent, hex: '#FFFF00'),
                  const _ColorSwatch(color: Colors.greenAccent, hex: '#00FF00'),
                  const _ColorSwatch(color: Colors.lightBlueAccent, hex: '#00FFFF'),
                  const _ColorSwatch(color: Colors.pinkAccent, hex: '#FF00FF'),
                  Container(width: 1, height: 24, color: Colors.black26),
                  IconButton(
                    icon: const Icon(Icons.note_add),
                    tooltip: 'Add Note',
                    onPressed: () {
                      final selected = ref.read(selectedVersesProvider);
                      final verse = selected.isNotEmpty ? selected.first : null;
                      showDialog(
                        context: context,
                        builder: (_) => NoteEditorDialog(verse: verse),
                      );
                      ref.read(selectedVersesProvider.notifier).clear();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add),
                    tooltip: 'Bookmark',
                    onPressed: () async {
                      final selected = ref.read(selectedVersesProvider);
                      if (selected.isEmpty) return;
                      for (final verse in selected) {
                        await ref.read(bookmarkActionProvider).saveBookmark(verse, 'Important');
                      }
                      ref.read(selectedVersesProvider.notifier).clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved bookmark')));
                      }
                    },
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

class _ColorSwatch extends ConsumerWidget {
  final Color color;
  final String hex;

  const _ColorSwatch({required this.color, required this.hex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final selected = ref.read(selectedVersesProvider);
        for (final verse in selected) {
          await ref.read(highlightActionProvider).applyHighlight(verse, hex);
        }
        ref.read(selectedVersesProvider.notifier).clear();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }
}
