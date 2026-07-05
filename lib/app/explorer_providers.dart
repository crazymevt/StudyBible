import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content_store.dart';
import '../data/user_store.dart';
import '../domain/explorer/explorer_ref.dart';
import '../domain/search/reference_parser.dart';
import 'content_providers.dart';
import 'document_reference_providers.dart';
import 'people_providers.dart';
import 'place_providers.dart';
import 'reader_state.dart';
import 'search_providers.dart';
import 'tag_providers.dart';
import 'topic_providers.dart';
import 'user_providers.dart';

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
  final List<ExplorerTagHit> tags;
  ExplorerSearchResults({
    this.passage,
    this.people = const [],
    this.places = const [],
    this.events = const [],
    this.topics = const [],
    this.tags = const [],
  });

  bool get isEmpty =>
      passage == null &&
      people.isEmpty &&
      places.isEmpty &&
      events.isEmpty &&
      topics.isEmpty &&
      tags.isEmpty;
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
///
/// A `.family` keyed on the query string itself, rather than reading it off
/// [explorerSearchQueryProvider] directly, so a second search surface (the
/// notebook editor's "Link to Explorer" picker) can reuse this fan-out logic
/// against its own local query without sharing state with the Explorer's
/// home-screen search box.
final explorerSearchResultsProvider = FutureProvider<ExplorerSearchResults>(
  (ref) => ref.watch(
    explorerSearchResultsForProvider(ref.watch(explorerSearchQueryProvider)).future,
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

  // Your tags: matched by name, with or without the leading '#' people type
  // out of habit from the global search.
  final tagQuery =
      (query.startsWith('#') ? query.substring(1) : query).trim();
  var tagHits = <ExplorerTagHit>[];
  if (tagQuery.isNotEmpty) {
    final userDb = ref.watch(userStoreProvider);
    final tagRows = await userDb.customSelect(
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
    ).get();
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
    tags: tagHits,
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

// --- Dictionary lookup (place & topic pages) ---

/// Dictionary entries whose headword matches an Explorer entity's name, across
/// every installed dictionary (Easton's, or any user-imported lexicon). Powers
/// the "Dictionary" facet card on place and topic pages, so a place like
/// "Jerusalem" or a topic like "AARON" surfaces its dictionary definition.
/// Empty when no dictionary is installed or nothing matches.
///
/// Person pages deliberately don't use this — their biography card already
/// shows the Easton entry (baked into the Theographic data), so a dictionary
/// card would duplicate it.
final explorerEntryDictionaryProvider =
    FutureProvider.family<List<DictionaryEntryWithDict>, String>(
        (ref, name) async {
  final dictionaries = await ref.watch(dictionariesProvider.future);
  if (dictionaries.isEmpty) return const [];
  final store = ref.watch(contentStoreProvider);

  // Candidate headwords: the name as-is, plus the name with any trailing
  // parenthetical qualifier stripped ("Ramah (1)" -> "Ramah"). LIKE with no
  // wildcards is a case-insensitive exact match, so a topic's upper-case
  // "AARON" still resolves Easton's "Aaron" without over-matching substrings.
  final terms = <String>{};
  final trimmed = name.trim();
  if (trimmed.isNotEmpty) terms.add(trimmed);
  final withoutQualifier =
      trimmed.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
  if (withoutQualifier.isNotEmpty) terms.add(withoutQualifier);
  if (terms.isEmpty) return const [];

  final word = store.dictionaryEntries.word;
  final predicate = terms.map((t) => word.like(t)).reduce((a, b) => a | b);

  final rows = await (store.select(store.dictionaryEntries).join([
    innerJoin(
      store.dictionaries,
      store.dictionaries.id.equalsExp(store.dictionaryEntries.dictionaryId),
    ),
  ])
        ..where(predicate))
      .get();

  return [
    for (final row in rows)
      DictionaryEntryWithDict(
        entry: row.readTable(store.dictionaryEntries),
        dictionary: row.readTable(store.dictionaries),
      ),
  ];
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

/// One installed commentary's entries for a chapter.
class ExplorerCommentarySection {
  final Commentary commentary;

  /// Entries for the chapter, in verse order.
  final List<CommentaryEntry> entries;
  ExplorerCommentarySection(this.commentary, this.entries);
}

/// Chapter commentary across *all* installed commentaries (the reader's
/// Commentary panel shows one selected module at a time; the Explorer shows
/// everything available for the passage). Empty when none are installed.
final explorerPassageCommentariesProvider = FutureProvider.family<
    List<ExplorerCommentarySection>, ({String book, int chapter})>(
  (ref, loc) async {
    final store = ref.watch(contentStoreProvider);
    final commentaries = await ref.watch(commentariesProvider.future);
    if (commentaries.isEmpty) return const [];

    final entries = await (store.select(store.commentaryEntries)
          ..where(
            (c) =>
                c.bookName.equals(loc.book) & c.chapter.equals(loc.chapter),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.verse)]))
        .get();
    if (entries.isEmpty) return const [];

    final byCommentary = <int, List<CommentaryEntry>>{};
    for (final e in entries) {
      byCommentary.putIfAbsent(e.commentaryId, () => []).add(e);
    }
    return [
      for (final c in commentaries)
        if (byCommentary[c.id] != null)
          ExplorerCommentarySection(c, byCommentary[c.id]!),
    ];
  },
);

/// A chapter's cross-references from one source verse, target-votes desc.
class ExplorerCrossRefGroup {
  final int verse;
  final List<CrossReference> refs;
  ExplorerCrossRefGroup(this.verse, this.refs);
}

/// Chapter cross-references across the whole `cross_references` dataset,
/// grouped by source verse. The reader's Cross-References panel queries one
/// verse at a time (on tap); this aggregates every verse in the chapter for
/// the passage page.
final explorerPassageCrossReferencesProvider = FutureProvider.family<
    List<ExplorerCrossRefGroup>, ({String book, int chapter})>((ref, loc) async {
  final store = ref.watch(contentStoreProvider);
  final rows = await (store.select(store.crossReferences)
        ..where((c) =>
            c.sourceBookName.equals(loc.book) &
            c.sourceChapter.equals(loc.chapter))
        ..orderBy([
          (c) => OrderingTerm.asc(c.sourceVerse),
          (c) => OrderingTerm(expression: c.votes, mode: OrderingMode.desc),
        ]))
      .get();
  if (rows.isEmpty) return const [];

  final byVerse = <int, List<CrossReference>>{};
  for (final r in rows) {
    byVerse.putIfAbsent(r.sourceVerse, () => []).add(r);
  }
  return [
    for (final verse in byVerse.keys.toList()..sort())
      ExplorerCrossRefGroup(verse, byVerse[verse]!),
  ];
});

/// The documents of one type that reference [target], straight from the
/// persisted `document_references` index (maintained by
/// [documentReferenceIndexProvider]) — no content is loaded or scanned. A
/// passage matches when a stored citation's chapter span covers the target
/// chapter (the same rule the old live scan applied); a
/// person/place/event/topic matches its stored `sbent:` link exactly.
Future<List<SearchResult>> _documentsReferencing(
  Ref ref,
  ExplorerRef target, {
  required String docType,
  required String docTable,
}) async {
  await ref.watch(documentReferenceIndexProvider.future);
  final db = ref.watch(userStoreProvider);

  final String where;
  final List<Variable> variables;
  if (target.type == ExplorerEntityType.passage) {
    where = "r.kind = 'passage' AND r.book_name = ? "
        'AND r.chapter_start <= ? AND r.chapter_end >= ?';
    variables = [
      Variable.withString(target.book!),
      Variable.withInt(target.chapter!),
      Variable.withInt(target.chapter!),
    ];
  } else {
    final id = target.id;
    if (id == null) return const [];
    where = "r.kind = 'entity' AND r.entity_type = ? AND r.entity_id = ?";
    variables = [
      Variable.withString(target.type.name),
      Variable.withInt(id),
    ];
  }

  final rows = await db.customSelect(
    'SELECT d.id AS id, d.title AS title FROM document_references r '
    'JOIN $docTable d ON d.id = r.doc_id '
    "WHERE r.doc_type = '$docType' AND d.deleted = 0 AND $where "
    'GROUP BY d.id, d.title ORDER BY MAX(d.updated_at) DESC',
    variables: variables,
  ).get();
  return [
    for (final r in rows)
      SearchResult(
        type: docType,
        referenceId: r.read<String>('id'),
        title: r.read<String>('title'),
        textContent: '',
      ),
  ];
}

/// The user's own sermons that reference an Explorer entity — the "Your
/// sermons" backlink card on person/place/event/topic/passage pages.
///
/// Served from the persisted `document_references` index: a passage match is
/// a stored scripture citation whose chapter span covers the target (a
/// chapter- or range-citation counts, not just an exact verse match); a
/// person/place/event/topic match is the exact `sbent:` link the sermon
/// editor's "Link to Explorer" action stores — free-text dataset names are
/// too collision-prone to detect by scanning prose.
final explorerSermonsProvider =
    FutureProvider.family<List<SearchResult>, ExplorerRef>(
  (ref, target) => _documentsReferencing(
    ref,
    target,
    docType: kDocTypeSermon,
    docTable: 'sermons',
  ),
);

/// The user's own notebook pages that reference an Explorer entity — the
/// "Your notebooks" backlink card on person/place/event/topic/passage pages.
/// Same index and matching rules as [explorerSermonsProvider].
final explorerNotebookPagesProvider =
    FutureProvider.family<List<SearchResult>, ExplorerRef>(
  (ref, target) => _documentsReferencing(
    ref,
    target,
    docType: kDocTypeNotebookPage,
    docTable: 'notebook_pages',
  ),
);

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

// --- Tags (your own study data joined into the knowledge web) ---

/// Everything filed under one tag, ready for the tag page: the tagged items
/// split by kind, the distinct chapters the tagged verses fall in (the hop
/// back into the knowledge web), and the tags that co-occur on the same
/// items.
class ExplorerTagDetail {
  final TagData tag;
  final List<SearchResult> verses;
  final List<SearchResult> notes;
  final List<SearchResult> sermons;
  final List<SearchResult> journals;
  final List<SearchResult> prayers;

  /// Notebooks/notebook pages directly filed under this tag.
  final List<SearchResult> notebooks;

  /// Media attachments filed under this tag (images/PDFs), newest first.
  final List<MediaAttachment> media;

  /// Distinct chapters of [verses], in canonical order.
  final List<({String book, int chapter})> passages;

  /// Tags sharing at least one item with this one, most shared first.
  final List<ExplorerTagHit> related;
  ExplorerTagDetail({
    required this.tag,
    required this.verses,
    required this.notes,
    required this.sermons,
    required this.journals,
    required this.prayers,
    required this.notebooks,
    required this.media,
    required this.related,
  }) : passages = _distinctChapters(verses);

  bool get isEmpty =>
      verses.isEmpty &&
      notes.isEmpty &&
      sermons.isEmpty &&
      journals.isEmpty &&
      prayers.isEmpty &&
      notebooks.isEmpty &&
      media.isEmpty;

  static List<({String book, int chapter})> _distinctChapters(
      List<SearchResult> verses) {
    final seen = <String>{};
    return [
      for (final v in verses)
        if (v.book != null && v.chapter != null && seen.add('${v.book}|${v.chapter}'))
          (book: v.book!, chapter: v.chapter!),
    ];
  }
}

/// Media attachments filed under a tag, newest first. A live Drift stream so a
/// title (or other) edit in the reader's Media panel reflects on the tag page
/// without a manual refresh. Media is typed data (filename + mime are needed to
/// open the viewer), so it's fetched here rather than through the SearchResult
/// path in [entitiesForTagProvider].
final explorerTagMediaProvider =
    StreamProvider.family<List<MediaAttachment>, String>((ref, tagId) {
  final db = ref.watch(userStoreProvider);
  final query = db.select(db.mediaAttachments).join([
    innerJoin(
      db.entityTags,
      db.entityTags.entityId.equalsExp(db.mediaAttachments.id),
    ),
  ])
    ..where(db.entityTags.tagId.equals(tagId))
    ..where(db.entityTags.entityType.equals('media_attachment'))
    ..where(db.entityTags.deleted.equals(false))
    ..where(db.mediaAttachments.deleted.equals(false));
  return query.watch().map((rows) {
    final seen = <String>{};
    final media = <MediaAttachment>[];
    for (final row in rows) {
      final a = row.readTable(db.mediaAttachments);
      if (seen.add(a.id)) media.add(a);
    }
    media.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return media;
  });
});

/// Loads a tag's page. Null when the tag doesn't exist (or was deleted,
/// possibly on another device, while sitting in the breadcrumb trail).
final explorerTagDetailProvider =
    FutureProvider.family<ExplorerTagDetail?, String>((ref, tagId) async {
  final db = ref.watch(userStoreProvider);
  final tagRow = await (db.select(db.tags)
        ..where((t) => t.id.equals(tagId) & t.deleted.equals(false)))
      .getSingleOrNull();
  if (tagRow == null) return null;

  final items = await ref.watch(entitiesForTagProvider(tagId).future);
  List<SearchResult> ofType(String type) =>
      [for (final i in items) if (i.type == type) i];

  // Watched (not one-shot) so an attachment edit re-runs the page.
  final media = await ref.watch(explorerTagMediaProvider(tagId).future);
  final verses = ofType('verse')
    ..sort((a, b) {
      final byBook = (a.bookOrder ?? 0).compareTo(b.bookOrder ?? 0);
      if (byBook != 0) return byBook;
      final byChapter = (a.chapter ?? 0).compareTo(b.chapter ?? 0);
      if (byChapter != 0) return byChapter;
      return (a.verse ?? 0).compareTo(b.verse ?? 0);
    });

  final relatedRows = await db.customSelect(
    'SELECT t.id AS id, t.name AS name, t.color_hex AS color_hex, '
    '  COUNT(DISTINCT other.entity_id) AS shared '
    'FROM entity_tags mine '
    'JOIN entity_tags other ON other.entity_id = mine.entity_id '
    '  AND other.tag_id != mine.tag_id AND other.deleted = 0 '
    'JOIN tags t ON t.id = other.tag_id AND t.deleted = 0 '
    'WHERE mine.tag_id = ? AND mine.deleted = 0 '
    'GROUP BY t.id, t.name, t.color_hex '
    'ORDER BY shared DESC, t.name LIMIT 20',
    variables: [Variable.withString(tagId)],
  ).get();

  return ExplorerTagDetail(
    tag: TagData(id: tagRow.id, name: tagRow.name, colorHex: tagRow.colorHex),
    verses: verses,
    notes: ofType('note'),
    sermons: ofType('sermon'),
    journals: ofType('journal'),
    prayers: ofType('prayer'),
    notebooks: [...ofType('notebookPage'), ...ofType('notebook')],
    media: media,
    related: [
      for (final r in relatedRows)
        ExplorerTagHit(
          TagData(
            id: r.read<String>('id'),
            name: r.read<String>('name'),
            colorHex: r.readNullable<String>('color_hex'),
          ),
          r.read<int>('shared'),
        ),
    ],
  );
});

/// A dataset entity (person/place) surfaced from a tag's tagged verses, with
/// the count of tagged verses that mention it.
class ExplorerTagEntityHit {
  final int id;
  final String label;

  /// Optional coordinates (places only) so the tag page can pin a map.
  final double? lat;
  final double? lng;

  /// How many of the tag's tagged verses mention this entity.
  final int verseCount;
  ExplorerTagEntityHit({
    required this.id,
    required this.label,
    required this.verseCount,
    this.lat,
    this.lng,
  });
}

/// Tagged verse numbers grouped by chapter, so a tag-scoped provider queries
/// each chapter once instead of once per verse. Shared by every provider
/// below that cross-references a tag's tagged verses into the bundled
/// datasets or installed content.
Map<({String book, int chapter}), Set<int>> _tagVersesByChapter(
    List<SearchResult> verses) {
  final versesByChapter = <({String book, int chapter}), Set<int>>{};
  for (final v in verses) {
    if (v.book == null || v.chapter == null || v.verse == null) continue;
    (versesByChapter[(book: v.book!, chapter: v.chapter!)] ??= {}).add(v.verse!);
  }
  return versesByChapter;
}

/// The dataset entities (people, places, events, topics) mentioned in a tag's
/// tagged verses — the same cross-referencing the passage page does, but
/// scoped to the exact verses carrying the tag rather than whole chapters.
class ExplorerTagCrossRefs {
  final List<ExplorerTagEntityHit> people;
  final List<ExplorerTagEntityHit> places;
  final List<ExplorerEventHit> events;
  final List<ExplorerTagEntityHit> topics;
  ExplorerTagCrossRefs({
    required this.people,
    required this.places,
    required this.events,
    this.topics = const [],
  });

  bool get isEmpty =>
      people.isEmpty && places.isEmpty && events.isEmpty && topics.isEmpty;
}

/// Cross-references a tag's tagged verses into the bundled datasets: the
/// people, places, events, and topics those verses mention. Derived from
/// [explorerTagDetailProvider]'s verse list, so it refreshes when the tag's
/// verses change. Each distinct chapter is resolved through the existing
/// passage lookups (cached) and then filtered down to the tagged verses.
final explorerTagCrossRefsProvider =
    FutureProvider.family<ExplorerTagCrossRefs, String>((ref, tagId) async {
  final detail = await ref.watch(explorerTagDetailProvider(tagId).future);
  const empty = <ExplorerTagEntityHit>[];
  if (detail == null || detail.verses.isEmpty) {
    return ExplorerTagCrossRefs(
        people: empty, places: empty, events: const [], topics: empty);
  }

  final versesByChapter = _tagVersesByChapter(detail.verses);
  if (versesByChapter.isEmpty) {
    return ExplorerTagCrossRefs(
        people: empty, places: empty, events: const [], topics: empty);
  }

  await ref.watch(explorerReadyProvider.future);
  final store = ref.watch(contentStoreProvider);

  final people = <int, ExplorerTagEntityHit>{};
  final places = <int, ExplorerTagEntityHit>{};
  final events = <int, ({ExplorerEventHit hit, int count})>{};
  final topics = <int, ExplorerTagEntityHit>{};

  for (final entry in versesByChapter.entries) {
    final loc = entry.key;
    final tagged = entry.value;

    final chapterPeople = await ref.watch(peopleForPassageProvider(loc).future);
    for (final p in chapterPeople) {
      final matched = p.verses.where(tagged.contains).length;
      if (matched == 0) continue;
      final prev = people[p.id];
      people[p.id] = ExplorerTagEntityHit(
        id: p.id,
        label: p.displayTitle,
        verseCount: (prev?.verseCount ?? 0) + matched,
      );
    }

    final chapterPlaces = await ref.watch(placesForPassageProvider(loc).future);
    for (final pl in chapterPlaces) {
      final matched = pl.verses.where(tagged.contains).length;
      if (matched == 0) continue;
      final prev = places[pl.id];
      places[pl.id] = ExplorerTagEntityHit(
        id: pl.id,
        label: pl.name,
        lat: pl.lat,
        lng: pl.lng,
        verseCount: (prev?.verseCount ?? 0) + matched,
      );
    }

    final eventRows = await store.customSelect(
      'SELECT e.id AS id, e.title AS title, e.start_year AS start_year, '
      '  ev.verse AS verse '
      'FROM event_verses ev '
      'JOIN timeline_events e ON e.id = ev.event_id '
      'WHERE ev.book_name = ? AND ev.chapter = ?',
      variables: [
        Variable.withString(loc.book),
        Variable.withInt(loc.chapter),
      ],
    ).get();
    for (final r in eventRows) {
      if (!tagged.contains(r.read<int>('verse'))) continue;
      final id = r.read<int>('id');
      final prev = events[id];
      events[id] = (
        hit: ExplorerEventHit(
          id,
          r.read<String>('title'),
          r.readNullable<int>('start_year'),
        ),
        count: (prev?.count ?? 0) + 1,
      );
    }

    final topicRows = await store.customSelect(
      'SELECT t.id AS id, t.name AS name, r.verse AS verse, '
      '  r.verse_end AS verse_end '
      'FROM topic_references r '
      'JOIN topics t ON t.id = r.topic_id '
      'WHERE r.book_name = ? AND r.chapter = ?',
      variables: [
        Variable.withString(loc.book),
        Variable.withInt(loc.chapter),
      ],
    ).get();
    for (final r in topicRows) {
      final verse = r.readNullable<int>('verse');
      // A null verse is a whole-chapter reference, so it touches every
      // tagged verse in this chapter; otherwise count the tagged verses the
      // (possibly ranged) reference actually overlaps.
      final matched = verse == null
          ? tagged.length
          : tagged
              .where((v) => v >= verse && v <= (r.readNullable<int>('verse_end') ?? verse))
              .length;
      if (matched == 0) continue;
      final id = r.read<int>('id');
      final prev = topics[id];
      topics[id] = ExplorerTagEntityHit(
        id: id,
        label: r.read<String>('name'),
        verseCount: (prev?.verseCount ?? 0) + matched,
      );
    }
  }

  int byCountThenLabel(ExplorerTagEntityHit a, ExplorerTagEntityHit b) {
    final byCount = b.verseCount.compareTo(a.verseCount);
    if (byCount != 0) return byCount;
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  }

  final peopleList = people.values.toList()..sort(byCountThenLabel);
  final placesList = places.values.toList()..sort(byCountThenLabel);
  final eventsList = events.values.toList()
    ..sort((a, b) {
      // Chronological, undated last — matching the passage page's ordering.
      final ay = a.hit.startYear, by = b.hit.startYear;
      if (ay == null && by == null) {
        return a.hit.title.toLowerCase().compareTo(b.hit.title.toLowerCase());
      }
      if (ay == null) return 1;
      if (by == null) return -1;
      return ay.compareTo(by);
    });

  final topicsList = topics.values.toList()..sort(byCountThenLabel);

  return ExplorerTagCrossRefs(
    people: peopleList,
    places: placesList,
    events: [for (final e in eventsList) e.hit],
    topics: topicsList,
  );
});

/// Installed-commentary entries for a tag's tagged verses (excludes
/// whole-chapter commentary entries, which don't carry a specific verse to
/// scope to) — the same content the passage page's Commentaries card shows,
/// scoped to the exact verses carrying the tag.
final explorerTagCommentariesProvider = FutureProvider.family<
    List<ExplorerCommentarySection>, String>((ref, tagId) async {
  final detail = await ref.watch(explorerTagDetailProvider(tagId).future);
  if (detail == null || detail.verses.isEmpty) return const [];
  final versesByChapter = _tagVersesByChapter(detail.verses);
  if (versesByChapter.isEmpty) return const [];

  final commentaries = await ref.watch(commentariesProvider.future);
  if (commentaries.isEmpty) return const [];
  final store = ref.watch(contentStoreProvider);

  final byCommentary = <int, List<CommentaryEntry>>{};
  for (final entry in versesByChapter.entries) {
    final loc = entry.key;
    final tagged = entry.value;
    final rows = await (store.select(store.commentaryEntries)
          ..where(
            (c) => c.bookName.equals(loc.book) & c.chapter.equals(loc.chapter),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.verse)]))
        .get();
    for (final r in rows) {
      if (r.verse == null || !tagged.contains(r.verse)) continue;
      byCommentary.putIfAbsent(r.commentaryId, () => []).add(r);
    }
  }
  return [
    for (final c in commentaries)
      if (byCommentary[c.id] != null) ExplorerCommentarySection(c, byCommentary[c.id]!),
  ];
});

/// The `cross_references` dataset entries whose source is one of a tag's
/// tagged verses, grouped by source verse — the same content the passage
/// page's Cross-references card shows, scoped to the exact verses carrying
/// the tag rather than the whole chapter.
final explorerTagCrossReferencesProvider =
    FutureProvider.family<List<ExplorerCrossRefGroup>, String>((ref, tagId) async {
  final detail = await ref.watch(explorerTagDetailProvider(tagId).future);
  if (detail == null || detail.verses.isEmpty) return const [];
  final versesByChapter = _tagVersesByChapter(detail.verses);
  if (versesByChapter.isEmpty) return const [];

  final store = ref.watch(contentStoreProvider);
  final byVerse = <int, List<CrossReference>>{};
  for (final entry in versesByChapter.entries) {
    final loc = entry.key;
    final tagged = entry.value;
    final rows = await (store.select(store.crossReferences)
          ..where(
            (c) =>
                c.sourceBookName.equals(loc.book) &
                c.sourceChapter.equals(loc.chapter) &
                c.sourceVerse.isIn(tagged),
          )
          ..orderBy([
            (c) => OrderingTerm.asc(c.sourceVerse),
            (c) => OrderingTerm(expression: c.votes, mode: OrderingMode.desc),
          ]))
        .get();
    for (final r in rows) {
      byVerse.putIfAbsent(r.sourceVerse, () => []).add(r);
    }
  }
  return [
    for (final verse in byVerse.keys.toList()..sort()) ExplorerCrossRefGroup(verse, byVerse[verse]!),
  ];
});

/// One tag used on a chapter's verses, with the verse numbers carrying it.
class ExplorerPassageTag {
  final TagData tag;
  final List<int> verses;
  ExplorerPassageTag(this.tag, this.verses);
}

/// Your tags on one chapter's verses, ordered by first tagged verse. Live, so
/// tagging a verse in the reader shows up when you come back to the Explorer.
final explorerPassageTagsProvider = StreamProvider.family<
    List<ExplorerPassageTag>, ({String book, int chapter})>((ref, loc) {
  final db = ref.watch(userStoreProvider);
  final query = db.select(db.entityTags).join([
    innerJoin(db.tags, db.tags.id.equalsExp(db.entityTags.tagId)),
  ])
    ..where(db.entityTags.entityType.equals('verse'))
    ..where(db.entityTags.entityId.like('Verse:${loc.book}|${loc.chapter}|%'))
    ..where(db.entityTags.deleted.equals(false))
    ..where(db.tags.deleted.equals(false));
  return query.watch().map((rows) {
    final tagsById = <String, TagData>{};
    final versesByTag = <String, Set<int>>{};
    for (final row in rows) {
      final et = row.readTable(db.entityTags);
      final t = row.readTable(db.tags);
      final verse = int.tryParse(et.entityId.split('|').last);
      if (verse == null) continue;
      tagsById[t.id] = TagData(id: t.id, name: t.name, colorHex: t.colorHex);
      (versesByTag[t.id] ??= {}).add(verse);
    }
    return [
      for (final id in tagsById.keys)
        ExplorerPassageTag(tagsById[id]!, versesByTag[id]!.toList()..sort()),
    ]..sort((a, b) {
        final byVerse = a.verses.first.compareTo(b.verses.first);
        if (byVerse != 0) return byVerse;
        return a.tag.name.toLowerCase().compareTo(b.tag.name.toLowerCase());
      });
  });
});

/// The user's verse-anchored tag links as a live stream of parsed refs. The
/// tagged verses are the small side of the entity-verses ∩ tagged-verses
/// intersection, so entity pages filter this list in Dart instead of building
/// thousand-variable IN clauses over a person's verse list.
Stream<List<({TagData tag, String book, int chapter, int verse})>>
    _taggedVerseStream(UserStore db) {
  final query = db.select(db.entityTags).join([
    innerJoin(db.tags, db.tags.id.equalsExp(db.entityTags.tagId)),
  ])
    ..where(db.entityTags.entityType.equals('verse'))
    ..where(db.entityTags.deleted.equals(false))
    ..where(db.tags.deleted.equals(false));
  return query.watch().map((rows) {
    final out = <({TagData tag, String book, int chapter, int verse})>[];
    for (final row in rows) {
      final et = row.readTable(db.entityTags);
      final t = row.readTable(db.tags);
      // entityId is 'Verse:Book|chapter|verse' (see verse_action_bar).
      final sep = et.entityId.indexOf(':');
      if (sep < 0) continue;
      final parts = et.entityId.substring(sep + 1).split('|');
      if (parts.length < 3) continue;
      final chapter = int.tryParse(parts[1]);
      final verse = int.tryParse(parts[2]);
      if (chapter == null || verse == null) continue;
      out.add((
        tag: TagData(id: t.id, name: t.name, colorHex: t.colorHex),
        book: parts[0],
        chapter: chapter,
        verse: verse,
      ));
    }
    return out;
  });
}

/// One of your tags that touches an entity's verses, with the shared refs in
/// the entity's canonical order.
class ExplorerEntityTag {
  final TagData tag;
  final List<({String book, int chapter, int verse})> refs;
  ExplorerEntityTag(this.tag, this.refs);
}

/// Intersects the user's tagged verses with an entity's verse refs, grouping
/// by tag: most shared verses first, refs in [refs]' (canonical) order.
List<ExplorerEntityTag> _tagsOnVerses(
  List<({TagData tag, String book, int chapter, int verse})> tagged,
  List<({String book, int chapter, int verse})> refs,
) {
  if (tagged.isEmpty || refs.isEmpty) return const [];
  final order = <String, int>{};
  for (var i = 0; i < refs.length; i++) {
    final r = refs[i];
    order.putIfAbsent('${r.book}|${r.chapter}|${r.verse}', () => i);
  }
  final tagsById = <String, TagData>{};
  final indicesByTag = <String, Set<int>>{};
  for (final t in tagged) {
    final idx = order['${t.book}|${t.chapter}|${t.verse}'];
    if (idx == null) continue;
    tagsById[t.tag.id] = t.tag;
    (indicesByTag[t.tag.id] ??= {}).add(idx);
  }
  return [
    for (final id in tagsById.keys)
      ExplorerEntityTag(
        tagsById[id]!,
        [for (final i in indicesByTag[id]!.toList()..sort()) refs[i]],
      ),
  ]..sort((a, b) {
      final byCount = b.refs.length.compareTo(a.refs.length);
      if (byCount != 0) return byCount;
      return a.tag.name.toLowerCase().compareTo(b.tag.name.toLowerCase());
    });
}

/// Your tags on verses where a person appears. A stream (of the tag links)
/// so tagging a verse in the reader shows up on the person's page; the
/// person's own verse list is static content data, read once per emission.
final explorerPersonTagsProvider =
    StreamProvider.family<List<ExplorerEntityTag>, int>((ref, personId) {
  final db = ref.watch(userStoreProvider);
  return _taggedVerseStream(db).asyncMap((tagged) async {
    if (tagged.isEmpty) return const <ExplorerEntityTag>[];
    final d = await ref.read(personDetailProvider(personId).future);
    if (d == null) return const <ExplorerEntityTag>[];
    return _tagsOnVerses(tagged, [
      for (final v in d.verses)
        (book: v.bookName, chapter: v.chapter, verse: v.verse),
    ]);
  });
});

/// Your tags on verses that mention a place. See [explorerPersonTagsProvider].
final explorerPlaceTagsProvider =
    StreamProvider.family<List<ExplorerEntityTag>, int>((ref, placeId) {
  final db = ref.watch(userStoreProvider);
  return _taggedVerseStream(db).asyncMap((tagged) async {
    if (tagged.isEmpty) return const <ExplorerEntityTag>[];
    final d = await ref.read(explorerPlaceDetailProvider(placeId).future);
    if (d == null) return const <ExplorerEntityTag>[];
    return _tagsOnVerses(tagged, [
      for (final v in d.verses)
        (book: v.bookName, chapter: v.chapter, verse: v.verse),
    ]);
  });
});

/// Your tags on verses in an event's account. See
/// [explorerPersonTagsProvider].
final explorerEventTagsProvider =
    StreamProvider.family<List<ExplorerEntityTag>, int>((ref, eventId) {
  final db = ref.watch(userStoreProvider);
  return _taggedVerseStream(db).asyncMap((tagged) async {
    if (tagged.isEmpty) return const <ExplorerEntityTag>[];
    final d = await ref.read(explorerEventDetailProvider(eventId).future);
    if (d == null) return const <ExplorerEntityTag>[];
    return _tagsOnVerses(tagged, [
      for (final v in d.verses)
        (book: v.bookName, chapter: v.chapter, verse: v.verse),
    ]);
  });
});
