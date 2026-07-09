import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/reader/reference_panel.dart';

/// Renders the Reference panel against in-memory stores: the searchable
/// kings & reigns list grouped by realm, a king's detail view, and tapping a
/// passage chip navigating the reader to it. Modeled on feasts_panel_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentStore contentStore;
  late UserStore userStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    contentStore = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());
  });

  tearDown(() async {
    await contentStore.close();
    await userStore.close();
  });

  Future<ProviderContainer> pumpPanel(WidgetTester tester) async {
    // Tall enough that all ~73 kings/rulers and their realm headers render
    // without needing to scroll.
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(contentStore),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ReferencePanel())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('lists kings grouped by realm', (tester) async {
    await pumpPanel(tester);

    expect(find.text('Reference'), findsOneWidget);
    expect(find.text('UNITED KINGDOM'), findsOneWidget);
    expect(find.text('NORTHERN KINGDOM (ISRAEL)'), findsOneWidget);
    expect(find.text('SOUTHERN KINGDOM (JUDAH)'), findsOneWidget);
    expect(find.textContaining('David'), findsWidgets);
  });

  testWidgets('search filters the list', (tester) async {
    await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'Hezekiah');
    await tester.pumpAndSettle();

    expect(find.text('Hezekiah — King'), findsOneWidget);
    expect(find.textContaining('David'), findsNothing);
  });

  testWidgets('opening a king shows notes and citations', (tester) async {
    await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'Hezekiah');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hezekiah — King'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sennacherib'), findsOneWidget);
    expect(find.text('2 Kings 18:1-6'), findsOneWidget);
  });

  testWidgets('tapping a passage navigates the reader to it', (tester) async {
    final container = await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'Hezekiah');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hezekiah — King'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 Kings 18:1-6'));
    await tester.pumpAndSettle();

    expect(container.read(selectedBookNameProvider), '2 Kings');
    expect(container.read(selectedChapterProvider), 18);
    expect(container.read(targetVerseToScrollProvider), 1);
  });
}
