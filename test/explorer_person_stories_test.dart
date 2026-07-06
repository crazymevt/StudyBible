import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/data/content_store.dart';

/// A person's page previously had no way to reach the curated stories they
/// appear in — searching David wouldn't surface "David and Goliath" even
/// though it cites the very chapter his person_verses point to. This
/// exercises the join directly: a curated story with a whole-chapter ref
/// (no verse bound) must still match, Nave's own subject headings must be
/// excluded, and a ranged ref must only match verses inside its range.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentStore store;

  Future<int> seedPerson(String name, String bookName, int chapter, int verse) async {
    final id = await store.into(store.biblePeople).insert(
          BiblePeopleCompanion.insert(
            slug: name.toLowerCase(),
            name: name,
            displayTitle: name,
            verseCount: 1,
          ),
        );
    await store.into(store.personVerses).insert(
          PersonVersesCompanion.insert(
            personId: id,
            bookName: bookName,
            chapter: chapter,
            verse: verse,
          ),
        );
    return id;
  }

  tearDown(() async {
    await store.close();
  });

  test('a whole-chapter curated story matches a person mentioned anywhere '
      'in that chapter', () async {
    store = ContentStore(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [contentStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final davidId = await seedPerson('David', '1 Samuel', 17, 40);
    // Runs the real Nave's + curated imports — the exact path production
    // takes, not a stand-in for it (parallels curated_topics_importer_test).
    await container.read(curatedTopicsReadyProvider.future);

    final stories =
        await container.read(explorerPersonStoriesProvider(davidId).future);
    expect(stories.map((s) => s.name), contains('DAVID AND GOLIATH'));
  });

  group('hermetic (real Nave\'s/curated imports stubbed out)', () {
    late ProviderContainer container;

    setUp(() {
      store = ContentStore(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          contentStoreProvider.overrideWithValue(store),
          peopleReadyProvider.overrideWith((ref) async => true),
          placesReadyProvider.overrideWith((ref) async => true),
          topicalIndexReadyProvider.overrideWith((ref) async => true),
          curatedTopicsReadyProvider.overrideWith((ref) async => true),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test("Nave's own subject headings (category null) are excluded",
        () async {
      final davidId = await seedPerson('David', '1 Samuel', 17, 40);
      final topicId = await store.into(store.topics).insert(
            TopicsCompanion.insert(name: 'FAITH', section: 'F'),
          );
      final entryId = await store.into(store.topicEntries).insert(
            TopicEntriesCompanion.insert(
              topicId: topicId,
              ordinal: 1,
              description: 'A faith example.',
            ),
          );
      await store.into(store.topicReferences).insert(
            TopicReferencesCompanion.insert(
              topicId: topicId,
              entryId: entryId,
              bookName: '1 Samuel',
              chapter: 17,
              verse: const Value(40),
            ),
          );

      final stories =
          await container.read(explorerPersonStoriesProvider(davidId).future);
      expect(stories, isEmpty);
    });

    test('a person with no shared verses gets no stories', () async {
      final goliathId = await seedPerson('Goliath', 'Genesis', 1, 1);
      final stories = await container
          .read(explorerPersonStoriesProvider(goliathId).future);
      expect(stories, isEmpty);
    });

    test('a ranged curated story ref only matches verses inside its range',
        () async {
      final topicId = await store.into(store.topics).insert(
            TopicsCompanion.insert(
              name: 'NARROW STORY',
              section: 'N',
              category: const Value('story'),
            ),
          );
      final entryId = await store.into(store.topicEntries).insert(
            TopicEntriesCompanion.insert(
              topicId: topicId,
              ordinal: 1,
              description: 'Covers only verses 1-5.',
            ),
          );
      await store.into(store.topicReferences).insert(
            TopicReferencesCompanion.insert(
              topicId: topicId,
              entryId: entryId,
              bookName: 'Exodus',
              chapter: 3,
              verse: const Value(1),
              verseEnd: const Value(5),
            ),
          );

      final outsideId = await seedPerson('Moses', 'Exodus', 3, 20);
      final outsideStories = await container
          .read(explorerPersonStoriesProvider(outsideId).future);
      expect(outsideStories, isEmpty);

      final insideId = await seedPerson('Aaron', 'Exodus', 3, 2);
      final insideStories = await container
          .read(explorerPersonStoriesProvider(insideId).future);
      expect(insideStories.map((s) => s.name), contains('NARROW STORY'));
    });
  });
}
