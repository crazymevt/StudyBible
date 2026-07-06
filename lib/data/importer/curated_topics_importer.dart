import 'package:drift/drift.dart';
import '../content_store.dart';
import 'curated_topics_data.dart';

/// Inserts the hand-curated feasts and well-known story topics from
/// `curated_topics_data.dart` into the same `topics` / `topic_entries` /
/// `topic_references` tables the bundled Nave's Topical Bible import already
/// populates (see `TopicalImporter`) — the Explorer's topic page and search
/// don't care where a topic came from, so no new query logic is needed, just
/// more data (tagged with a non-null `category` so it can be browsed as its
/// own group, separately from Nave's own entries).
///
/// Runs after `TopicalImporter`, relying on the same trick `CuratedJourneysImporter`
/// uses: inserted rows omit an explicit `id`, so SQLite's AUTOINCREMENT
/// continues past whatever ids Nave's import already used.
class CuratedTopicsImporter {
  CuratedTopicsImporter(this.store);

  final ContentStore store;

  /// Idempotent per topic (not just on the first call): each curated topic is
  /// only inserted if no `topics` row with its exact name *and category*
  /// exists yet, so adding new entries to curated_topics_data.dart is picked
  /// up on a persistent on-device database that already ran an earlier
  /// version of this importer — see CuratedJourneysImporter, which uses the
  /// same trick. Matching on category too (not just name) matters here: Nave's
  /// Topical Bible already has its own "PASSOVER" heading (category null), and
  /// that must not block inserting our distinct curated feast entry of the
  /// same name.
  Future<void> ensureLoaded() async {
    for (final topic in curatedTopics) {
      final existing = await (store.select(store.topics)
            ..where(
              (t) => t.name.equals(topic.name) & t.category.equals(topic.category),
            )
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) continue;

      final topicId = await store.into(store.topics).insert(
            TopicsCompanion.insert(
              name: topic.name,
              section: topic.name.isEmpty ? '' : topic.name[0],
              category: Value(topic.category),
            ),
          );
      final entryId = await store.into(store.topicEntries).insert(
            TopicEntriesCompanion.insert(
              topicId: topicId,
              ordinal: 1,
              description: topic.description,
            ),
          );
      await store.batch((b) {
        b.insertAll(store.topicReferences, [
          for (final r in topic.refs)
            TopicReferencesCompanion.insert(
              topicId: topicId,
              entryId: entryId,
              bookName: r.bookName,
              chapter: r.chapter,
              verse: Value(r.verse),
              verseEnd: Value(r.verseEnd),
            ),
        ]);
      });
      await store.customStatement(
        "INSERT INTO content_search(type, reference_id, text_content) "
        "VALUES ('topic', ?, ?)",
        [topicId, topic.name],
      );
    }
  }
}
