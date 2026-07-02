import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content_store.dart';
import '../domain/explorer/explorer_ref.dart';
import '../domain/search/reference_parser.dart';
import 'content_providers.dart';
import 'people_providers.dart';
import 'place_providers.dart';
import 'reader_state.dart';
import 'topic_providers.dart';

/// All three bundled datasets the Explorer draws on (people, places, topics),
/// imported into the DB. One thing for the screen to await.
final explorerReadyProvider = FutureProvider<bool>((ref) async {
  await Future.wait([
    ref.watch(peopleReadyProvider.future),
    ref.watch(placesReadyProvider.future),
    ref.watch(topicalIndexReadyProvider.future),
  ]);
  return true;
});

/// Dataset sizes shown on the Explorer home page.
class ExplorerStats {
  final int people;
  final int places;
  final int events;
  final int topics;
  const ExplorerStats({
    required this.people,
    required this.places,
    required this.events,
    required this.topics,
  });
}

final explorerStatsProvider = FutureProvider<ExplorerStats>((ref) async {
  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  Future<int> count(String table) async {
    final row = await store
        .customSelect('SELECT COUNT(*) AS c FROM $table')
        .getSingle();
    return row.read<int>('c');
  }

  final counts = await Future.wait([
    count('bible_people'),
    count('places'),
    count('timeline_events'),
    count('topics'),
  ]);
  return ExplorerStats(
    people: counts[0],
    places: counts[1],
    events: counts[2],
    topics: counts[3],
  );
});

// --- Exploration trail (breadcrumb navigation stack) ---

/// The chain of entities the user has drilled through, oldest first. Empty
/// means the Explorer home (search) page. Session-global so reopening the
/// Explorer resumes where the user left off.
class ExplorerTrailNotifier extends Notifier<List<ExplorerRef>> {
  @override
  List<ExplorerRef> build() => const [];

  void open(ExplorerRef ref) {
    if (state.isNotEmpty && state.last == ref) return;
    state = [...state, ref];
  }

  /// Cut the trail back so [index] is the last (current) entry.
  void truncateTo(int index) {
    if (index < 0 || index >= state.length - 1) return;
    state = state.sublist(0, index + 1);
  }

  void pop() {
    if (state.isNotEmpty) state = state.sublist(0, state.length - 1);
  }

  void clear() => state = const [];
}

final explorerTrailProvider =
    NotifierProvider<ExplorerTrailNotifier, List<ExplorerRef>>(
  () => ExplorerTrailNotifier(),
);

// --- Universal search ---

class ExplorerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final explorerSearchQueryProvider =
    NotifierProvider<ExplorerSearchQueryNotifier, String>(
  () => ExplorerSearchQueryNotifier(),
);

/// One search hit: where it goes plus a short qualifier for the result tile.
class ExplorerSearchItem {
  final ExplorerRef ref;
  final String? subtitle;
  ExplorerSearchItem(this.ref, [this.subtitle]);
}

class ExplorerSearchResults {
  final ExplorerRef? passage;
  final List<ExplorerSearchItem> people;
  final List<ExplorerSearchItem> places;
  final List<ExplorerSearchItem> events;
  final List<ExplorerSearchItem> topics;
  ExplorerSearchResults({
    this.passage,
    this.people = const [],
    this.places = const [],
    this.events = const [],
    this.topics = const [],
  });

  bool get isEmpty =>
      passage == null &&
      people.isEmpty &&
      places.isEmpty &&
      events.isEmpty &&
      topics.isEmpty;
}

const _kSearchLimitPerKind = 25;

String _isoYear(int year) => year < 0 ? '${-year} BC' : 'AD $year';

/// Fetch the [BiblePerson] rows for [ids], preserving the ids' order.
Future<List<BiblePerson>> _peopleByIds(ContentStore store, List<int> ids) async {
  if (ids.isEmpty) return const [];
  final rows = await (store.select(store.biblePeople)
        ..where((p) => p.id.isIn(ids)))
      .get();
  final byId = {for (final p in rows) p.id: p};
  return [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];
}

/// Fetch the [Place] rows for [ids], preserving the ids' order.
Future<List<Place>> _placesByIds(ContentStore store, List<int> ids) async {
  if (ids.isEmpty) return const [];
  final rows = await (store.select(store.places)
        ..where((p) => p.id.isIn(ids)))
      .get();
  final byId = {for (final p in rows) p.id: p};
  return [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];
}

/// Fetch the [TimelineEvent] rows for [ids], preserving the ids' order.
Future<List<TimelineEvent>> _eventsByIds(
    ContentStore store, List<int> ids) async {
  if (ids.isEmpty) return const [];
  final rows = await (store.select(store.timelineEvents)
        ..where((e) => e.id.isIn(ids)))
      .get();
  final byId = {for (final e in rows) e.id: e};
  return [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];
}

/// Prefix matches first, then substring matches; within each rank the caller's
/// [weight] (e.g. verse count) decides, heaviest first.
void _rankByPrefix<T>(
  List<T> rows,
  String query,
  String Function(T) name,
  int Function(T) weight,
) {
  final lower = query.toLowerCase();
  rows.sort((a, b) {
    final ap = name(a).toLowerCase().startsWith(lower) ? 0 : 1;
    final bp = name(b).toLowerCase().startsWith(lower) ? 0 : 1;
    if (ap != bp) return ap - bp;
    final w = weight(b).compareTo(weight(a));
    if (w != 0) return w;
    return name(a).compareTo(name(b));
  });
}

/// Fans one query out across every entity kind: a scripture-reference parse
/// plus name searches over people, places, events, and topics.
final explorerSearchResultsProvider =
    FutureProvider<ExplorerSearchResults>((ref) async {
  final query = ref.watch(explorerSearchQueryProvider).trim();
  if (query.length < 2) return ExplorerSearchResults();
  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  final pattern = '%$query%';

  // Passage: parse against the primary active version's book list.
  ExplorerRef? passage;
  final versions = ref.watch(activeVersionsProvider);
  if (versions.isNotEmpty) {
    final books =
        await ref.watch(booksForVersionProvider(versions.first).future);
    final parsed = ReferenceParser.parse(query, books);
    if (parsed != null) {
      passage = ExplorerRef.passage(parsed.book.name, parsed.chapter);
    }
  }

  final peopleRows = await (store.select(store.biblePeople)
        ..where(
          (p) =>
              p.name.like(pattern) |
              p.displayTitle.like(pattern) |
              p.alsoCalled.like(pattern),
        )
        ..orderBy([(p) => OrderingTerm.desc(p.verseCount)])
        ..limit(_kSearchLimitPerKind))
      .get();
  _rankByPrefix(peopleRows, query, (p) => p.name, (p) => p.verseCount);

  final placeRows = await store.customSelect(
    'SELECT p.id AS id, p.name AS name, COUNT(pv.id) AS refs '
    'FROM places p LEFT JOIN place_verses pv ON pv.place_id = p.id '
    'WHERE p.name LIKE ? GROUP BY p.id, p.name '
    'ORDER BY refs DESC LIMIT ?',
    variables: [
      Variable.withString(pattern),
      Variable.withInt(_kSearchLimitPerKind),
    ],
  ).get();
  final placeHits = [
    for (final r in placeRows)
      (
        id: r.read<int>('id'),
        name: r.read<String>('name'),
        refs: r.read<int>('refs'),
      ),
  ];
  _rankByPrefix(placeHits, query, (p) => p.name, (p) => p.refs);

  final eventRows = await (store.select(store.timelineEvents)
        ..where((e) => e.title.like(pattern))
        ..orderBy([
          (e) => OrderingTerm(expression: e.sortKey.isNull()),
          (e) => OrderingTerm.asc(e.sortKey),
        ])
        ..limit(_kSearchLimitPerKind))
      .get();

  final topicRows = await (store.select(store.topics)
        ..where((t) => t.name.like('%${query.toUpperCase()}%'))
        ..orderBy([(t) => OrderingTerm.asc(t.name)])
        ..limit(_kSearchLimitPerKind))
      .get();
  _rankByPrefix(topicRows, query, (t) => t.name, (_) => 0);

  return ExplorerSearchResults(
    passage: passage,
    people: [
      for (final p in peopleRows)
        ExplorerSearchItem(
          ExplorerRef.person(p.id, p.displayTitle),
          '${p.verseCount} ${p.verseCount == 1 ? 'verse' : 'verses'}'
          '${p.alsoCalled != null ? ' · also ${p.alsoCalled}' : ''}',
        ),
    ],
    places: [
      for (final p in placeHits)
        ExplorerSearchItem(
          ExplorerRef.place(p.id, p.name),
          '${p.refs} ${p.refs == 1 ? 'verse' : 'verses'}',
        ),
    ],
    events: [
      for (final e in eventRows)
        ExplorerSearchItem(
          ExplorerRef.event(e.id, e.title),
          e.startYear == null ? null : _isoYear(e.startYear!),
        ),
    ],
    topics: [
      for (final t in topicRows)
        ExplorerSearchItem(ExplorerRef.topic(t.id, t.name)),
    ],
  );
});

// --- Event page ---

class ExplorerEventDetail {
  final TimelineEvent event;

  /// Participants, most-mentioned first.
  final List<BiblePerson> participants;

  /// The event's account, in canonical order.
  final List<EventVerse> verses;

  /// Places mentioned within the event's verses.
  final List<Place> places;
  ExplorerEventDetail({
    required this.event,
    required this.participants,
    required this.verses,
    required this.places,
  });
}

final explorerEventDetailProvider =
    FutureProvider.family<ExplorerEventDetail?, int>((ref, eventId) async {
  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  final event = await (store.select(store.timelineEvents)
        ..where((e) => e.id.equals(eventId)))
      .getSingleOrNull();
  if (event == null) return null;

  final participantRows = await store.customSelect(
    'SELECT p.id AS id FROM event_participants ep '
    'JOIN bible_people p ON p.id = ep.person_id '
    'WHERE ep.event_id = ? ORDER BY p.verse_count DESC',
    variables: [Variable.withInt(eventId)],
  ).get();
  final participants = await _peopleByIds(
    store,
    [for (final r in participantRows) r.read<int>('id')],
  );

  final verses = await (store.select(store.eventVerses)
        ..where((v) => v.eventId.equals(eventId))
        ..orderBy([(v) => OrderingTerm.asc(v.ord)]))
      .get();

  // Places aren't linked to events in the dataset; the event's verses are the
  // bridge — any place mentioned in one of them belongs on the event's map.
  final placeRows = await store.customSelect(
    'SELECT DISTINCT p.id AS id, p.name AS name FROM event_verses ev '
    'JOIN place_verses pv ON pv.book_name = ev.book_name '
    '  AND pv.chapter = ev.chapter AND pv.verse = ev.verse '
    'JOIN places p ON p.id = pv.place_id '
    'WHERE ev.event_id = ? ORDER BY p.name',
    variables: [Variable.withInt(eventId)],
  ).get();
  final places = await _placesByIds(
    store,
    [for (final r in placeRows) r.read<int>('id')],
  );

  return ExplorerEventDetail(
    event: event,
    participants: participants,
    verses: verses,
    places: places,
  );
});

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
  final place = await (store.select(store.places)
        ..where((p) => p.id.equals(placeId)))
      .getSingleOrNull();
  if (place == null) return null;

  // Import order is canonical scripture order.
  final verses = await (store.select(store.placeVerses)
        ..where((v) => v.placeId.equals(placeId))
        ..orderBy([(v) => OrderingTerm.asc(v.id)]))
      .get();

  final eventRows = await store.customSelect(
    'SELECT DISTINCT e.id AS id, e.sort_key AS sort_key '
    'FROM place_verses pv '
    'JOIN event_verses ev ON ev.book_name = pv.book_name '
    '  AND ev.chapter = pv.chapter AND ev.verse = pv.verse '
    'JOIN timeline_events e ON e.id = ev.event_id '
    'WHERE pv.place_id = ? '
    'ORDER BY e.sort_key IS NULL, e.sort_key',
    variables: [Variable.withInt(placeId)],
  ).get();
  final events = await _eventsByIds(
    store,
    [for (final r in eventRows) r.read<int>('id')],
  );

  final peopleRows = await store.customSelect(
    'SELECT pe.id AS id, COUNT(*) AS shared FROM place_verses pv '
    'JOIN person_verses psv ON psv.book_name = pv.book_name '
    '  AND psv.chapter = pv.chapter AND psv.verse = pv.verse '
    'JOIN bible_people pe ON pe.id = psv.person_id '
    'WHERE pv.place_id = ? '
    'GROUP BY pe.id ORDER BY shared DESC LIMIT 30',
    variables: [Variable.withInt(placeId)],
  ).get();
  final people = await _peopleByIds(
    store,
    [for (final r in peopleRows) r.read<int>('id')],
  );

  return ExplorerPlaceDetail(
    place: place,
    verses: verses,
    events: events,
    people: people,
  );
});

// --- Person page extras (the core comes from personDetailProvider) ---

/// Places mentioned in the same verses as a person — where their story
/// happens, most co-mentions first.
final explorerPersonPlacesProvider =
    FutureProvider.family<List<Place>, int>((ref, personId) async {
  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);
  final rows = await store.customSelect(
    'SELECT p.id AS id, COUNT(*) AS shared FROM person_verses psv '
    'JOIN place_verses pv ON pv.book_name = psv.book_name '
    '  AND pv.chapter = psv.chapter AND pv.verse = psv.verse '
    'JOIN places p ON p.id = pv.place_id '
    'WHERE psv.person_id = ? '
    'GROUP BY p.id ORDER BY shared DESC LIMIT 30',
    variables: [Variable.withInt(personId)],
  ).get();
  return _placesByIds(store, [for (final r in rows) r.read<int>('id')]);
});

// --- Passage page ---

class ExplorerEventHit {
  final int id;
  final String title;
  final int? startYear;
  ExplorerEventHit(this.id, this.title, this.startYear);
}

class ExplorerTopicHit {
  final int id;
  final String name;
  ExplorerTopicHit(this.id, this.name);
}

class ExplorerPassageOverview {
  final List<PersonInPassage> people;
  final List<PlaceInPassage> places;
  final List<ExplorerEventHit> events;
  final List<ExplorerTopicHit> topics;
  ExplorerPassageOverview({
    required this.people,
    required this.places,
    required this.events,
    required this.topics,
  });

  bool get isEmpty =>
      people.isEmpty && places.isEmpty && events.isEmpty && topics.isEmpty;
}

/// Everything the datasets know about one chapter, fetched concurrently.
final explorerPassageOverviewProvider = FutureProvider.family<
    ExplorerPassageOverview, ({String book, int chapter})>((ref, loc) async {
  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);

  final peopleFuture = ref.watch(peopleForPassageProvider(loc).future);
  final placesFuture = ref.watch(placesForPassageProvider(loc).future);

  final eventsFuture = store.customSelect(
    'SELECT DISTINCT e.id AS id, e.title AS title, e.start_year AS start_year '
    'FROM event_verses ev '
    'JOIN timeline_events e ON e.id = ev.event_id '
    'WHERE ev.book_name = ? AND ev.chapter = ? '
    'ORDER BY e.sort_key IS NULL, e.sort_key',
    variables: [
      Variable.withString(loc.book),
      Variable.withInt(loc.chapter),
    ],
  ).get();

  final topicsFuture = store.customSelect(
    'SELECT DISTINCT t.id AS id, t.name AS name '
    'FROM topic_references r '
    'JOIN topics t ON t.id = r.topic_id '
    'WHERE r.book_name = ? AND r.chapter = ? '
    'ORDER BY t.name',
    variables: [
      Variable.withString(loc.book),
      Variable.withInt(loc.chapter),
    ],
  ).get();

  final results = await Future.wait([
    peopleFuture,
    placesFuture,
    eventsFuture,
    topicsFuture,
  ]);

  return ExplorerPassageOverview(
    people: results[0] as List<PersonInPassage>,
    places: results[1] as List<PlaceInPassage>,
    events: [
      for (final r in results[2] as List<QueryRow>)
        ExplorerEventHit(
          r.read<int>('id'),
          r.read<String>('title'),
          r.readNullable<int>('start_year'),
        ),
    ],
    topics: [
      for (final r in results[3] as List<QueryRow>)
        ExplorerTopicHit(r.read<int>('id'), r.read<String>('name')),
    ],
  );
});
