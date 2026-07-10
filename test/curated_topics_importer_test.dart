import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/curated_topics_data.dart';
import 'package:study_bible/data/importer/curated_topics_importer.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';

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

  test('tribes/apostles/judges/prophets land in their own categories',
      () async {
    await container.read(curatedTopicsReadyProvider.future);
    final tribes =
        await container.read(curatedTopicsByCategoryProvider('tribe').future);
    final apostles = await container.read(
      curatedTopicsByCategoryProvider('apostle').future,
    );
    final judges =
        await container.read(curatedTopicsByCategoryProvider('judge').future);
    final prophets = await container.read(
      curatedTopicsByCategoryProvider('prophet').future,
    );
    expect(tribes.map((t) => t.name), contains('REUBEN'));
    expect(tribes, hasLength(12));
    expect(apostles.map((t) => t.name), contains('SIMON PETER'));
    expect(apostles, hasLength(12));
    expect(judges.map((t) => t.name), contains('GIDEON'));
    expect(judges, hasLength(13));
    expect(prophets.map((t) => t.name), contains('ISAIAH'));
    expect(prophets.map((t) => t.name), contains('ELIJAH'));
    // 4 major + 12 minor (writing prophets) + 14 other (no book of their own).
    expect(prophets, hasLength(30));
  });

  test('named-group browse order follows the curated order, not alphabetical',
      () async {
    await container.read(curatedTopicsReadyProvider.future);
    Future<List<String>> browse(String category) async {
      final entries = await container.read(explorerIndexProvider(
              (kind: ExplorerEntityType.topic, category: category))
          .future);
      return entries.map((e) => e.ref.label).toList();
    }

    expect(await browse('tribe'), tribeOrder);
    expect(await browse('apostle'), apostleOrder);
    expect(await browse('judge'), judgeOrder);
    expect(await browse('prophet'), prophetOrder);
  });

  test('namedGroupPersonIds values are unique per category', () {
    // Deborah and Samuel are intentionally listed under both 'judge' and
    // 'prophet' (same real person, same id) — uniqueness only needs to hold
    // within a single category's own keys, not globally across categories.
    final byCategory = <String, List<int>>{};
    for (final entry in namedGroupPersonIds.entries) {
      final category = entry.key.split('|').first;
      byCategory.putIfAbsent(category, () => []).add(entry.value);
    }
    for (final entry in byCategory.entries) {
      expect(entry.value.toSet().length, entry.value.length,
          reason: '${entry.key}: ${entry.value}');
    }
  });

  test('prophetSections covers every prophet topic exactly once, '
      'partitioned 4/12/14', () {
    final prophetNames =
        curatedTopics.where((t) => t.category == 'prophet').map((t) => t.name);
    expect(prophetSections.keys.toSet(), prophetNames.toSet());

    final counts = <String, int>{};
    for (final section in prophetSections.values) {
      counts[section] = (counts[section] ?? 0) + 1;
    }
    expect(counts['Major Prophets'], 4);
    expect(counts['Minor Prophets'], 12);
    expect(counts['Other Prophets'], 14);
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
