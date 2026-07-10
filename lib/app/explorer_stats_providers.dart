part of 'explorer_providers.dart';

/// All bundled/curated datasets the Explorer draws on (people, places,
/// Nave's topics, and the curated feasts/stories layered on top of them),
/// imported into the DB. One thing for the screen to await.
final explorerReadyProvider = FutureProvider<bool>((ref) async {
  await Future.wait([
    ref.watch(peopleReadyProvider.future),
    ref.watch(placesReadyProvider.future),
    ref.watch(curatedTopicsReadyProvider.future),
  ]);
  return true;
});

/// Dataset sizes shown on the Explorer home page. Curated feasts, stories,
/// and named-group categories are counted apart from the plain (Nave's)
/// topics — each gets its own browse chip.
class ExplorerStats {
  final int people;
  final int places;
  final int events;
  final int topics;
  final int feasts;
  final int stories;
  final int prophecies;
  final int tribes;
  final int apostles;
  final int judges;
  final int prophets;
  const ExplorerStats({
    required this.people,
    required this.places,
    required this.events,
    required this.topics,
    required this.feasts,
    required this.stories,
    required this.prophecies,
    required this.tribes,
    required this.apostles,
    required this.judges,
    required this.prophets,
  });
}

final explorerStatsProvider = FutureProvider<ExplorerStats>((ref) async {
  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  Future<int> count(String from) async {
    final row = await store
        .customSelect('SELECT COUNT(*) AS c FROM $from')
        .getSingle();
    return row.read<int>('c');
  }

  final counts = await Future.wait([
    count('bible_people'),
    count('places'),
    count('timeline_events'),
    count('topics WHERE category IS NULL'),
    count("topics WHERE category = 'feast'"),
    count("topics WHERE category = 'story'"),
    count("topics WHERE category = 'tribe'"),
    count("topics WHERE category = 'apostle'"),
    count("topics WHERE category = 'judge'"),
    count("topics WHERE category = 'prophet'"),
  ]);
  return ExplorerStats(
    people: counts[0],
    places: counts[1],
    events: counts[2],
    topics: counts[3],
    feasts: counts[4],
    stories: counts[5],
    // Prophecies aren't a content-store table — they're the pure-Dart
    // `prophecies` dataset, so this count is just its length.
    prophecies: prophecies.length,
    tribes: counts[6],
    apostles: counts[7],
    judges: counts[8],
    prophets: counts[9],
  );
});

/// Hand-verified tribe/apostle/judge/prophet → `BiblePeople.id` links (see
/// `namedGroupPersonIds` in `curated_topics_data.dart`), wrapped in a
/// provider so the Explorer topic page reads it the same way it reads
/// everything else.
final namedGroupPersonIdsProvider = Provider<Map<String, int>>(
  (ref) => namedGroupPersonIds,
);

/// Major/Minor/Other grouping for the Prophets browse category (see
/// `prophetSections` in `curated_topics_data.dart`), wrapped in a provider
/// for the same reason as [namedGroupPersonIdsProvider].
final prophetSectionsProvider = Provider<Map<String, String>>(
  (ref) => prophetSections,
);
