import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/domain/sermons/sermon_reading_time.dart';
import 'package:study_bible/ui/common/reference_autolink.dart';
import 'package:study_bible/ui/sermons/sermon_reading_time_estimator.dart';

// Verse 17 is deliberately long — if a single-verse citation ("John 3:16", no
// range) ever regressed into reading to the end of the chapter, this filler
// would silently balloon the estimate and the "no range" test below would
// catch it.
const _verse16 = 'For God so loved the world that he gave his only Son.';
const _verse17 =
    'For God did not send his Son into the world to condemn the world but '
    'that the world through him might be saved amen amen amen amen amen '
    'amen amen amen amen amen amen amen amen amen amen amen amen amen.';
const _verse18 = 'Whoever believes in him is not condemned.';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ContentStore content;
  late Book john;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'activeVersions': ['NLT'],
    });
    prefs = await SharedPreferences.getInstance();

    content = ContentStore(NativeDatabase.memory());
    await content
        .into(content.versions)
        .insert(
          const VersionsCompanion(
            id: Value('NLT'),
            abbreviation: Value('NLT'),
            name: Value('New Living Translation'),
          ),
        );
    final bookId = await content
        .into(content.books)
        .insert(
          const BooksCompanion(
            versionId: Value('NLT'),
            name: Value('John'),
            bookOrder: Value(43),
            testament: Value('NT'),
          ),
        );
    john = Book(
      id: bookId,
      versionId: 'NLT',
      name: 'John',
      bookOrder: 43,
      testament: 'NT',
    );
    for (final v in [
      (16, _verse16),
      (17, _verse17),
      (18, _verse18),
    ]) {
      await content
          .into(content.verses)
          .insert(
            VersesCompanion.insert(
              bookId: bookId,
              chapter: 3,
              verse: v.$1,
              textContent: v.$2,
              segments: '[]',
            ),
          );
    }
  });

  // A minimal way to obtain a real WidgetRef (estimateSermonReadingTime's
  // signature, matching how the sermon editor calls it) without needing to
  // drive the full Quill editor UI: pump a bare Consumer and capture the ref
  // its builder receives.
  Future<WidgetRef> captureRef(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        contentStoreProvider.overrideWithValue(content),
      ],
    );
    addTearDown(container.dispose);
    late WidgetRef captured;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, r, _) {
              captured = r;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  Document docFromOps(List<Map<String, dynamic>> ops) =>
      Document.fromJson(ops);

  testWidgets('a bare citation adds the looked-up verse\'s word count', (
    tester,
  ) async {
    final ref = await captureRef(tester);

    final url = buildReferenceUrl(john, 3, 16);
    final doc = docFromOps([
      {'insert': 'Please read '},
      {
        'insert': 'John 3:16',
        'attributes': {'link': url},
      },
      {'insert': ' before we begin.\n'},
    ]);

    final estimate = await estimateSermonReadingTime(doc, ref);
    final expected = estimateReadingTime(
      countWords(doc.toPlainText()) + countWords(_verse16),
    );
    expect(estimate, expected);
    // Sanity: the lookup actually added time beyond the bare document text.
    expect(
      estimate,
      greaterThan(estimateReadingTime(countWords(doc.toPlainText()))),
    );
  });

  testWidgets(
    'a citation followed by its own pasted verse text is not double-counted',
    (tester) async {
      final ref = await captureRef(tester);

      final url = buildReferenceUrl(john, 3, 16);
      final doc = docFromOps([
        {
          'insert': 'John 3:16',
          'attributes': {'link': url},
        },
        {'insert': ' - $_verse16\n'},
      ]);

      final estimate = await estimateSermonReadingTime(doc, ref);
      // No addition on top of the document's own word count — the pasted
      // verse text already accounts for itself.
      expect(estimate, estimateReadingTime(countWords(doc.toPlainText())));
    },
  );

  testWidgets(
    'a single-verse citation (no range) does not pull in the next verse',
    (tester) async {
      final ref = await captureRef(tester);

      final url = buildReferenceUrl(john, 3, 16); // no endVerse
      final doc = docFromOps([
        {
          'insert': 'John 3:16',
          'attributes': {'link': url},
        },
        {'insert': '\n'},
      ]);

      final estimate = await estimateSermonReadingTime(doc, ref);
      final expected = estimateReadingTime(
        countWords(doc.toPlainText()) + countWords(_verse16),
      );
      expect(estimate, expected);
      // The long verse 17 filler must not have leaked in.
      final withVerse17 = estimateReadingTime(
        countWords(doc.toPlainText()) + countWords(_verse16) + countWords(_verse17),
      );
      expect(estimate, isNot(equals(withVerse17)));
    },
  );

  testWidgets('a same-chapter range citation sums every verse in it', (
    tester,
  ) async {
    final ref = await captureRef(tester);

    final url = buildReferenceUrl(john, 3, 16, endChapter: 3, endVerse: 18);
    final doc = docFromOps([
      {
        'insert': 'John 3:16-18',
        'attributes': {'link': url},
      },
      {'insert': '\n'},
    ]);

    final estimate = await estimateSermonReadingTime(doc, ref);
    final expected = estimateReadingTime(
      countWords(doc.toPlainText()) +
          countWords(_verse16) +
          countWords(_verse17) +
          countWords(_verse18),
    );
    expect(estimate, expected);
  });
}
