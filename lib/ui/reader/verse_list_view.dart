import 'package:flutter/material.dart';
import '../../data/content_store.dart';

class VerseListView extends StatelessWidget {
  final List<Verse> verses;
  final Set<int> selectedVerses;
  final Map<int, String> savedHighlights;
  final ValueChanged<int> onVerseTap;

  const VerseListView({
    super.key,
    required this.verses,
    required this.selectedVerses,
    required this.savedHighlights,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        final isSelected = selectedVerses.contains(verse.verse);
        final highlightHex = savedHighlights[verse.verse];
        final highlightColor = highlightHex != null 
            ? Color(int.parse(highlightHex.replaceFirst('#', '0xFF'))) 
            : Colors.transparent;

        return InkWell(
          onTap: () => onVerseTap(verse.verse),
          child: Container(
            color: isSelected 
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6) 
                : highlightColor.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            margin: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${verse.verse}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    verse.textContent,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
