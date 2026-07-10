part of 'explorer_providers.dart';

// --- Place page ---

class ExplorerPlaceDetail {
  final Place place;

  /// Every verse that mentions the place, in canonical order.
  final List<PlaceVerse> verses;

  /// Events whose account includes one of those verses, chronological.
  final List<TimelineEvent> events;

  /// People co-mentioned in those verses, most co-mentions first.
  final List<BiblePerson> people;
  ExplorerPlaceDetail({
    required this.place,
    required this.verses,
    required this.events,
    required this.people,
  });
}

final explorerPlaceDetailProvider =
    FutureProvider.family<ExplorerPlaceDetail?, int>((ref, placeId) async {
      await ref.watch(explorerReadyProvider.future);
      final store = ref.watch(contentStoreProvider);
      final place = await (store.select(
        store.places,
      )..where((p) => p.id.equals(placeId))).getSingleOrNull();
      if (place == null) return null;

      // Import order is canonical scripture order.
      final verses =
          await (store.select(store.placeVerses)
                ..where((v) => v.placeId.equals(placeId))
                ..orderBy([(v) => OrderingTerm.asc(v.id)]))
              .get();

      final eventRows = await store
          .customSelect(
            'SELECT DISTINCT e.id AS id, e.sort_key AS sort_key '
            'FROM place_verses pv '
            'JOIN event_verses ev ON ev.book_name = pv.book_name '
            '  AND ev.chapter = pv.chapter AND ev.verse = pv.verse '
            'JOIN timeline_events e ON e.id = ev.event_id '
            'WHERE pv.place_id = ? '
            'ORDER BY e.sort_key IS NULL, e.sort_key',
            variables: [Variable.withInt(placeId)],
          )
          .get();
      final events = await _eventsByIds(store, [
        for (final r in eventRows) r.read<int>('id'),
      ]);

      final peopleRows = await store
          .customSelect(
            'SELECT pe.id AS id, COUNT(*) AS shared FROM place_verses pv '
            'JOIN person_verses psv ON psv.book_name = pv.book_name '
            '  AND psv.chapter = pv.chapter AND psv.verse = pv.verse '
            'JOIN bible_people pe ON pe.id = psv.person_id '
            'WHERE pv.place_id = ? '
            'GROUP BY pe.id ORDER BY shared DESC LIMIT 30',
            variables: [Variable.withInt(placeId)],
          )
          .get();
      final people = await _peopleByIds(store, [
        for (final r in peopleRows) r.read<int>('id'),
      ]);

      return ExplorerPlaceDetail(
        place: place,
        verses: verses,
        events: events,
        people: people,
      );
    });
