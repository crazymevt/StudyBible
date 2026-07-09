import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/explorer_providers.dart';
import '../../domain/explorer/explorer_ref.dart';

IconData _iconFor(ExplorerEntityType type) => switch (type) {
      ExplorerEntityType.person => Icons.person_outline,
      ExplorerEntityType.place => Icons.place_outlined,
      ExplorerEntityType.event => Icons.flag_outlined,
      ExplorerEntityType.topic => Icons.topic_outlined,
      ExplorerEntityType.passage => Icons.menu_book_outlined,
      ExplorerEntityType.tag => Icons.label_outline,
      ExplorerEntityType.browse => Icons.list_alt_outlined,
      ExplorerEntityType.prophecy => Icons.auto_awesome_outlined,
    };

/// Picks a person, place, event, or topic from the bundled Explorer datasets
/// to link a notebook page to. Reuses the Explorer's search fan-out
/// (`explorerSearchResultsForProvider`) against a query kept local to this
/// dialog (a plain `setState`, not the Explorer's own home-screen search
/// state) — so opening/closing this dialog never touches shared provider
/// state, and closing it has nothing to restore.
class InsertEntityLinkDialog extends ConsumerStatefulWidget {
  const InsertEntityLinkDialog({super.key});

  static Future<ExplorerRef?> show(BuildContext context) {
    return showDialog<ExplorerRef>(
      context: context,
      builder: (_) => const InsertEntityLinkDialog(),
    );
  }

  @override
  ConsumerState<InsertEntityLinkDialog> createState() =>
      _InsertEntityLinkDialogState();
}

class _InsertEntityLinkDialogState
    extends ConsumerState<InsertEntityLinkDialog> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(ExplorerRef ref) => Navigator.pop(context, ref);

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final resultsAsync = ref.watch(explorerSearchResultsForProvider(query));

    return AlertDialog(
      title: const Text('Link to Explorer'),
      content: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search people, places, events, topics…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: query.length < 2
                  ? const Center(child: Text('Start typing to search.'))
                  : resultsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Search failed: $e')),
                      data: (r) {
                        final items = [
                          ...r.people,
                          ...r.places,
                          ...r.events,
                          ...r.topics,
                        ];
                        if (items.isEmpty) {
                          return const Center(child: Text('No matches.'));
                        }
                        return ListView(
                          children: [
                            for (final item in items)
                              ListTile(
                                leading: Icon(_iconFor(item.ref.type)),
                                title: Text(item.ref.label),
                                subtitle: item.subtitle == null
                                    ? null
                                    : Text(item.subtitle!),
                                onTap: () => _pick(item.ref),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
