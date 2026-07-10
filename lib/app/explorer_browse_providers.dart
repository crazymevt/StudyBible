part of 'explorer_providers.dart';

// --- Browsable indexes (the pages behind the home page's dataset chips) ---

/// One row of a browsable index over an entity kind.
class ExplorerIndexEntry {
  final ExplorerRef ref;
  final String? subtitle;

  /// Rank for the index page's "most mentioned" sort (verse counts); 0 where
  /// that sort doesn't apply (topics, events — events rank chronologically
  /// by their position in the returned list instead).
  final int weight;
  const ExplorerIndexEntry(this.ref, {this.subtitle, this.weight = 0});
}

String _countLabel(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

/// Family key for [explorerIndexProvider]: the entity kind to list and — for
/// topics — optionally one curated category ('feast' or 'story') instead of
/// the plain Nave's entries.
typedef ExplorerIndexSpec = ({ExplorerEntityType kind, String? category});

/// Every entity of one kind, as index rows. People, places, and topics come
/// back A-Z; events come back in timeline order and feasts in Leviticus 23
/// calendar order (their natural browse orders).
final explorerIndexProvider =
    FutureProvider.family<List<ExplorerIndexEntry>, ExplorerIndexSpec>((
      ref,
      spec,
    ) async {
      await ref.watch(explorerReadyProvider.future);
      final store = ref.watch(contentStoreProvider);
      switch (spec.kind) {
        case ExplorerEntityType.person:
          final rows = await (store.select(
            store.biblePeople,
          )..orderBy([(p) => OrderingTerm.asc(p.displayTitle)])).get();
          return [
            for (final p in rows)
              ExplorerIndexEntry(
                ExplorerRef.person(p.id, p.displayTitle),
                subtitle:
                    _countLabel(p.verseCount, 'verse') +
                    (p.alsoCalled == null ? '' : ' · also ${p.alsoCalled}'),
                weight: p.verseCount,
              ),
          ];
        case ExplorerEntityType.place:
          final rows = await store
              .customSelect(
                'SELECT p.id AS id, p.name AS name, COUNT(pv.id) AS refs '
                'FROM places p LEFT JOIN place_verses pv ON pv.place_id = p.id '
                'GROUP BY p.id, p.name ORDER BY p.name',
              )
              .get();
          return [
            for (final r in rows)
              ExplorerIndexEntry(
                ExplorerRef.place(r.read<int>('id'), r.read<String>('name')),
                subtitle: _countLabel(r.read<int>('refs'), 'verse'),
                weight: r.read<int>('refs'),
              ),
          ];
        case ExplorerEntityType.event:
          final rows =
              await (store.select(store.timelineEvents)..orderBy([
                    (e) => OrderingTerm(expression: e.sortKey.isNull()),
                    (e) => OrderingTerm.asc(e.sortKey),
                    (e) => OrderingTerm.asc(e.title),
                  ]))
                  .get();
          return [
            for (final e in rows)
              ExplorerIndexEntry(
                ExplorerRef.event(e.id, e.title),
                subtitle: e.startYear == null ? null : _isoYear(e.startYear!),
              ),
          ];
        case ExplorerEntityType.topic:
          // Curated feasts/stories have their own indexes, so the plain Topics
          // index is Nave's Topical Bible alone.
          final query = store.select(store.topics)
            ..where(
              (t) => spec.category == null
                  ? t.category.isNull()
                  : t.category.equals(spec.category!),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.name)]);
          final rows = await query.get();
          if (spec.category == 'feast') {
            // Re-sort into the Leviticus 23 calendar order (`feasts`, the domain
            // list) — "Day of Atonement" first reads as nonsense next to the
            // actual liturgical sequence.
            final order = [for (final f in feasts) f.name.toUpperCase()];
            rows.sort(
              (a, b) => order.indexOf(a.name).compareTo(order.indexOf(b.name)),
            );
          } else if (spec.category == 'tribe') {
            // Birth order (Genesis 29-30, 35), not alphabetical.
            rows.sort(
              (a, b) => tribeOrder
                  .indexOf(a.name)
                  .compareTo(tribeOrder.indexOf(b.name)),
            );
          } else if (spec.category == 'apostle') {
            // The Matthew 10:2-4 list order, not alphabetical.
            rows.sort(
              (a, b) => apostleOrder
                  .indexOf(a.name)
                  .compareTo(apostleOrder.indexOf(b.name)),
            );
          } else if (spec.category == 'judge') {
            // Chronological, per the book of Judges (and 1 Samuel for Samuel).
            rows.sort(
              (a, b) => judgeOrder
                  .indexOf(a.name)
                  .compareTo(judgeOrder.indexOf(b.name)),
            );
          } else if (spec.category == 'prophet') {
            // Canonical order (majors, then minors), not alphabetical.
            rows.sort(
              (a, b) => prophetOrder
                  .indexOf(a.name)
                  .compareTo(prophetOrder.indexOf(b.name)),
            );
          }
          return [
            for (final t in rows)
              ExplorerIndexEntry(ExplorerRef.topic(t.id, t.name)),
          ];
        case ExplorerEntityType.prophecy:
          // Pure-Dart dataset, addressed by list index; the index page re-sorts
          // A-Z, so file order here doesn't matter.
          return [
            for (var i = 0; i < prophecies.length; i++)
              ExplorerIndexEntry(
                ExplorerRef.prophecy(i, prophecies[i].title),
                subtitle: prophecies[i].category.label,
              ),
          ];
        case ExplorerEntityType.passage:
        case ExplorerEntityType.tag:
        case ExplorerEntityType.browse:
          throw ArgumentError('no index for ${spec.kind.name}');
      }
    });
