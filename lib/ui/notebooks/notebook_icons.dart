import 'package:flutter/material.dart';

/// Curated cover icons for notebooks. Each icon is stored by a stable string
/// [key] (persisted in `Notebooks.iconKey`), not by its raw `IconData`
/// codePoint — const `IconData`s survive Flutter's icon tree-shaking, whereas a
/// codePoint reconstructed at runtime does not.
class NotebookIconChoice {
  final String key;
  final String label;
  final IconData icon;
  const NotebookIconChoice(this.key, this.label, this.icon);
}

const List<NotebookIconChoice> kNotebookIcons = [
  NotebookIconChoice('book', 'Book', Icons.menu_book),
  NotebookIconChoice('bookmark', 'Bookmark', Icons.bookmark),
  NotebookIconChoice('note', 'Notes', Icons.edit_note),
  NotebookIconChoice('lightbulb', 'Idea', Icons.lightbulb_outline),
  NotebookIconChoice('star', 'Star', Icons.star_outline),
  NotebookIconChoice('favorite', 'Heart', Icons.favorite_border),
  NotebookIconChoice('church', 'Church', Icons.church_outlined),
  NotebookIconChoice('people', 'People', Icons.people_outline),
  NotebookIconChoice('school', 'Study', Icons.school_outlined),
  NotebookIconChoice('flag', 'Flag', Icons.flag_outlined),
  NotebookIconChoice('label', 'Tag', Icons.label_outline),
  NotebookIconChoice('folder', 'Folder', Icons.folder_outlined),
];

const IconData kDefaultNotebookIcon = Icons.menu_book;

/// Resolve a stored [iconKey] to its `IconData`, falling back to the default
/// notebook icon for null/unknown keys.
IconData notebookIconFromKey(String? iconKey) {
  if (iconKey == null) return kDefaultNotebookIcon;
  for (final choice in kNotebookIcons) {
    if (choice.key == iconKey) return choice.icon;
  }
  return kDefaultNotebookIcon;
}

/// A wrap of tappable icon choices for the notebook cover picker. [selectedKey]
/// is highlighted; tapping calls [onSelected] with the chosen key.
class NotebookIconPicker extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String?> onSelected;

  const NotebookIconPicker({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final choice in kNotebookIcons)
          Tooltip(
            message: choice.label,
            child: InkWell(
              onTap: () => onSelected(choice.key),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedKey == choice.key
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  border: Border.all(
                    color: selectedKey == choice.key
                        ? scheme.primary
                        : scheme.outlineVariant,
                    width: selectedKey == choice.key ? 2 : 1,
                  ),
                ),
                child: Icon(
                  choice.icon,
                  size: 20,
                  color: selectedKey == choice.key
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
