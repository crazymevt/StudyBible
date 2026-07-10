part of 'explorer_providers.dart';

// --- Topic page: aggregated passage facets ---
//
// A topic page previously showed only its own description/refs/"Your
// sermons"/"Your notebooks" — every other facet the passage page has
// (commentaries, cross-references, notes, tags, media) was missing because
// those are all keyed to a single (book, chapter), while a topic spans
// several. The providers below fan the same per-chapter providers out over
// every distinct chapter a topic's entries cite, so the topic page can show
// the same "everything the datasets/your content know" experience.

/// One (book, chapter) a topic's entries cite, plus the specific verses
/// actually referenced there (the union, if more than one ref lands in the
/// same chapter). [verses] is null when some ref for this chapter had no
/// verse bound (a whole-chapter citation) — the whole chapter is then in
/// scope, same as when there's no ref-level detail to narrow by.
///
/// Places carry per-verse detail already (see [PlaceInPassage.verses], the
/// same field the reader's Places panel shows) — narrowing to [verses] is
/// how a story's Places card avoids showing every place mentioned anywhere
/// in the chapter when the story itself only covers a handful of verses.
/// Chapter-granular facets (commentaries, cross-references, notes, tags)
/// stay chapter-wide, matching the passage page they're borrowed from.
class ExplorerTopicLocation {
  final String book;
  final int chapter;
  final Set<int>? verses;

  ExplorerTopicLocation({
    required this.book,
    required this.chapter,
    required this.verses,
  });
}

/// Distinct (book, chapter) locations across all of a topic's entries'
/// references, deduped, in first-seen order, each carrying the verses cited
/// there (see [ExplorerTopicLocation]).
final explorerTopicLocationsProvider =
    FutureProvider.family<List<ExplorerTopicLocation>, int>((
      ref,
      topicId,
    ) async {
      final detail = await ref.watch(topicDetailProvider(topicId).future);
      if (detail == null) return const [];
      final order = <String>[];
      final books = <String, String>{};
      final chapters = <String, int>{};
      final verses = <String, Set<int>?>{};
      for (final entry in detail.entries) {
        for (final r in entry.refs) {
          final key = '${r.bookName}|${r.chapter}';
          if (!verses.containsKey(key)) {
            order.add(key);
            books[key] = r.bookName;
            chapters[key] = r.chapter;
            verses[key] = <int>{};
          }
          final existing = verses[key];
          if (existing == null)
            continue; // already widened to the whole chapter
          if (r.verse == null) {
            verses[key] = null;
          } else {
            final end = r.verseEnd ?? r.verse!;
            existing.addAll([for (var v = r.verse!; v <= end; v++) v]);
          }
        }
      }
      return [
        for (final key in order)
          ExplorerTopicLocation(
            book: books[key]!,
            chapter: chapters[key]!,
            verses: verses[key],
          ),
      ];
    });

/// One chapter's full set of passage-style facets, for aggregating across a
/// topic's several referenced chapters.
class ExplorerTopicLocationFacets {
  final String book;
  final int chapter;
  final List<PlaceInPassage> places;
  final List<ExplorerCommentarySection> commentaries;
  final List<ExplorerCrossRefGroup> crossRefGroups;
  final List<Note> notes;
  final List<ExplorerPassageTag> tags;
  final List<MediaGroup> videoGroups;
  final List<MediaAttachment> attachments;

  ExplorerTopicLocationFacets({
    required this.book,
    required this.chapter,
    required this.places,
    required this.commentaries,
    required this.crossRefGroups,
    required this.notes,
    required this.tags,
    required this.videoGroups,
    required this.attachments,
  });

  bool get isEmpty =>
      places.isEmpty &&
      commentaries.isEmpty &&
      crossRefGroups.isEmpty &&
      notes.isEmpty &&
      tags.isEmpty &&
      videoGroups.isEmpty &&
      attachments.isEmpty;
}

/// A topic's chapter facets are only aggregated up to this many distinct
/// chapters. Hand-curated feasts/stories cite a handful; Nave's Topical
/// Bible headings like "GOD" or "CHURCH" cite thousands of verses across
/// hundreds of chapters, where per-chapter fan-out would be prohibitively
/// expensive and the resulting page unreadable regardless.
const _kTopicPassageFacetCap = 30;

/// Everything the datasets/your content know about every chapter a topic's
/// entries cite — the topic-page equivalent of
/// [explorerPassageOverviewProvider]'s facet providers, fanned out over
/// several locations instead of one. Empty (not partial) once a topic
/// exceeds [_kTopicPassageFacetCap] distinct chapters — see there.
final explorerTopicPassageFacetsProvider =
    FutureProvider.family<List<ExplorerTopicLocationFacets>, int>((
      ref,
      topicId,
    ) async {
      final locations = await ref.watch(
        explorerTopicLocationsProvider(topicId).future,
      );
      if (locations.isEmpty || locations.length > _kTopicPassageFacetCap) {
        return const [];
      }
      // chapterMediaProvider derives synchronously from this; await it once so
      // every location's synchronous watch below sees loaded data, not the
      // provider's "still loading" empty fallback.
      await ref.watch(mediaCollectionsProvider.future);

      final results = await Future.wait([
        for (final loc in locations)
          Future.wait([
            ref.watch(
              placesForPassageProvider((
                book: loc.book,
                chapter: loc.chapter,
              )).future,
            ),
            ref.watch(
              explorerPassageCommentariesProvider((
                book: loc.book,
                chapter: loc.chapter,
              )).future,
            ),
            ref.watch(
              explorerPassageCrossReferencesProvider((
                book: loc.book,
                chapter: loc.chapter,
              )).future,
            ),
            ref.watch(
              chapterNotesFamilyProvider((
                bookName: loc.book,
                chapter: loc.chapter,
              )).future,
            ),
            ref.watch(
              explorerPassageTagsProvider((
                book: loc.book,
                chapter: loc.chapter,
              )).future,
            ),
            ref.watch(
              chapterAttachmentsProvider((
                book: loc.book,
                chapter: loc.chapter,
              )).future,
            ),
          ]).then(
            (r) => ExplorerTopicLocationFacets(
              book: loc.book,
              chapter: loc.chapter,
              places: _placesInScope(r[0] as List<PlaceInPassage>, loc.verses),
              commentaries: r[1] as List<ExplorerCommentarySection>,
              crossRefGroups: r[2] as List<ExplorerCrossRefGroup>,
              notes: r[3] as List<Note>,
              tags: r[4] as List<ExplorerPassageTag>,
              videoGroups: ref.watch(
                chapterMediaProvider((book: loc.book, chapter: loc.chapter)),
              ),
              attachments: r[5] as List<MediaAttachment>,
            ),
          ),
      ]);
      return results.where((r) => !r.isEmpty).toList();
    });

/// Narrows a chapter's places down to the ones actually mentioned in
/// [verses] (null means the whole chapter is in scope — no narrowing). A
/// place's own verse list is trimmed to just the matching verses too, so its
/// subtitle on the topic page reflects the story's citation, not every verse
/// in the chapter that happens to mention it.
List<PlaceInPassage> _placesInScope(
  List<PlaceInPassage> places,
  Set<int>? verses,
) {
  if (verses == null) return places;
  return [
    for (final p in places)
      if (p.verses.any(verses.contains))
        PlaceInPassage(
          id: p.id,
          name: p.name,
          lat: p.lat,
          lng: p.lng,
          verses: p.verses.where(verses.contains).toList(),
        ),
  ];
}

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
    where =
        "r.kind = 'passage' AND r.book_name = ? "
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
    variables = [Variable.withString(target.type.name), Variable.withInt(id)];
  }

  final rows = await db
      .customSelect(
        'SELECT d.id AS id, d.title AS title FROM document_references r '
        'JOIN $docTable d ON d.id = r.doc_id '
        "WHERE r.doc_type = '$docType' AND d.deleted = 0 AND $where "
        'GROUP BY d.id, d.title ORDER BY MAX(d.updated_at) DESC',
        variables: variables,
      )
      .get();
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
final explorerPassageOverviewProvider =
    FutureProvider.family<
      ExplorerPassageOverview,
      ({String book, int chapter})
    >((ref, loc) async {
      await ref.watch(explorerReadyProvider.future);
      final store = ref.watch(contentStoreProvider);

      final peopleFuture = ref.watch(peopleForPassageProvider(loc).future);
      final placesFuture = ref.watch(placesForPassageProvider(loc).future);

      final eventsFuture = store
          .customSelect(
            'SELECT DISTINCT e.id AS id, e.title AS title, e.start_year AS start_year '
            'FROM event_verses ev '
            'JOIN timeline_events e ON e.id = ev.event_id '
            'WHERE ev.book_name = ? AND ev.chapter = ? '
            'ORDER BY e.sort_key IS NULL, e.sort_key',
            variables: [
              Variable.withString(loc.book),
              Variable.withInt(loc.chapter),
            ],
          )
          .get();

      final topicsFuture = store
          .customSelect(
            'SELECT DISTINCT t.id AS id, t.name AS name '
            'FROM topic_references r '
            'JOIN topics t ON t.id = r.topic_id '
            'WHERE r.book_name = ? AND r.chapter = ? '
            'ORDER BY t.name',
            variables: [
              Variable.withString(loc.book),
              Variable.withInt(loc.chapter),
            ],
          )
          .get();

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
