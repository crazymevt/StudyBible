import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_state.dart';
import 'common/tool_groups.dart';

/// The desktop tools rail: the reader's side tools.
/// Shows pinned favorites with an edit button.
class GroupedToolRail extends ConsumerWidget {
  const GroupedToolRail({super.key});

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return const _EditFavoritesDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final pinnedTools = ref.watch(pinnedToolsProvider);

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          const SizedBox(height: 6),
          for (final tool in pinnedTools)
            if (allToolsMap.containsKey(tool))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _RailItem(
                  item: allToolsMap[tool]!,
                  selected: activeTool == tool,
                ),
              ),
          const SizedBox(height: 8),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ref),
              tooltip: 'Edit Favorites',
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _EditFavoritesDialog extends ConsumerStatefulWidget {
  const _EditFavoritesDialog();

  @override
  ConsumerState<_EditFavoritesDialog> createState() =>
      _EditFavoritesDialogState();
}

class _EditFavoritesDialogState extends ConsumerState<_EditFavoritesDialog> {
  late List<ActiveTool> _pinned;

  @override
  void initState() {
    super.initState();
    _pinned = List.of(ref.read(pinnedToolsProvider));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Favorites'),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final group in toolGroups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0),
                  child: Text(
                    group.label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                for (final item in group.items)
                  CheckboxListTile(
                    title: Text(item.label),
                    secondary: Icon(item.icon),
                    value: _pinned.contains(item.tool),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _pinned.add(item.tool);
                        } else {
                          _pinned.remove(item.tool);
                        }
                      });
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(pinnedToolsProvider.notifier).setPinnedTools(_pinned);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _RailItem extends ConsumerWidget {
  final ToolItem item;
  final bool selected;

  const _RailItem({required this.item, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconColor = selected
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: selected
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onSurfaceVariant,
      fontWeight: selected ? FontWeight.w600 : null,
      height: 1.1,
    );

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(activeToolProvider.notifier).setTool(item.tool),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.secondaryContainer : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: iconColor),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  item.railLabel,
                  style: labelStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
