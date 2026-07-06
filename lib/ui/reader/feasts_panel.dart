import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/feast_providers.dart';
import '../../app/reader_state.dart';
import '../../domain/feasts/feast.dart';
import '../../domain/feasts/feast_data.dart';
import '../common/breakpoints.dart';

final _dateFormat = DateFormat('MMM d, yyyy');

/// A feast's Torah/Scripture citation, e.g. "Leviticus 23:5" or "John 10:22-23".
/// Chapter-only citations (e.g. "Leviticus 16") default to verse 1, matching
/// the convention used elsewhere for whole-chapter references.
final _passageExp = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

enum _FeastSort { alphabetical, date }

/// Biblical feasts and appointed times: a searchable list, plus each feast's
/// description, passages, and this year's (and the next few years') dates.
class FeastsPanel extends ConsumerStatefulWidget {
  const FeastsPanel({super.key});

  @override
  ConsumerState<FeastsPanel> createState() => _FeastsPanelState();
}

class _FeastsPanelState extends ConsumerState<FeastsPanel> {
  final _controller = TextEditingController();
  String _query = '';
  String? _selectedFeastId;
  _FeastSort _sort = _FeastSort.alphabetical;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPassage(String passage) {
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

  @override
  Widget build(BuildContext context) {
    final selectedId = _selectedFeastId;

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
                        if (selectedId != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back to results',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _selectedFeastId = null),
                          ),
                        Text(
                          'Feasts',
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
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search feasts (e.g. Passover, Tabernacles)…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _selectedFeastId = null;
                  }),
                ),
                if (selectedId == null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<_FeastSort>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: _FeastSort.alphabetical,
                          icon: Icon(Icons.sort_by_alpha),
                          label: Text('A–Z'),
                        ),
                        ButtonSegment(
                          value: _FeastSort.date,
                          icon: Icon(Icons.event),
                          label: Text('Date'),
                        ),
                      ],
                      selected: {_sort},
                      onSelectionChanged: (s) =>
                          setState(() => _sort = s.first),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedId != null
                ? _FeastDetailView(feastId: selectedId, onPassageTap: _goToPassage)
                : _FeastList(
                    query: _query,
                    sort: _sort,
                    onSelect: (id) => setState(() => _selectedFeastId = id),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeastList extends ConsumerWidget {
  const _FeastList({required this.query, required this.sort, required this.onSelect});

  final String query;
  final _FeastSort sort;
  final void Function(String feastId) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFeasts = ref.watch(feastsProvider);
    final q = query.trim().toLowerCase();
    final filtered = (q.isEmpty
            ? allFeasts
            : allFeasts.where((f) => f.name.toLowerCase().contains(q)))
        .toList();

    switch (sort) {
      case _FeastSort.alphabetical:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case _FeastSort.date:
        // Feasts with no upcoming occurrence (shouldn't happen within the
        // generated 30-year range) sort last rather than first.
        filtered.sort((a, b) {
          final aDate = _nextOccurrence(a.id)?.start;
          final bDate = _nextOccurrence(b.id)?.start;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
    }

    if (filtered.isEmpty) {
      return Center(child: Text('No feasts matching "$query".'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final feast = filtered[i];
        final next = _nextOccurrence(feast.id);
        return ListTile(
          dense: true,
          title: Text(feast.name),
          subtitle: next == null ? null : Text('Next: ${_formatRange(next)}'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => onSelect(feast.id),
        );
      },
    );
  }
}

class _FeastDetailView extends ConsumerWidget {
  const _FeastDetailView({required this.feastId, required this.onPassageTap});

  final String feastId;
  final void Function(String passage) onPassageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feast =
        ref.watch(feastsProvider).firstWhere((f) => f.id == feastId);
    final scheme = Theme.of(context).colorScheme;
    final upcoming = _upcomingOccurrences(feastId, limit: 5);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            feast.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
          ),
        ),
        Text(feast.description, style: Theme.of(context).textTheme.bodyMedium),
        if (feast.passages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: feast.passages
                  .map((p) => ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(p),
                        onPressed: () => onPassageTap(p),
                      ))
                  .toList(),
            ),
          ),
        if (upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6),
            child: Text(
              'Upcoming dates',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          for (final o in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(_formatRange(o)),
            ),
        ],
      ],
    );
  }
}

FeastOccurrence? _nextOccurrence(String feastId) =>
    _upcomingOccurrences(feastId, limit: 1).firstOrNull;

List<FeastOccurrence> _upcomingOccurrences(String feastId, {required int limit}) {
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  final matches = feastOccurrences.where((o) => o.feastId == feastId).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final upcoming = matches.where((o) => !o.end.isBefore(todayMidnight)).toList();
  return upcoming.take(limit).toList();
}

String _formatRange(FeastOccurrence o) {
  if (o.start == o.end) return _dateFormat.format(o.start);
  return '${_dateFormat.format(o.start)} – ${_dateFormat.format(o.end)}';
}
