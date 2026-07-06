import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/curated_topics_data.dart';
import 'package:study_bible/data/importer/curated_topics_importer.dart';

/// Runs the real curated importer against the real bundled Nave's Topical
/// Bible data, then exercises the real Explorer topic providers end to end —
/// the same path the Explorer takes for a curated feast/story topic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentStore store;
  late ProviderContainer container;

  setUp(() {
    store = ContentStore(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [contentStoreProvider.overrideWithValue(store)],
    );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  // Counting by category (not by name) matters throughout this file: Nave's
  // Topical Bible already has its own headings that happen to share a name
  // with a curated entry (e.g. "PASSOVER"), and those rows have category ==
  // null, so a name-based count would over-count and mask a broken import.
  test('inserts every curated topic exactly once, idempotently', () async {
    final importer = CuratedTopicsImporter(store);
    await container.read(curatedTopicsReadyProvider.future);
    final topics = await store.select(store.topics).get();
    final curatedRows = topics.where((t) => t.category != null).toList();
    expect(curatedRows.length, curatedTopics.length);

    // Re-running (directly, bypassing the cached provider) must not duplicate.
    await importer.ensureLoaded();
    final recount = await store.select(store.topics).get();
    expect(recount.length, topics.length);
  });

  // Regression: CuratedJourneysImporter used to gate on a single "have we
  // ever run this importer" sentinel, so a persistent on-device DB that
  // already had just the first entry from an early run would skip every
  // entry added afterward, forever. This importer checks each topic's own
  // name individually instead — verify that still holds.
  test('a DB that already has just the first curated topic still gets every '
      'other topic on the next run', () async {
    await container.read(curatedTopicsReadyProvider.future);

    await store.delete(store.topics).go();
    await store.delete(store.topicEntries).go();
    await store.delete(store.topicReferences).go();
    final sentinel = curatedTopics.first;
    await store.into(store.topics).insert(
          TopicsCompanion.insert(
            name: sentinel.name,
            section: sentinel.name[0],
            category: Value(sentinel.category),
          ),
        );

    await CuratedTopicsImporter(store).ensureLoaded();
    final topics = await store.select(store.topics).get();
    final curatedRows = topics.where((t) => t.category != null).toList();
    expect(curatedRows.length, curatedTopics.length);
  });

  test('feasts and stories land in their own categories', () async {
    await container.read(curatedTopicsReadyProvider.future);
    final feasts =
        await container.read(curatedTopicsByCategoryProvider('feast').future);
    final stories = await container.read(
      curatedTopicsByCategoryProvider('story').future,
    );
    expect(feasts.map((t) => t.name), contains('PASSOVER'));
    expect(stories.map((t) => t.name), contains('DAVID AND GOLIATH'));
    expect(stories.map((t) => t.name),
        contains('PETER HEALS THE LAME MAN AT THE TEMPLE'));
    // Nave's own topics are untouched: category stays null.
    final aaron = await (store.select(store.topics)
          ..where((t) => t.name.equals('AARON')))
        .getSingleOrNull();
    expect(aaron?.category, isNull);
  });

  test('each curated topic is searchable via full-text search', () async {
    await container.read(curatedTopicsReadyProvider.future);
    final goliath = await (store.select(store.topics)
          ..where((t) => t.name.equals('DAVID AND GOLIATH')))
        .getSingle();
    final indexed = await store.customSelect(
      "SELECT 1 FROM content_search WHERE type = 'topic' AND reference_id = ?",
      variables: [Variable.withInt(goliath.id)],
    ).get();
    expect(indexed, isNotEmpty);
  });

  test('every curated ref names a book from the canonical book list', () async {
    // Catches a typo'd book name (e.g. "I Samuel" instead of "1 Samuel") that
    // would otherwise silently produce an unopenable verse chip instead of a
    // test failure — naves_topical.json's list is the same canonical English
    // book-name spelling used throughout the app.
    final raw = await rootBundle.loadString('assets/data/naves_topical.json');
    final books = ((jsonDecode(raw) as Map<String, dynamic>)['books'] as List)
        .cast<String>()
        .toSet();
    for (final topic in curatedTopics) {
      for (final ref in topic.refs) {
        expect(books, contains(ref.bookName), reason: topic.name);
      }
    }
  });
}
