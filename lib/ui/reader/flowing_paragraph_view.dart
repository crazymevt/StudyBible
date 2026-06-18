import 'package:flutter/material.dart';
import '../../data/content_store.dart';

class FlowingParagraphView extends StatelessWidget {
  final List<Verse> verses;

  const FlowingParagraphView({super.key, required this.verses});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
      child: Text.rich(
        TextSpan(
          children: verses.map((verse) {
            return TextSpan(
              children: [
                TextSpan(
                  text: '${verse.verse} ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.superscripts()],
                      ),
                ),
                TextSpan(
                  text: '${verse.textContent} ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                      ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
