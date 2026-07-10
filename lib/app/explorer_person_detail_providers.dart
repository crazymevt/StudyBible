part of 'explorer_providers.dart';

// --- Person page extras (the core comes from personDetailProvider) ---

/// Places mentioned in the same verses as a person — where their story
/// happens, most co-mentions first.
final explorerPersonPlacesProvider = FutureProvider.family<List<Place>, int>((
  ref,
  personId,
) async {
  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  final rows = await store
      .customSelect(
        'SELECT p.id AS id, COUNT(*) AS shared FROM person_verses psv '
        'JOIN place_verses pv ON pv.book_name = psv.book_name '
        '  AND pv.chapter = psv.chapter AND pv.verse = psv.verse '
        'JOIN places p ON p.id = pv.place_id '
        'WHERE psv.person_id = ? '
        'GROUP BY p.id ORDER BY shared DESC LIMIT 30',
        variables: [Variable.withInt(personId)],
      )
      .get();
  return _placesByIds(store, [for (final r in rows) r.read<int>('id')]);
});

/// The curated feasts/stories (see curated_topics_data.dart) whose cited
/// verses include one of a person's verses — "David and Goliath" for David,
/// "Passover" for Moses, etc. Nave's own ~5,000 subject headings are excluded
/// (a person like David would match hundreds of those — "FAITH," "KING" —
/// which isn't what a "their stories" card is for); only topics with a
/// non-null `category` (feast/story) qualify.
final explorerPersonStoriesProvider =
    FutureProvider.family<List<ExplorerTopicHit>, int>((ref, personId) async {
      await ref.watch(explorerReadyProvider.future);
      final store = ref.watch(contentStoreProvider);
      final rows = await store
          .customSelect(
            '''
    SELECT DISTINCT t.id AS id, t.name AS name
    FROM person_verses psv
    JOIN topic_references tr ON tr.book_name = psv.book_name AND tr.chapter = psv.chapter
      AND (
        tr.verse IS NULL
        OR (tr.verse_end IS NULL AND tr.verse = psv.verse)
        OR (tr.verse_end IS NOT NULL AND psv.verse BETWEEN tr.verse AND tr.verse_end)
      )
    JOIN topics t ON t.id = tr.topic_id AND t.category IS NOT NULL
    WHERE psv.person_id = ?
    ORDER BY t.name
    ''',
            variables: [Variable.withInt(personId)],
          )
          .get();
      return [
        for (final r in rows)
          ExplorerTopicHit(r.read<int>('id'), r.read<String>('name')),
      ];
    });
