import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/reference_providers.dart';
import '../../domain/reference/king_reign.dart';
import '../../domain/reference/measure.dart';
import '../common/breakpoints.dart';

/// A reference citation, e.g. "Micah 5:2", "Isaiah 53:5-6", or a whole
/// chapter "Leviticus 16". Chapter-only citations default to verse 1,
/// matching the convention the Feasts/Prophecies/curated-topic passages use.
final _passageExp = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

void _goToPassage(BuildContext context, WidgetRef ref, String passage) {
  final match = _passageExp.firstMatch(passage.trim());
  if (match == null) return;
  final bookName = match.group(1)!.trim();
  final chapter = int.parse(match.group(2)!);
  final verse = int.tryParse(match.group(3) ?? '') ?? 1;

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

/// Browsable reference tables: Kings & Reigns today, more datasets as tabs
/// in later phases. Each tab is a self-contained searchable list grouped by
/// category, opening to a detail view with tappable passage links.
class ReferencePanel extends ConsumerWidget {
  const ReferencePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reference',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Kings & Reigns'),
                      Tab(text: 'Measures & Money'),
                    ],
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [_KingsReignsTab(), _MeasuresMoneyTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tab's own search field + back button, shown above its list/detail body.
class _TabSearchHeader extends StatelessWidget {
  const _TabSearchHeader({
    required this.showBack,
    required this.onBack,
    required this.hintText,
    required this.controller,
    required this.onChanged,
  });

  final bool showBack;
  final VoidCallback onBack;
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: showBack
          ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to results',
                  visualDensity: VisualDensity.compact,
                  onPressed: onBack,
                ),
                Text('Back to results', style: Theme.of(context).textTheme.bodyMedium),
              ],
            )
          : TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: onChanged,
            ),
    );
  }
}

class _KingsReignsTab extends ConsumerStatefulWidget {
  const _KingsReignsTab();

  @override
  ConsumerState<_KingsReignsTab> createState() => _KingsReignsTabState();
}

class _KingsReignsTabState extends ConsumerState<_KingsReignsTab> {
  final _controller = TextEditingController();
  String _query = '';
  String? _selectedId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _selectedId;
    final all = ref.watch(kingReignsProvider);
    final selected =
        selectedId == null ? null : all.firstWhere((k) => k.id == selectedId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabSearchHeader(
          showBack: selected != null,
          onBack: () => setState(() => _selectedId = null),
          hintText: 'Search kings & reigns (e.g. Hezekiah, Babylon)…',
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
        ),
        const Divider(height: 1),
        Expanded(
          child: selected != null
              ? _KingReignDetailView(
                  king: selected,
                  onPassageTap: (p) => _goToPassage(context, ref, p),
                )
              : _KingReignList(
                  query: _query,
                  onSelect: (id) => setState(() => _selectedId = id),
                ),
        ),
      ],
    );
  }
}

class _KingReignList extends ConsumerWidget {
  const _KingReignList({required this.query, required this.onSelect});

  final String query;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(kingReignsProvider);
    final q = query.trim().toLowerCase();
    bool matches(KingReign k) =>
        q.isEmpty ||
        k.name.toLowerCase().contains(q) ||
        k.title.toLowerCase().contains(q) ||
        k.notes.toLowerCase().contains(q) ||
        k.realm.label.toLowerCase().contains(q) ||
        k.citations.any((r) => r.toLowerCase().contains(q));

    final filtered = all.where(matches).toList();
    if (filtered.isEmpty) {
      return Center(child: Text('No kings or rulers matching "$query".'));
    }

    // Group under realm headers in enum order (the kingdoms as they
    // actually succeed one another), independent of the data file's order.
    final rows = <Widget>[];
    for (final realm in Realm.values) {
      final items = filtered.where((k) => k.realm == realm).toList()
        ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
      if (items.isEmpty) continue;
      rows.add(_SectionHeader(label: realm.label));
      for (final k in items) {
        rows.add(
          ListTile(
            dense: true,
            title: Text('${k.name} — ${k.title}'),
            subtitle: Text(
              k.reignSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => onSelect(k.id),
          ),
        );
      }
    }

    return ListView(children: rows);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

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

class _KingReignDetailView extends StatelessWidget {
  const _KingReignDetailView({required this.king, required this.onPassageTap});

  final KingReign king;
  final void Function(String passage) onPassageTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          king.realm.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${king.name} — ${king.title}',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(king.reignSummary, style: Theme.of(context).textTheme.bodyMedium),
        if (king.verdict != null) ...[
          const SizedBox(height: 8),
          _VerdictChip(verdict: king.verdict!),
        ],
        const SizedBox(height: 16),
        _NotesSection(notes: king.notes, citations: king.citations, onPassageTap: onPassageTap),
      ],
    );
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.verdict});

  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color color = switch (verdict) {
      Verdict.good => Colors.green,
      Verdict.bad => scheme.error,
      Verdict.mixed => Colors.orange,
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      label: Text(
        verdict.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _MeasuresMoneyTab extends ConsumerStatefulWidget {
  const _MeasuresMoneyTab();

  @override
  ConsumerState<_MeasuresMoneyTab> createState() => _MeasuresMoneyTabState();
}

class _MeasuresMoneyTabState extends ConsumerState<_MeasuresMoneyTab> {
  final _controller = TextEditingController();
  String _query = '';
  String? _selectedId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _selectedId;
    final all = ref.watch(measuresProvider);
    final selected =
        selectedId == null ? null : all.firstWhere((m) => m.id == selectedId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabSearchHeader(
          showBack: selected != null,
          onBack: () => setState(() => _selectedId = null),
          hintText: 'Search measures & money (e.g. cubit, denarius)…',
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
        ),
        const Divider(height: 1),
        Expanded(
          child: selected != null
              ? _MeasureDetailView(
                  measure: selected,
                  onPassageTap: (p) => _goToPassage(context, ref, p),
                )
              : _MeasureList(
                  query: _query,
                  onSelect: (id) => setState(() => _selectedId = id),
                ),
        ),
      ],
    );
  }
}

class _MeasureList extends ConsumerWidget {
  const _MeasureList({required this.query, required this.onSelect});

  final String query;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(measuresProvider);
    final q = query.trim().toLowerCase();
    bool matches(Measure m) =>
        q.isEmpty ||
        m.name.toLowerCase().contains(q) ||
        m.modernEquivalent.toLowerCase().contains(q) ||
        m.notes.toLowerCase().contains(q) ||
        m.category.label.toLowerCase().contains(q) ||
        m.citations.any((r) => r.toLowerCase().contains(q));

    final filtered = all.where(matches).toList();
    if (filtered.isEmpty) {
      return Center(child: Text('No measures or money matching "$query".'));
    }

    final rows = <Widget>[];
    for (final category in MeasureCategory.values) {
      final items = filtered.where((m) => m.category == category).toList();
      if (items.isEmpty) continue;
      rows.add(_SectionHeader(label: category.label));
      for (final m in items) {
        rows.add(
          ListTile(
            dense: true,
            title: Text(m.name),
            subtitle: Text(
              m.modernEquivalent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => onSelect(m.id),
          ),
        );
      }
    }

    return ListView(children: rows);
  }
}

class _MeasureDetailView extends StatelessWidget {
  const _MeasureDetailView({required this.measure, required this.onPassageTap});

  final Measure measure;
  final void Function(String passage) onPassageTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
          measure.name,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(measure.modernEquivalent, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        _NotesSection(notes: measure.notes, citations: measure.citations, onPassageTap: onPassageTap),
      ],
    );
  }
}

/// Shared "Notes" section + tappable passage chips, used by both tabs'
/// detail views.
class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.notes,
    required this.citations,
    required this.onPassageTap,
  });

  final String notes;
  final List<String> citations;
  final void Function(String passage) onPassageTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              'Notes',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        if (citations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: citations
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
