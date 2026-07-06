import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Regression test: subheadings modules always use MyBible's own book
  // numbering (Genesis=10, Exodus=20, … spaced by 10). An OSIS-imported Bible
  // numbers its books sequentially (1, 2, 3…) instead. When the active Bible
  // is OSIS-imported (as the bundled KJV is), chapterSubheadingsProvider used
  // to compare the two incompatible schemes directly — silently returning no
  // subheadings for most books, and another book's subheadings for the few
  // where the sequential number happened to equal a MyBible book number (e.g.
  // sequential 60 = "1 Peter" colliding with MyBible 60 = "Joshua").
  testWidgets(
    'chapterSubheadingsProvider matches by book name, not the active '
    "Bible's own book-order scheme",
    (tester) async {
      final store = ContentStore(NativeDatabase.memory());
      addTearDown(store.close);

      await store
          .into(store.versions)
          .insert(VersionsCompanion.insert(id: 'KJV', abbreviation: 'KJV', name: 'King James'));
      await store
          .into(store.versions)
          .insert(
            VersionsCompanion.insert(
              id: 'KJV-S.SUBHEADINGS',
              abbreviation: 'KJV-s',
              name: 'KJV Subheadings',
            ),
          );

      // Sequentially-numbered Bible (as an OSIS import would produce): "1
      // Peter" lands on bookOrder 60 purely because it's the 60th book, which
      // coincidentally collides with MyBible's book number for Joshua.
      await store
          .into(store.books)
          .insert(
            BooksCompanion.insert(
              versionId: 'KJV',
              name: '1 Peter',
              bookOrder: 60,
              testament: 'NT',
            ),
          );

      // Subheadings keyed by MyBible's real numbering: 670 = "1 Peter", 60 =
      // "Joshua" (a decoy that must NOT leak into 1 Peter's results).
      await store
          .into(store.subheadings)
          .insert(
            SubheadingsCompanion.insert(
              versionId: 'KJV-S.SUBHEADINGS',
              bookOrder: 670,
              chapter: 5,
              verse: 1,
              textContent: 'Humility and Vigilance',
            ),
          );
      await store
          .into(store.subheadings)
          .insert(
            SubheadingsCompanion.insert(
              versionId: 'KJV-S.SUBHEADINGS',
              bookOrder: 60,
              chapter: 5,
              verse: 1,
              textContent: 'The Canaanites Fear Israel',
            ),
          );

      SharedPreferences.setMockInitialValues({
        'activeVersions': ['KJV'],
        'subheadingsSourceVersionId': 'KJV-S.SUBHEADINGS',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          contentStoreProvider.overrideWithValue(store),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        chapterSubheadingsProvider((bookName: '1 Peter', chapter: 5)).future,
      );

      expect(result[1], ['Humility and Vigilance']);
      expect(
        result.values.expand((v) => v),
        isNot(contains('The Canaanites Fear Israel')),
      );
    },
  );
}
