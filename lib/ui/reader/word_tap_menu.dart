import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../domain/reference/measure.dart';
import '../../domain/reference/measure_conversion.dart';
import '../../domain/reference/measure_matcher.dart';
import '../common/breakpoints.dart';
import 'dictionary_panel.dart';

/// The long-press/right-click menu for a tapped verse word — shared by every
/// verse-rendering view (list, flowing paragraph, parallel) so the dictionary
/// lookup and measure-conversion behavior can't drift between copies.
///
/// [precedingWords] and [followingWords] are the lowercased word tokens
/// already seen earlier/later in the same verse (oldest-to-newest), used to
/// find a quantity phrase next to a unit-of-measure word (e.g. the "six" in
/// "six cubits") regardless of which of those words was actually tapped.
Future<void> showWordTapMenu({
  required BuildContext context,
  required WidgetRef ref,
  required String word,
  required Offset position,
  required List<String> precedingWords,
  required List<String> followingWords,
}) async {
  final resolved = resolveMeasureNearWord(word, precedingWords, followingWords);

  final result = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: [
      PopupMenuItem(
        value: 'dictionary',
        child: Text('Look up "$word" in Dictionary'),
      ),
      if (resolved != null)
        PopupMenuItem(
          value: 'measure',
          child: Text(
            'Convert "${_quantityPhrase(resolved.quantity, resolved.unitWord)}" to US units',
          ),
        ),
    ],
  );

  if (!context.mounted) return;

  if (result == 'dictionary') {
    ref.read(dictionarySearchQueryProvider.notifier).setQuery(word, exact: true);
    if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
      ref.read(activeToolProvider.notifier).openTool(ActiveTool.dictionary);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.sizeOf(context).height * 0.8,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const DictionaryPanel(),
        ),
      );
    }
  } else if (result == 'measure' && resolved != null) {
    showDialog<void>(
      context: context,
      builder: (_) => _MeasureConversionDialog(measure: resolved.measure, quantity: resolved.quantity ?? 1),
    );
  }
}

String _quantityPhrase(num? quantity, String word) {
  if (quantity == null) return word;
  final n = quantity == quantity.roundToDouble() ? quantity.round().toString() : quantity.toString();
  return '$n $word';
}

class _MeasureConversionDialog extends StatelessWidget {
  const _MeasureConversionDialog({required this.measure, required this.quantity});

  final Measure measure;
  final num quantity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quantityLabel = quantity == quantity.roundToDouble() ? quantity.round().toString() : quantity.toString();
    final ambiguityNote = ambiguityNoteFor(measure);

    return AlertDialog(
      title: Text('$quantityLabel ${measure.name}${quantity == 1 ? '' : 's'}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            measure.category.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ${formatMeasureConversion(measure, quantity)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(measure.notes, style: Theme.of(context).textTheme.bodyMedium),
          if (measure.category == MeasureCategory.money) ...[
            const SizedBox(height: 12),
            Text(
              'The dollar figure is a rough estimate only — ancient purchasing power doesn\'t map cleanly onto modern prices.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (ambiguityNote != null) ...[
            const SizedBox(height: 8),
            Text(
              ambiguityNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
