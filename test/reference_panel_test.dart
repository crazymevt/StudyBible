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

/// Renders the Reference panel against in-memory stores: the tabbed Kings &
/// Reigns / Measures & Money lists, each grouped by category with search,
/// a detail view, and passage-chip navigation. Modeled on
/// feasts_panel_test.dart.
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

  // Both tabs' TextFields can coexist in the tree (TabBarView keeps
  // neighboring pages built), so find by hint text rather than by type.
  Finder searchFieldWithHint(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  const kingsHint = 'Search kings & reigns (e.g. Hezekiah, Babylon)…';
  const measuresHint = 'Search measures & money (e.g. cubit, denarius)…';

  testWidgets('lists kings grouped by realm', (tester) async {
    await pumpPanel(tester);

    expect(find.text('Reference'), findsOneWidget);
    expect(find.text('Kings & Reigns'), findsOneWidget);
    expect(find.text('Measures & Money'), findsOneWidget);
    expect(find.text('UNITED KINGDOM'), findsOneWidget);
    expect(find.text('NORTHERN KINGDOM (ISRAEL)'), findsOneWidget);
    expect(find.text('SOUTHERN KINGDOM (JUDAH)'), findsOneWidget);
    expect(find.textContaining('David'), findsWidgets);
  });

  testWidgets('search filters the kings list', (tester) async {
    await pumpPanel(tester);

    await tester.enterText(searchFieldWithHint(kingsHint), 'Hezekiah');
    await tester.pumpAndSettle();

    expect(find.text('Hezekiah — King'), findsOneWidget);
    expect(find.textContaining('David'), findsNothing);
  });

  testWidgets('opening a king shows notes and citations', (tester) async {
    await pumpPanel(tester);

    await tester.enterText(searchFieldWithHint(kingsHint), 'Hezekiah');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hezekiah — King'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sennacherib'), findsOneWidget);
    expect(find.text('2 Kings 18:1-6'), findsOneWidget);
  });

  testWidgets('tapping a king passage navigates the reader to it', (
    tester,
  ) async {
    final container = await pumpPanel(tester);

    await tester.enterText(searchFieldWithHint(kingsHint), 'Hezekiah');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hezekiah — King'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 Kings 18:1-6'));
    await tester.pumpAndSettle();

    expect(container.read(selectedBookNameProvider), '2 Kings');
    expect(container.read(selectedChapterProvider), 18);
    expect(container.read(targetVerseToScrollProvider), 1);
  });

  testWidgets(
      'a hand-verified king shows an Open in Explorer button, an unverified one does not',
      (tester) async {
    await pumpPanel(tester);

    await tester.enterText(searchFieldWithHint(kingsHint), 'David');
    await tester.pumpAndSettle();
    await tester.tap(find.text('David — King'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Open in Explorer'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.enterText(searchFieldWithHint(kingsHint), 'Hezekiah');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hezekiah — King'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Open in Explorer'), findsNothing);
  });

  testWidgets('Measures & Money tab lists units grouped by category', (
    tester,
  ) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Measures & Money'));
    await tester.pumpAndSettle();

    expect(find.text('LENGTH'), findsOneWidget);
    expect(find.text('MONEY'), findsOneWidget);
    expect(find.text('Cubit'), findsOneWidget);
  });

  testWidgets('search filters the measures list', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Measures & Money'));
    await tester.pumpAndSettle();
    await tester.enterText(searchFieldWithHint(measuresHint), 'Denarius');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Denarius'), findsOneWidget);
    expect(find.text('Cubit'), findsNothing);
  });

  testWidgets('opening a measure shows notes and citations', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Measures & Money'));
    await tester.pumpAndSettle();
    await tester.enterText(searchFieldWithHint(measuresHint), 'Denarius');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Denarius'));
    await tester.pumpAndSettle();

    expect(find.textContaining('vineyard'), findsOneWidget);
    expect(find.text('Matthew 20:2'), findsOneWidget);
  });

  testWidgets('tapping a measure passage navigates the reader to it', (
    tester,
  ) async {
    final container = await pumpPanel(tester);

    await tester.tap(find.text('Measures & Money'));
    await tester.pumpAndSettle();
    await tester.enterText(searchFieldWithHint(measuresHint), 'Denarius');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Denarius'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matthew 20:2'));
    await tester.pumpAndSettle();

    expect(container.read(selectedBookNameProvider), 'Matthew');
    expect(container.read(selectedChapterProvider), 20);
    expect(container.read(targetVerseToScrollProvider), 2);
  });

  testWidgets('Covenants tab lists all five covenants', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Covenants'));
    await tester.pumpAndSettle();

    expect(find.text('Noahic Covenant'), findsOneWidget);
    expect(find.text('Abrahamic Covenant'), findsOneWidget);
    expect(find.text('Mosaic Covenant'), findsOneWidget);
    expect(find.text('Davidic Covenant'), findsOneWidget);
    expect(find.text('New Covenant'), findsOneWidget);
  });

  testWidgets('opening a covenant shows its parties, terms, and citations', (
    tester,
  ) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Covenants'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Davidic Covenant'));
    await tester.pumpAndSettle();

    expect(find.textContaining('King David'), findsOneWidget);
    expect(find.textContaining('established forever'), findsOneWidget);
    expect(find.text('2 Samuel 7:12-16'), findsOneWidget);
  });

  testWidgets('tapping a covenant passage navigates the reader to it', (
    tester,
  ) async {
    final container = await pumpPanel(tester);

    await tester.tap(find.text('Covenants'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Davidic Covenant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 Samuel 7:12-16'));
    await tester.pumpAndSettle();

    expect(container.read(selectedBookNameProvider), '2 Samuel');
    expect(container.read(selectedChapterProvider), 7);
    expect(container.read(targetVerseToScrollProvider), 12);
  });

  testWidgets('Named Groups tab defaults to the 12 tribes', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Named Groups'));
    await tester.pumpAndSettle();

    expect(find.text('Reuben'), findsOneWidget);
    expect(find.text('Judah'), findsOneWidget);
    expect(find.text('Benjamin'), findsOneWidget);
  });

  testWidgets('switching the sub-list shows the 12 apostles', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Named Groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12 Apostles'));
    await tester.pumpAndSettle();

    expect(find.text('Simon Peter'), findsOneWidget);
    expect(find.text('Judas Iscariot'), findsOneWidget);
    expect(find.text('Reuben'), findsNothing);
  });

  testWidgets('opening a named-group entry shows notes and citations', (
    tester,
  ) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Named Groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12 Apostles'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Simon Peter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Denied Jesus'), findsOneWidget);
    expect(find.text('John 21:15-17'), findsOneWidget);
  });

  testWidgets('tapping a named-group passage navigates the reader to it', (
    tester,
  ) async {
    final container = await pumpPanel(tester);

    await tester.tap(find.text('Named Groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12 Apostles'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Simon Peter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('John 21:15-17'));
    await tester.pumpAndSettle();

    expect(container.read(selectedBookNameProvider), 'John');
    expect(container.read(selectedChapterProvider), 21);
    expect(container.read(targetVerseToScrollProvider), 15);
  });

  testWidgets(
      'a hand-verified apostle shows an Open in Explorer button, an unverified tribe does not',
      (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Named Groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Reuben'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Open in Explorer'), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('12 Apostles'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Simon Peter'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Open in Explorer'), findsOneWidget);
  });
}
