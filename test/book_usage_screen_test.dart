import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/dashboard/book_chapter_usage_screen.dart';
import 'package:study_bible/ui/dashboard/book_usage_screen.dart';

/// The full-screen 66-book breakdown: it always renders every canonical
/// book (studied or not), visually distinguishes zero-activity books, and
/// drills into a per-book chapter screen on tap rather than jumping straight
/// to the Reader.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ContentStore store;
  late UserStore userStore;

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
    await store.close();
    await userStore.close();
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BookUsageScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders all 66 canonical books', (tester) async {
    await pump(tester);

    expect(find.text('Genesis'), findsOneWidget);
    expect(find.textContaining('66 books'), findsOneWidget);

    // The list is lazily built (ListView.builder); scroll to confirm the
    // last canonical book is actually part of it, not just the summary text.
    await tester.scrollUntilVisible(
      find.text('Revelation'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Revelation'), findsOneWidget);
  });

  testWidgets('a zero-activity book is marked as not studied yet', (
    tester,
  ) async {
    await insertHighlight('Genesis', 1);
    await pump(tester);

    // Genesis has activity; Leviticus (far from any seeded data) does not.
    final leviticusTile = find.ancestor(
      of: find.text('Leviticus'),
      matching: find.byType(InkWell),
    );
    expect(leviticusTile, findsOneWidget);
    expect(
      find.descendant(of: leviticusTile, matching: find.text('Not studied yet')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a book pushes the chapter drill-down, not the reader', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Genesis'));
    await tester.pumpAndSettle();

    expect(find.byType(BookChapterUsageScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Genesis'), findsOneWidget);
  });
}
