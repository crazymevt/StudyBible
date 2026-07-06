import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';

/// A topic's own facet cards (description/refs/"Your sermons"/"Your
/// notebooks") were the only content on the Explorer topic page — every
/// other passage-page facet (commentaries, cross-references, notes, tags) was
/// missing because those are keyed to a single (book, chapter) while a topic
/// spans however many its entries cite. These tests exercise the aggregation
/// providers that fan those per-chapter facets out across a topic's several
/// referenced chapters directly (no widget pump needed).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentStore store;
  late UserStore userStore;
  late ProviderContainer container;

  setUp(() {
    store = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        userStoreProvider.overrideWithValue(userStore),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
    await userStore.close();
  });

  /// A topic citing two different chapters (Genesis 1 and Genesis 2), each
  /// with its own commentary/cross-reference/note/tag, so aggregation across
  /// locations (not just within one) is actually exercised.
  Future<void> seedTwoChapterTopic() async {
    await store.into(store.topics).insert(
          const TopicsCompanion(
            id: Value(1),
            name: Value('TEST STORY'),
            section: Value('T'),
            category: Value('story'),
          ),
        );
    await store.into(store.topicEntries).insert(
          const TopicEntriesCompanion(
            id: Value(1),
            topicId: Value(1),
            ordinal: Value(1),
            description: Value('A two-chapter test story.'),
          ),
        );
    await store.into(store.topicReferences).insert(
          const TopicReferencesCompanion(
            id: Value(1),
            topicId: Value(1),
            entryId: Value(1),
            bookName: Value('Genesis'),
            chapter: Value(1),
          ),
        );
    await store.into(store.topicReferences).insert(
          const TopicReferencesCompanion(
            id: Value(2),
            topicId: Value(1),
            entryId: Value(1),
            bookName: Value('Genesis'),
            chapter: Value(2),
          ),
        );

    // Genesis 1's facets: a commentary entry and a user note.
    await store.into(store.commentaries).insert(
          const CommentariesCompanion(
            id: Value(1),
            abbreviation: Value('MHC'),
            name: Value('Matthew Henry'),
          ),
        );
    await store.into(store.commentaryEntries).insert(
          const CommentaryEntriesCompanion(
            id: Value(1),
            commentaryId: Value(1),
            bookName: Value('Genesis'),
            chapter: Value(1),
            verse: Value(1),
            textContent: Value('<p>In the beginning.</p>'),
          ),
        );
    await userStore.into(userStore.notes).insert(
          const NotesCompanion(
            id: Value('note-1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            bookName: Value('Genesis'),
            chapter: Value(1),
            verse: Value(1),
            content: Value('The very beginning.'),
          ),
        );

    // A place mentioned in both chapters, so merging is actually exercised
    // (not just per-location passthrough).
    await store.into(store.places).insert(
          const PlacesCompanion(
            id: Value(1),
            name: Value('Eden'),
            lat: Value(35.0),
            lng: Value(45.0),
          ),
        );
    await store.into(store.placeVerses).insert(
          const PlaceVersesCompanion(
            id: Value(1),
            placeId: Value(1),
            bookName: Value('Genesis'),
            chapter: Value(1),
            verse: Value(1),
          ),
        );
    await store.into(store.placeVerses).insert(
          const PlaceVersesCompanion(
            id: Value(2),
            placeId: Value(1),
            bookName: Value('Genesis'),
            chapter: Value(2),
            verse: Value(8),
          ),
        );

    // Genesis 2's facets: a cross-reference and a tag.
    await store.into(store.crossReferences).insert(
          const CrossReferencesCompanion(
            id: Value(1),
            sourceBookName: Value('Genesis'),
            sourceChapter: Value(2),
            sourceVerse: Value(2),
            targetBookName: Value('Exodus'),
            targetChapter: Value(20),
            targetVerse: Value(11),
            votes: Value(1),
          ),
        );
    await userStore.into(userStore.tags).insert(
          const TagsCompanion(
            id: Value('tag-rest'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            name: Value('rest'),
          ),
        );
    await userStore.into(userStore.entityTags).insert(
          const EntityTagsCompanion(
            id: Value('link-1'),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            tagId: Value('tag-rest'),
            entityId: Value('Verse:Genesis|2|2'),
            entityType: Value('verse'),
          ),
        );
  }

  test('locations are the topic\'s distinct (book, chapter) refs, deduped',
      () async {
    await seedTwoChapterTopic();
    final locations =
        await container.read(explorerTopicLocationsProvider(1).future);
    expect(locations.map((l) => (book: l.book, chapter: l.chapter)), [
      (book: 'Genesis', chapter: 1),
      (book: 'Genesis', chapter: 2),
    ]);
    // Both refs in the fixture are whole-chapter (no verse bound).
    expect(locations.map((l) => l.verses), [null, null]);
  });

  test('aggregates commentaries/notes from one chapter and '
      'cross-references/tags from another', () async {
    await seedTwoChapterTopic();
    final facets =
        await container.read(explorerTopicPassageFacetsProvider(1).future);
    expect(facets.length, 2);

    final genesis1 = facets.firstWhere((f) => f.chapter == 1);
    expect(genesis1.commentaries, isNotEmpty);
    expect(genesis1.commentaries.first.commentary.abbreviation, 'MHC');
    expect(genesis1.notes, hasLength(1));
    expect(genesis1.crossRefGroups, isEmpty);
    expect(genesis1.tags, isEmpty);
    expect(genesis1.places.map((p) => p.name), contains('Eden'));

    final genesis2 = facets.firstWhere((f) => f.chapter == 2);
    expect(genesis2.places.map((p) => p.name), contains('Eden'));
    expect(genesis2.crossRefGroups, isNotEmpty);
    expect(genesis2.crossRefGroups.first.refs.first.targetBookName, 'Exodus');
    expect(genesis2.tags, hasLength(1));
    expect(genesis2.tags.first.tag.name, 'rest');
    expect(genesis2.commentaries, isEmpty);
    expect(genesis2.notes, isEmpty);
  });

  test('narrows places to the verses a story\'s ref actually cites, not '
      'every place mentioned anywhere in the chapter', () async {
    await store.into(store.topics).insert(
          const TopicsCompanion(
            id: Value(4),
            name: Value('NARROW STORY'),
            section: Value('N'),
            category: Value('story'),
          ),
        );
    await store.into(store.topicEntries).insert(
          const TopicEntriesCompanion(
            id: Value(3),
            topicId: Value(4),
            ordinal: Value(1),
            description: Value('Only covers verses 1-5.'),
          ),
        );
    // A ref bounded to verses 1-5 — places outside that range shouldn't
    // surface even though they're in the same chapter.
    await store.into(store.topicReferences).insert(
          const TopicReferencesCompanion(
            id: Value(3),
            topicId: Value(4),
            entryId: Value(3),
            bookName: Value('Exodus'),
            chapter: Value(3),
            verse: Value(1),
            verseEnd: Value(5),
          ),
        );

    await store.into(store.places).insert(
          const PlacesCompanion(
            id: Value(2),
            name: Value('Horeb'),
            lat: Value(28.5),
            lng: Value(33.9),
          ),
        );
    await store.into(store.placeVerses).insert(
          const PlaceVersesCompanion(
            id: Value(3),
            placeId: Value(2),
            bookName: Value('Exodus'),
            chapter: Value(3),
            verse: Value(1),
          ),
        );
    await store.into(store.places).insert(
          const PlacesCompanion(
            id: Value(3),
            name: Value('Egypt'),
            lat: Value(26.8),
            lng: Value(30.8),
          ),
        );
    // Outside the cited 1-5 range — must be excluded.
    await store.into(store.placeVerses).insert(
          const PlaceVersesCompanion(
            id: Value(4),
            placeId: Value(3),
            bookName: Value('Exodus'),
            chapter: Value(3),
            verse: Value(20),
          ),
        );

    final locations =
        await container.read(explorerTopicLocationsProvider(4).future);
    expect(locations, hasLength(1));
    expect(locations.first.verses, {1, 2, 3, 4, 5});

    final facets =
        await container.read(explorerTopicPassageFacetsProvider(4).future);
    expect(facets, hasLength(1));
    expect(facets.first.places.map((p) => p.name), ['Horeb']);
    expect(facets.first.places.single.verses, [1]);
  });

  test('a topic with no locations produces no facets', () async {
    await store.into(store.topics).insert(
          const TopicsCompanion(
            id: Value(2),
            name: Value('EMPTY TOPIC'),
            section: Value('E'),
          ),
        );
    final facets =
        await container.read(explorerTopicPassageFacetsProvider(2).future);
    expect(facets, isEmpty);
  });

  test('a topic citing more chapters than the aggregation cap yields no '
      'facets at all (avoids fanning out over huge Nave\'s topics like '
      '"GOD" or "CHURCH")', () async {
    await store.into(store.topics).insert(
          const TopicsCompanion(id: Value(3), name: Value('HUGE TOPIC'), section: Value('H')),
        );
    await store.into(store.topicEntries).insert(
          const TopicEntriesCompanion(
            id: Value(2),
            topicId: Value(3),
            ordinal: Value(1),
            description: Value('Cites 40 different chapters.'),
          ),
        );
    for (var chapter = 1; chapter <= 40; chapter++) {
      await store.into(store.topicReferences).insert(
            TopicReferencesCompanion.insert(
              topicId: 3,
              entryId: 2,
              bookName: 'Psalms',
              chapter: chapter,
            ),
          );
    }
    // Give chapter 1 a real commentary entry, so a non-empty result here
    // would definitely show up rather than just happening to have no data.
    await store.into(store.commentaries).insert(
          const CommentariesCompanion(
            id: Value(1),
            abbreviation: Value('MHC'),
            name: Value('Matthew Henry'),
          ),
        );
    await store.into(store.commentaryEntries).insert(
          const CommentaryEntriesCompanion(
            id: Value(1),
            commentaryId: Value(1),
            bookName: Value('Psalms'),
            chapter: Value(1),
            verse: Value(1),
            textContent: Value('<p>Blessed is the man.</p>'),
          ),
        );

    final facets =
        await container.read(explorerTopicPassageFacetsProvider(3).future);
    expect(facets, isEmpty);
  });
}
