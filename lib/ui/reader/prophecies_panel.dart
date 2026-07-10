import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/prophecy_providers.dart';
import '../../app/reader_state.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../../domain/prophecy/prophecy.dart';
import '../../domain/scripture/passage_citation.dart';
import '../common/breakpoints.dart';
import '../explorer/explorer_screen.dart';

/// Old Testament prophecies paired with their New Testament fulfillment: a
/// searchable list grouped by theme, each opening to the foretelling and its
/// fulfillment with tappable passage links.
class PropheciesPanel extends ConsumerStatefulWidget {
  const PropheciesPanel({super.key});

  @override
  ConsumerState<PropheciesPanel> createState() => _PropheciesPanelState();
}

class _PropheciesPanelState extends ConsumerState<PropheciesPanel> {
  final _controller = TextEditingController();
  String _query = '';
  String? _selectedId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPassage(String passage) {
    final citation = PassageCitation.tryParse(passage);
    if (citation == null) return;
    final bookName = citation.book;
    final chapter = citation.chapter;
    final verse = citation.verse ?? 1;

    ref.read(selectedBookNameProvider.notifier).set(bookName);
    ref.read(selectedChapterProvider.notifier).set(chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(verse);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(selectedVersesProvider.notifier).toggle(verse);
    ref.read(navigationControllerProvider).recordHistory(verse: verse);

    if (MediaQuery.sizeOf(context).width <= Breakpoints.compact) {
      ref.read(activeToolProvider.notifier).close();
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  /// Open this prophecy's full Explorer page. Prophecies are addressed in the
  /// Explorer by their index in the (const) list.
  void _openInExplorer(Prophecy prophecy) {
    final index = ref.read(propheciesProvider).indexOf(prophecy);
    if (index < 0) return;
    openInFreshExplorer(
      context,
      ref,
      ExplorerRef.prophecy(index, prophecy.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _selectedId;
    final all = ref.watch(propheciesProvider);
    final selected = selectedId == null
        ? null
        : all.firstWhere((p) => p.id == selectedId);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (selected != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back to results',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _selectedId = null),
                          ),
                        Text(
                          'Prophecies',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: () {
                        ref.read(activeToolProvider.notifier).close();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
                if (selected == null) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search prophecies (e.g. Bethlehem, pierced)…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selected != null
                ? _ProphecyDetailView(
                    prophecy: selected,
                    onPassageTap: _goToPassage,
                    onOpenInExplorer: () => _openInExplorer(selected),
                  )
                : _ProphecyList(
                    query: _query,
                    onSelect: (id) => setState(() => _selectedId = id),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProphecyList extends ConsumerWidget {
  const _ProphecyList({required this.query, required this.onSelect});

  final String query;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(propheciesProvider);
    final q = query.trim().toLowerCase();
    bool matches(Prophecy p) =>
        q.isEmpty ||
        p.title.toLowerCase().contains(q) ||
        p.prophecyText.toLowerCase().contains(q) ||
        p.fulfillmentText.toLowerCase().contains(q) ||
        p.prophecy.any((r) => r.toLowerCase().contains(q)) ||
        p.fulfillment.any((r) => r.toLowerCase().contains(q));

    final filtered = all.where(matches).toList();
    if (filtered.isEmpty) {
      return Center(child: Text('No prophecies matching "$query".'));
    }

    // Group under category headers in enum order (the arc of redemptive
    // history), independent of the data file's ordering.
    final rows = <Widget>[];
    for (final category in ProphecyCategory.values) {
      final items = filtered.where((p) => p.category == category).toList();
      if (items.isEmpty) continue;
      rows.add(_CategoryHeader(label: category.label));
      for (final p in items) {
        rows.add(
          ListTile(
            dense: true,
            title: Text(p.title),
            subtitle: Text(
              '${p.prophecy.join(', ')}  →  ${p.fulfillment.join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => onSelect(p.id),
          ),
        );
      }
    }

    return ListView(children: rows);
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.primary,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _ProphecyDetailView extends StatelessWidget {
  const _ProphecyDetailView({
    required this.prophecy,
    required this.onPassageTap,
    required this.onOpenInExplorer,
  });

  final Prophecy prophecy;
  final void Function(String passage) onPassageTap;
  final VoidCallback onOpenInExplorer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOtFulfillment =
        prophecy.category == ProphecyCategory.oldTestament;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          prophecy.category.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                prophecy.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.explore_outlined),
              tooltip: 'Open in Explorer',
              visualDensity: VisualDensity.compact,
              onPressed: onOpenInExplorer,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          heading: 'The Prophecy',
          icon: Icons.auto_stories_outlined,
          body: prophecy.prophecyText,
          passages: prophecy.prophecy,
          onPassageTap: onPassageTap,
        ),
        const SizedBox(height: 20),
        _Section(
          heading: isOtFulfillment ? 'Fulfilled' : 'The Fulfillment',
          icon: Icons.check_circle_outline,
          body: prophecy.fulfillmentText,
          passages: prophecy.fulfillment,
          onPassageTap: onPassageTap,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.heading,
    required this.icon,
    required this.body,
    required this.passages,
    required this.onPassageTap,
  });

  final String heading;
  final IconData icon;
  final String body;
  final List<String> passages;
  final void Function(String passage) onPassageTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              heading,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        if (passages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: passages
                  .map((p) => ActionChip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.menu_book, size: 16),
                        label: Text(p),
                        onPressed: () => onPassageTap(p),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
