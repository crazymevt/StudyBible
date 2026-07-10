part of 'explorer_providers.dart';

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

/// A tag hit for search results and facet cards: the tag itself (name and
/// colour) plus how many things are filed under it.
class ExplorerTagHit {
  final TagData tag;
  final int itemCount;
  ExplorerTagHit(this.tag, this.itemCount);
}

class ExplorerSearchResults {
  final ExplorerRef? passage;
  final List<ExplorerSearchItem> people;
  final List<ExplorerSearchItem> places;
  final List<ExplorerSearchItem> events;
  final List<ExplorerSearchItem> topics;
  final List<ExplorerSearchItem> prophecies;
  final List<ExplorerTagHit> tags;

  /// "Did you mean …?" entities near the query by edit distance. Only
  /// populated when everything above is empty (see [isEmpty], which
  /// deliberately ignores these — they're an offer, not a result).
  final List<ExplorerSearchItem> suggestions;
  ExplorerSearchResults({
    this.passage,
    this.people = const [],
    this.places = const [],
    this.events = const [],
    this.topics = const [],
    this.prophecies = const [],
    this.tags = const [],
    this.suggestions = const [],
  });

  bool get isEmpty =>
      passage == null &&
      people.isEmpty &&
      places.isEmpty &&
      events.isEmpty &&
      topics.isEmpty &&
      prophecies.isEmpty &&
      tags.isEmpty;
}

const _kSearchLimitPerKind = 25;

String _isoYear(int year) => year < 0 ? '${-year} BC' : 'AD $year';

/// Fetch the [BiblePerson] rows for [ids], preserving the ids' order.
Future<List<BiblePerson>> _peopleByIds(
  ContentStore store,
  List<int> ids,
) async {
  if (ids.isEmpty) return const [];
  final rows = await (store.select(
    store.biblePeople,
  )..where((p) => p.id.isIn(ids))).get();
  final byId = {for (final p in rows) p.id: p};
  return [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];
}

/// Fetch the [Place] rows for [ids], preserving the ids' order.
Future<List<Place>> _placesByIds(ContentStore store, List<int> ids) async {
  if (ids.isEmpty) return const [];
  final rows = await (store.select(
    store.places,
  )..where((p) => p.id.isIn(ids))).get();
  final byId = {for (final p in rows) p.id: p};
  return [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];
}

/// Fetch the [TimelineEvent] rows for [ids], preserving the ids' order.
Future<List<TimelineEvent>> _eventsByIds(
  ContentStore store,
  List<int> ids,
) async {
  if (ids.isEmpty) return const [];
  final rows = await (store.select(
    store.timelineEvents,
  )..where((e) => e.id.isIn(ids))).get();
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

/// Every dataset entity's name variants, preloaded once for the fuzzy
/// "Did you mean …?" pass — only consulted when a search comes back empty,
/// but scanning four tables per keystroke would be wasteful, so the
/// candidate list is built a single time and cached.
final _explorerFuzzyCandidatesProvider =
    FutureProvider<List<FuzzyCandidate<ExplorerRef>>>((ref) async {
      await ref.watch(explorerReadyProvider.future);
      final store = ref.watch(contentStoreProvider);
      final candidates = <FuzzyCandidate<ExplorerRef>>[];

      final people = await store.select(store.biblePeople).get();
      for (final p in people) {
        candidates.add(
          FuzzyCandidate(ExplorerRef.person(p.id, p.displayTitle), [
            p.name,
            p.displayTitle,
            if (p.alsoCalled != null) ...p.alsoCalled!.split(RegExp('[,;]')),
          ], weight: p.verseCount),
        );
      }

      final places = await store.select(store.places).get();
      for (final p in places) {
        candidates.add(
          FuzzyCandidate(ExplorerRef.place(p.id, p.name), [p.name]),
        );
      }

      final events = await store.select(store.timelineEvents).get();
      for (final e in events) {
        candidates.add(
          FuzzyCandidate(ExplorerRef.event(e.id, e.title), [e.title]),
        );
      }

      final topics = await store.select(store.topics).get();
      for (final t in topics) {
        candidates.add(
          FuzzyCandidate(ExplorerRef.topic(t.id, t.name), [t.name]),
        );
      }

      // Prophecies are intentionally left out of the fuzzy "did you mean" pool:
      // their titles are phrases, not names, so matching a misspelled word against
      // them ("David" inside "Heir to the throne of David") only adds noise. Direct
      // search (searchProphecies) already covers them by title, reference, or prose.

      return candidates;
    });

/// A short window of bio text around the first [query] match, for the result
/// tile's subtitle — so a hit found through Easton's prose shows *why* it
/// matched ("…the shepherd king of Israel…").
String bioSnippet(String bio, String query, {int radius = 40}) {
  final flat = bio.replaceAll(RegExp(r'\s+'), ' ');
  final i = flat.toLowerCase().indexOf(query.toLowerCase());
  if (i < 0) return flat;
  final start = i - radius < 0 ? 0 : i - radius;
  final end = i + query.length + radius > flat.length
      ? flat.length
      : i + query.length + radius;
  return '${start > 0 ? '…' : ''}${flat.substring(start, end).trim()}'
      '${end < flat.length ? '…' : ''}';
}

/// Bio search only kicks in for queries long enough that a substring match
/// against prose still means something — `%son%` would match nearly every
/// Easton's entry.
const _kMinBioQueryLength = 4;

/// Fans one query out across every entity kind: a scripture-reference parse
/// plus name searches over people, places, events, and topics.
///
/// A `.family` keyed on the query string itself, rather than reading it off
/// [explorerSearchQueryProvider] directly, so a second search surface (the
/// notebook editor's "Link to Explorer" picker) can reuse this fan-out logic
/// against its own local query without sharing state with the Explorer's
/// home-screen search box.
final explorerSearchResultsProvider = FutureProvider<ExplorerSearchResults>(
  (ref) => ref.watch(
    explorerSearchResultsForProvider(
      ref.watch(explorerSearchQueryProvider),
    ).future,
  ),
);

final explorerSearchResultsForProvider =
    FutureProvider.family<ExplorerSearchResults, String>((ref, rawQuery) async {
      final query = rawQuery.trim();
      if (query.length < 2) return ExplorerSearchResults();
      await ref.watch(explorerReadyProvider.future);
      final store = ref.watch(contentStoreProvider);
      final pattern = '%$query%';

      // Passage: parse against the primary active version's book list.
      ExplorerRef? passage;
      final versions = ref.watch(activeVersionsProvider);
      if (versions.isNotEmpty) {
        final books = await ref.watch(
          booksForVersionProvider(versions.first).future,
        );
        final parsed = ReferenceParser.parse(query, books);
        if (parsed != null) {
          passage = ExplorerRef.passage(parsed.book.name, parsed.chapter);
        }
      }

      final peopleRows =
          await (store.select(store.biblePeople)
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

      // Second pass: people whose name didn't match but whose Easton's bio
      // mentions the query at a word start ("shepherd" finds David, not every
      // bio containing "…herds…"). Fills whatever the name search left of the
      // per-kind limit; SQL over-fetches because the word-start filter only
      // happens here, after LIKE's substring matching.
      var bioHits = <BiblePerson>[];
      if (query.length >= _kMinBioQueryLength &&
          peopleRows.length < _kSearchLimitPerKind) {
        final room = _kSearchLimitPerKind - peopleRows.length;
        final wordStart = RegExp(
          '\\b${RegExp.escape(query)}',
          caseSensitive: false,
        );
        final rows =
            await (store.select(store.biblePeople)
                  ..where(
                    (p) =>
                        p.bio.like(pattern) &
                        p.id.isNotIn([for (final p in peopleRows) p.id]),
                  )
                  ..orderBy([(p) => OrderingTerm.desc(p.verseCount)])
                  ..limit(room * 3))
                .get();
        bioHits = rows
            .where((p) => wordStart.hasMatch(p.bio!))
            .take(room)
            .toList();
      }

      final placeRows = await store
          .customSelect(
            'SELECT p.id AS id, p.name AS name, COUNT(pv.id) AS refs '
            'FROM places p LEFT JOIN place_verses pv ON pv.place_id = p.id '
            'WHERE p.name LIKE ? GROUP BY p.id, p.name '
            'ORDER BY refs DESC LIMIT ?',
            variables: [
              Variable.withString(pattern),
              Variable.withInt(_kSearchLimitPerKind),
            ],
          )
          .get();
      final placeHits = [
        for (final r in placeRows)
          (
            id: r.read<int>('id'),
            name: r.read<String>('name'),
            refs: r.read<int>('refs'),
          ),
      ];
      _rankByPrefix(placeHits, query, (p) => p.name, (p) => p.refs);

      final eventRows =
          await (store.select(store.timelineEvents)
                ..where((e) => e.title.like(pattern))
                ..orderBy([
                  (e) => OrderingTerm(expression: e.sortKey.isNull()),
                  (e) => OrderingTerm.asc(e.sortKey),
                ])
                ..limit(_kSearchLimitPerKind))
              .get();

      final topicRows =
          await (store.select(store.topics)
                ..where((t) => t.name.like('%${query.toUpperCase()}%'))
                ..orderBy([(t) => OrderingTerm.asc(t.name)])
                ..limit(_kSearchLimitPerKind))
              .get();
      _rankByPrefix(topicRows, query, (t) => t.name, (_) => 0);

      // Your tags: matched by name, with or without the leading '#' people type
      // out of habit from the global search.
      final tagQuery = (query.startsWith('#') ? query.substring(1) : query)
          .trim();
      var tagHits = <ExplorerTagHit>[];
      if (tagQuery.isNotEmpty) {
        final userDb = ref.watch(userStoreProvider);
        final tagRows = await userDb
            .customSelect(
              'SELECT t.id AS id, t.name AS name, t.color_hex AS color_hex, '
              '  COUNT(et.id) AS items '
              'FROM tags t '
              'LEFT JOIN entity_tags et ON et.tag_id = t.id AND et.deleted = 0 '
              'WHERE t.deleted = 0 AND t.name LIKE ? '
              'GROUP BY t.id, t.name, t.color_hex '
              'ORDER BY items DESC LIMIT ?',
              variables: [
                Variable.withString('%$tagQuery%'),
                Variable.withInt(_kSearchLimitPerKind),
              ],
            )
            .get();
        tagHits = [
          for (final r in tagRows)
            ExplorerTagHit(
              TagData(
                id: r.read<String>('id'),
                name: r.read<String>('name'),
                colorHex: r.readNullable<String>('color_hex'),
              ),
              r.read<int>('items'),
            ),
        ];
        _rankByPrefix(tagHits, tagQuery, (t) => t.tag.name, (t) => t.itemCount);
      }

      // Prophecies: matched over the pure-Dart dataset (see searchProphecies).
      final prophecyHits = searchProphecies(query, limit: _kSearchLimitPerKind);

      final results = ExplorerSearchResults(
        passage: passage,
        people: [
          for (final p in peopleRows)
            ExplorerSearchItem(
              ExplorerRef.person(p.id, p.displayTitle),
              '${p.verseCount} ${p.verseCount == 1 ? 'verse' : 'verses'}'
              '${p.alsoCalled != null ? ' · also ${p.alsoCalled}' : ''}',
            ),
          for (final p in bioHits)
            ExplorerSearchItem(
              ExplorerRef.person(p.id, p.displayTitle),
              bioSnippet(p.bio!, query),
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
        prophecies: [
          for (final h in prophecyHits)
            ExplorerSearchItem(
              ExplorerRef.prophecy(h.index, h.title),
              h.subtitle,
            ),
        ],
        tags: tagHits,
      );
      if (!results.isEmpty || query.startsWith('#')) return results;

      // Nothing matched anywhere: offer the nearest entity names by edit
      // distance instead of a dead-end "No matches".
      final candidates = await ref.watch(
        _explorerFuzzyCandidatesProvider.future,
      );
      return ExplorerSearchResults(
        suggestions: [
          for (final s in fuzzySuggest(query, candidates))
            ExplorerSearchItem(s.item),
        ],
      );
    });
