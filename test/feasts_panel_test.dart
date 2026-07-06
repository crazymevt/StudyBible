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
import 'package:study_bible/ui/reader/feasts_panel.dart';

/// Renders the Feasts panel against in-memory stores: the searchable list of
/// biblical feasts, a feast's detail view, and tapping a passage chip
/// navigating the reader to it.
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
    // Tall enough that all 9 feasts render without needing to scroll.
    tester.view.physicalSize = const Size(800, 1400);
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
        child: const MaterialApp(home: Scaffold(body: FeastsPanel())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('lists all feasts with their next occurrence', (tester) async {
    await pumpPanel(tester);

    expect(find.text('Feasts'), findsOneWidget);
    expect(find.text('Passover'), findsOneWidget);
    expect(find.text('Feast of Tabernacles'), findsOneWidget);
    expect(find.textContaining('Next:'), findsWidgets);
  });

  testWidgets('sorts alphabetically by default, and by date on toggle', (
    tester,
  ) async {
    await pumpPanel(tester);

    List<String> titlesInOrder() => tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data!)
        .toList();

    final alpha = titlesInOrder();
    expect(alpha, equals([...alpha]..sort()));
    expect(alpha.first, 'Day of Atonement');

    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();

    final byDate = titlesInOrder();
    expect(byDate, isNot(equals(alpha)));
    // Purim (early March 2026) falls before Passover (April 2026) next.
    expect(byDate.indexOf('Purim'), lessThan(byDate.indexOf('Passover')));
  });

  testWidgets('search filters the list', (tester) async {
    await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'Trumpets');
    await tester.pumpAndSettle();

    expect(find.text('Feast of Trumpets'), findsOneWidget);
    expect(find.text('Passover'), findsNothing);
  });

  testWidgets('opening a feast shows its description and passages', (
    tester,
  ) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Passover'));
    await tester.pumpAndSettle();

    expect(find.textContaining('passing over'), findsOneWidget);
    expect(find.text('Leviticus 23:5'), findsOneWidget);
  });

  testWidgets('tapping a passage navigates the reader to it', (tester) async {
    final container = await pumpPanel(tester);

    await tester.tap(find.text('Passover'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leviticus 23:5'));
    await tester.pumpAndSettle();

    expect(container.read(selectedBookNameProvider), 'Leviticus');
    expect(container.read(selectedChapterProvider), 23);
    expect(container.read(targetVerseToScrollProvider), 5);
  });
}
