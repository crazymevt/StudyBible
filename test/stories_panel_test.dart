import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/curated_topics_importer.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/reader/stories_panel.dart';

/// Renders the Stories panel against the real bundled curated-story data: the
/// searchable list of Bible stories, a story's detail view, and tapping a
/// passage chip navigating the reader to it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentStore contentStore;
  late UserStore userStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    contentStore = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());
    // Runs the real curated importer directly instead of going through
    // topicalIndexReadyProvider, which would import Nave's entire
    // ~5,000-topic index and blow past pumpAndSettle's timeout.
    await CuratedTopicsImporter(contentStore).ensureLoaded();
  });

  tearDown(() async {
    await contentStore.close();
    await userStore.close();
  });

  Future<ProviderContainer> pumpPanel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(contentStore),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Data's already imported above; skip the real (slow) import chain.
        topicalIndexReadyProvider.overrideWith((ref) async => true),
        curatedTopicsReadyProvider.overrideWith((ref) async => true),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: StoriesPanel())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('lists Bible stories, title-cased', (tester) async {
    await pumpPanel(tester);

    expect(find.text('Bible Stories'), findsOneWidget);
    // Unfiltered, the 449 curated stories overflow one screen, so filter to
    // bring specific entries into the lazily-built ListView.
    await tester.enterText(find.byType(TextField), 'Creation');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Creation'), findsOneWidget);
  });

  testWidgets('search filters the list', (tester) async {
    await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'Goliath');
    await tester.pumpAndSettle();

    expect(find.text('David And Goliath'), findsOneWidget);
    expect(find.text('Creation'), findsNothing);
  });

  testWidgets('opening a story shows its description and passages', (
    tester,
  ) async {
    await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'Creation');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Creation'));
    await tester.pumpAndSettle();

    expect(find.textContaining('rests on the seventh'), findsOneWidget);
    expect(find.text('Genesis 1'), findsOneWidget);
    expect(find.text('Genesis 2:1-3'), findsOneWidget);
  });

  testWidgets('tapping a passage navigates the reader to it', (tester) async {
    final container = await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'Goliath');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'David And Goliath'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 Samuel 17'));
    await tester.pumpAndSettle();

    expect(container.read(selectedBookNameProvider), '1 Samuel');
    expect(container.read(selectedChapterProvider), 17);
    expect(container.read(targetVerseToScrollProvider), 1);
  });
}
