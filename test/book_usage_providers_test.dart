import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/book_usage_providers.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/dashboard/book_activity.dart';

/// The "most used book" dashboard feature: per-book/per-chapter aggregation
/// across highlights, notes, and the persisted document-references index
/// (sermons/notebook pages). See [[document_reference_index_test.dart]] for
/// the poll-after-write pattern this reuses — Riverpod 3 pauses stream-backed
/// providers with no listener, and the doc-ref sweep runs asynchronously.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ContentStore store;
  late UserStore userStore;
  late ProviderContainer container;

  Future<void> insertHighlight(String book, int chapter, {int verse = 1}) {
    return userStore.into(userStore.highlights).insert(
          HighlightsCompanion.insert(
            id: '$book-$chapter-$verse-${DateTime.now().microsecondsSinceEpoch}-${book.hashCode}',
            updatedAt: 1,
            deviceId: 'test-device',
            bookName: book,
            chapter: chapter,
            verse: verse,
            colorHex: '#ffff00',
          ),
        );
  }

  Future<void> insertNote(String book, int chapter, {int? verse}) {
    return userStore.into(userStore.notes).insert(
          NotesCompanion.insert(
            id: 'note-$book-$chapter-${verse ?? 0}-${DateTime.now().microsecondsSinceEpoch}',
            updatedAt: 1,
            deviceId: 'test-device',
            bookName: book,
            chapter: chapter,
            verse: Value(verse),
            content: 'a note',
          ),
        );
  }

  Future<void> insertSermon(
    String id,
    String plain, {
    int updatedAt = 1,
  }) {
    final content = jsonEncode([
      {'insert': '$plain\n'},
    ]);
    return userStore.into(userStore.sermons).insert(
          SermonsCompanion(
            id: Value(id),
            createdAt: const Value(0),
            updatedAt: Value(updatedAt),
            deviceId: const Value('test-device'),
            title: Value('Sermon $id'),
            content: Value(content),
            contentPlain: Value(plain),
          ),
        );
  }

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());

    await store.into(store.versions).insert(
          const VersionsCompanion(
            id: Value('KJV'),
            abbreviation: Value('KJV'),
            name: Value('KJV'),
          ),
        );
    await store.into(store.books).insert(
          const BooksCompanion(
            id: Value(1),
            versionId: Value('KJV'),
            name: Value('Romans'),
            bookOrder: Value(45),
            testament: Value('NT'),
          ),
        );

    SharedPreferences.setMockInitialValues({
      'activeVersions': ['KJV'],
    });
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
    await userStore.close();
  });

  /// Listens (so stream-backed providers aren't paused) and polls until the
  /// breakdown for [book] matches [matcher] or times out.
  Future<void> expectBookCounts(String book, Object matcher) async {
    final sub = container.listen(bookActivityBreakdownProvider, (_, _) {});
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (true) {
        try {
          final breakdown =
              await container.read(bookActivityBreakdownProvider.future);
          expect(breakdown[book], matcher);
          return;
        } on TestFailure {
          if (DateTime.now().isAfter(deadline)) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      }
    } finally {
      sub.close();
    }
  }

  /// Same polling shape as [expectBookCounts], for the per-book chapter
  /// breakdown family provider.
  Future<void> expectChapterCounts(String book, Object matcher) async {
    final provider = bookChapterActivityProvider(book);
    final sub = container.listen(provider, (_, _) {});
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (true) {
        try {
          final chapters = await container.read(provider.future);
          expect(chapters, matcher);
          return;
        } on TestFailure {
          if (DateTime.now().isAfter(deadline)) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      }
    } finally {
      sub.close();
    }
  }

  group('bookActivityBreakdownProvider', () {
    test('zero-fills every canonical book with no activity', () async {
      await expectBookCounts(
        'Genesis',
        isA<ActivityCounts>().having((c) => c.isEmpty, 'isEmpty', isTrue),
      );
      await expectBookCounts(
        'Revelation',
        isA<ActivityCounts>().having((c) => c.isEmpty, 'isEmpty', isTrue),
      );
    });

    test('counts highlights and notes per book', () async {
      await insertHighlight('Romans', 8);
      await insertHighlight('Romans', 8, verse: 2);
      await insertNote('Romans', 12);

      await expectBookCounts(
        'Romans',
        isA<ActivityCounts>()
            .having((c) => c.highlights, 'highlights', 2)
            .having((c) => c.notes, 'notes', 1),
      );
    });

    test('counts a sermon citation as a notebook/sermon reference', () async {
      await insertSermon('s1', 'On Romans 8:28 and hope.');
      await expectBookCounts(
        'Romans',
        isA<ActivityCounts>().having((c) => c.sermonRefs, 'sermonRefs', 1),
      );
    });

    test('a sermon citing the same book twice counts once (dedupe)',
        () async {
      await insertSermon('s1', 'Romans 8:28 and also Romans 12:1.');
      await expectBookCounts(
        'Romans',
        isA<ActivityCounts>().having((c) => c.sermonRefs, 'sermonRefs', 1),
      );
    });

    test('soft-deleting a highlight updates counts live', () async {
      await insertHighlight('Romans', 8);
      await expectBookCounts(
        'Romans',
        isA<ActivityCounts>().having((c) => c.highlights, 'highlights', 1),
      );

      await (userStore.update(userStore.highlights)
            ..where((h) => h.bookName.equals('Romans')))
          .write(const HighlightsCompanion(deleted: Value(true)));

      await expectBookCounts(
        'Romans',
        isA<ActivityCounts>().having((c) => c.highlights, 'highlights', 0),
      );
    });
  });

  group('mostUsedBookProvider', () {
    test('is null with an empty database', () {
      expect(container.read(mostUsedBookProvider), isNull);
    });
  });

  group('bookChapterActivityProvider', () {
    test('zero-fills every chapter of the book', () async {
      await expectChapterCounts(
        'Romans',
        allOf(
          hasLength(16), // Romans has 16 chapters
          isA<Map<int, ActivityCounts>>()
              .having((c) => c[1]!.isEmpty, 'chapter 1 isEmpty', isTrue),
        ),
      );
    });

    test('places highlight/note counts on the right chapter', () async {
      await insertHighlight('Romans', 8);
      await insertNote('Romans', 8);
      await insertHighlight('Romans', 12);

      await expectChapterCounts(
        'Romans',
        predicate<Map<int, ActivityCounts>>(
          (chapters) =>
              chapters[8]!.highlights == 1 &&
              chapters[8]!.notes == 1 &&
              chapters[12]!.highlights == 1 &&
              chapters[1]!.isEmpty,
          'chapter 8/12 counts placed correctly, chapter 1 empty',
        ),
      );
    });

    test('a multi-chapter sermon citation counts once per chapter it spans',
        () async {
      await insertSermon('s1', 'Read all of Romans 8-9 this week.');
      await expectChapterCounts(
        'Romans',
        predicate<Map<int, ActivityCounts>>(
          (chapters) =>
              chapters[8]!.sermonRefs == 1 && chapters[9]!.sermonRefs == 1,
          'chapters 8 and 9 both have one sermon reference',
        ),
      );
    });
  });
}
