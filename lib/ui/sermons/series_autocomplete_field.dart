import 'package:flutter/material.dart';

/// A series text field that suggests existing series names as the user types,
/// so one series doesn't splinter into several spellings.
///
/// Wraps [RawAutocomplete] around a caller-owned controller and focus node so
/// callers keep their save-on-change listeners; selecting a suggestion writes
/// it to the controller like any other edit.
class SeriesAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Candidate series names (already deduplicated and sorted).
  final List<String> options;
  final bool readOnly;
  final InputDecoration decoration;

  /// Called when the user submits the field (Enter). Runs after the
  /// autocomplete has had its chance to commit a highlighted suggestion, so
  /// the controller already holds the final text. Null (the default) leaves
  /// Enter doing nothing beyond that, which is what the always-visible fields
  /// in the editor and the new-sermon dialog want; a dialog whose whole job is
  /// this one field passes its confirm action here.
  final VoidCallback? onSubmitted;

  const SeriesAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.options,
    this.readOnly = false,
    this.decoration = const InputDecoration(labelText: 'Series'),
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) {
        if (readOnly) return const Iterable<String>.empty();
        final query = value.text.trim().toLowerCase();
        // An exact match is excluded so the popup closes once a suggestion is
        // picked (or the full name typed) instead of lingering with one entry.
        return options.where((o) {
          final lower = o.toLowerCase();
          return lower != query && lower.contains(query);
        });
      },
      fieldViewBuilder:
          (context, textController, fieldFocusNode, onFieldSubmitted) {
            return TextField(
              controller: textController,
              focusNode: fieldFocusNode,
              readOnly: readOnly,
              decoration: decoration,
              onSubmitted: (_) {
                onFieldSubmitted();
                onSubmitted?.call();
              },
            );
          },
      optionsViewBuilder: (context, onSelected, opts) {
        final highlighted = AutocompleteHighlightedOption.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opts.length,
                itemBuilder: (context, index) {
                  final option = opts.elementAt(index);
                  return ListTile(
                    dense: true,
                    selected: index == highlighted,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
