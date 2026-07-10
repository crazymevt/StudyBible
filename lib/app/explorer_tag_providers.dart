part of 'explorer_providers.dart';

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
    List<SearchResult> verses,
  ) {
    final seen = <String>{};
    return [
      for (final v in verses)
        if (v.book != null &&
            v.chapter != null &&
            seen.add('${v.book}|${v.chapter}'))
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
      final query =
          db.select(db.mediaAttachments).join([
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
      final tagRow =
          await (db.select(db.tags)
                ..where((t) => t.id.equals(tagId) & t.deleted.equals(false)))
              .getSingleOrNull();
      if (tagRow == null) return null;

      final items = await ref.watch(entitiesForTagProvider(tagId).future);
      List<SearchResult> ofType(String type) => [
        for (final i in items)
          if (i.type == type) i,
      ];

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

      final relatedRows = await db
          .customSelect(
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
          )
          .get();

      return ExplorerTagDetail(
        tag: TagData(
          id: tagRow.id,
          name: tagRow.name,
          colorHex: tagRow.colorHex,
        ),
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
  List<SearchResult> verses,
) {
  final versesByChapter = <({String book, int chapter}), Set<int>>{};
  for (final v in verses) {
    if (v.book == null || v.chapter == null || v.verse == null) continue;
    (versesByChapter[(book: v.book!, chapter: v.chapter!)] ??= {}).add(
      v.verse!,
    );
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
          people: empty,
          places: empty,
          events: const [],
          topics: empty,
        );
      }

      final versesByChapter = _tagVersesByChapter(detail.verses);
      if (versesByChapter.isEmpty) {
        return ExplorerTagCrossRefs(
          people: empty,
          places: empty,
          events: const [],
          topics: empty,
        );
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

        final chapterPeople = await ref.watch(
          peopleForPassageProvider(loc).future,
        );
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

        final chapterPlaces = await ref.watch(
          placesForPassageProvider(loc).future,
        );
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

        final eventRows = await store
            .customSelect(
              'SELECT e.id AS id, e.title AS title, e.start_year AS start_year, '
              '  ev.verse AS verse '
              'FROM event_verses ev '
              'JOIN timeline_events e ON e.id = ev.event_id '
              'WHERE ev.book_name = ? AND ev.chapter = ?',
              variables: [
                Variable.withString(loc.book),
                Variable.withInt(loc.chapter),
              ],
            )
            .get();
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

        final topicRows = await store
            .customSelect(
              'SELECT t.id AS id, t.name AS name, r.verse AS verse, '
              '  r.verse_end AS verse_end '
              'FROM topic_references r '
              'JOIN topics t ON t.id = r.topic_id '
              'WHERE r.book_name = ? AND r.chapter = ?',
              variables: [
                Variable.withString(loc.book),
                Variable.withInt(loc.chapter),
              ],
            )
            .get();
        for (final r in topicRows) {
          final verse = r.readNullable<int>('verse');
          // A null verse is a whole-chapter reference, so it touches every
          // tagged verse in this chapter; otherwise count the tagged verses the
          // (possibly ranged) reference actually overlaps.
          final matched = verse == null
              ? tagged.length
              : tagged
                    .where(
                      (v) =>
                          v >= verse &&
                          v <= (r.readNullable<int>('verse_end') ?? verse),
                    )
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
            return a.hit.title.toLowerCase().compareTo(
              b.hit.title.toLowerCase(),
            );
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
final explorerTagCommentariesProvider =
    FutureProvider.family<List<ExplorerCommentarySection>, String>((
      ref,
      tagId,
    ) async {
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
        final rows =
            await (store.select(store.commentaryEntries)
                  ..where(
                    (c) =>
                        c.bookName.equals(loc.book) &
                        c.chapter.equals(loc.chapter),
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
          if (byCommentary[c.id] != null)
            ExplorerCommentarySection(c, byCommentary[c.id]!),
      ];
    });

/// The `cross_references` dataset entries whose source is one of a tag's
/// tagged verses, grouped by source verse — the same content the passage
/// page's Cross-references card shows, scoped to the exact verses carrying
/// the tag rather than the whole chapter.
final explorerTagCrossReferencesProvider =
    FutureProvider.family<List<ExplorerCrossRefGroup>, String>((
      ref,
      tagId,
    ) async {
      final detail = await ref.watch(explorerTagDetailProvider(tagId).future);
      if (detail == null || detail.verses.isEmpty) return const [];
      final versesByChapter = _tagVersesByChapter(detail.verses);
      if (versesByChapter.isEmpty) return const [];

      final store = ref.watch(contentStoreProvider);
      final byVerse = <int, List<CrossReference>>{};
      for (final entry in versesByChapter.entries) {
        final loc = entry.key;
        final tagged = entry.value;
        final rows =
            await (store.select(store.crossReferences)
                  ..where(
                    (c) =>
                        c.sourceBookName.equals(loc.book) &
                        c.sourceChapter.equals(loc.chapter) &
                        c.sourceVerse.isIn(tagged),
                  )
                  ..orderBy([
                    (c) => OrderingTerm.asc(c.sourceVerse),
                    (c) => OrderingTerm(
                      expression: c.votes,
                      mode: OrderingMode.desc,
                    ),
                  ]))
                .get();
        for (final r in rows) {
          byVerse.putIfAbsent(r.sourceVerse, () => []).add(r);
        }
      }
      return [
        for (final verse in byVerse.keys.toList()..sort())
          ExplorerCrossRefGroup(verse, byVerse[verse]!),
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
final explorerPassageTagsProvider =
    StreamProvider.family<
      List<ExplorerPassageTag>,
      ({String book, int chapter})
    >((ref, loc) {
      final db = ref.watch(userStoreProvider);
      final query =
          db.select(db.entityTags).join([
              innerJoin(db.tags, db.tags.id.equalsExp(db.entityTags.tagId)),
            ])
            ..where(db.entityTags.entityType.equals('verse'))
            ..where(
              db.entityTags.entityId.like('Verse:${loc.book}|${loc.chapter}|%'),
            )
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
          tagsById[t.id] = TagData(
            id: t.id,
            name: t.name,
            colorHex: t.colorHex,
          );
          (versesByTag[t.id] ??= {}).add(verse);
        }
        return [
          for (final id in tagsById.keys)
            ExplorerPassageTag(
              tagsById[id]!,
              versesByTag[id]!.toList()..sort(),
            ),
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
  final query =
      db.select(db.entityTags).join([
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
      ExplorerEntityTag(tagsById[id]!, [
        for (final i in indicesByTag[id]!.toList()..sort()) refs[i],
      ]),
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
