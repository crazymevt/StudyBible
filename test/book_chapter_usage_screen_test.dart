import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/app_state.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/dashboard/book_chapter_usage_screen.dart';

/// The per-book chapter drill-down: renders every chapter of the book
/// (studied or not), and tapping a chapter is what actually jumps into the
/// Reader (the book list screen above it only drills down, it never jumps
/// to the Reader directly).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ContentStore store;
  late UserStore userStore;
  late ProviderContainer container;

  Future<void> insertHighlight(String book, int chapter) {
    return userStore.into(userStore.highlights).insert(
          HighlightsCompanion.insert(
            id: 'h-$book-$chapter',
            updatedAt: 1,
            deviceId: 'test-device',
            bookName: book,
            chapter: chapter,
            verse: 1,
            colorHex: '#ffff00',
          ),
        );
  }

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());
  });

  tearDown(() async {
    container.dispose();
    await store.close();
    await userStore.close();
  });

  Future<void> pump(WidgetTester tester, String book) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: BookChapterUsageScreen(bookName: book)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders every chapter of the book', (tester) async {
    await pump(tester, 'Romans'); // Romans has 16 chapters

    expect(find.text('Chapter 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Chapter 16'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Chapter 16'), findsOneWidget);
    expect(find.text('Chapter 17'), findsNothing);
  });

  testWidgets('a zero-activity chapter is marked as not studied yet', (
    tester,
  ) async {
    await insertHighlight('Romans', 8);
    await pump(tester, 'Romans');

    final chapterOneTile = find.ancestor(
      of: find.text('Chapter 1'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(
        of: chapterOneTile,
        matching: find.text('Not studied yet'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a chapter sets the reader selection and module', (
    tester,
  ) async {
    // This screen is pushed as MaterialApp's home route here, so it's
    // already Navigator.isFirst — popUntil(isFirst) is a no-op and the
    // screen stays mounted, exactly like it stays mounted-but-hidden below
    // the real dashboard root when reached via the actual book list → drill
    // down → chapter tap flow. Only the provider state is asserted here.
    await pump(tester, 'Romans');

    await tester.tap(find.text('Chapter 8'));
    await tester.pumpAndSettle();

    expect(container.read(selectedBookNameProvider), 'Romans');
    expect(container.read(selectedChapterProvider), 8);
    expect(container.read(appModuleProvider), AppModule.reader);
  });
}
