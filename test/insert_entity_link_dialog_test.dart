import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';
import 'package:study_bible/ui/notebooks/insert_entity_link_dialog.dart';

/// Regression coverage for a crash found by manual testing: this dialog used
/// to mirror its query into the Explorer's *global* search state
/// (`explorerSearchQueryProvider`) and restore it in `dispose()` — but
/// `dispose()` can run after the widget (or the provider itself, once the
/// container is tearing down) is already gone, and Riverpod forbids touching
/// `ref`/a notifier at that point. The dialog now keeps its query as plain
/// local state and searches via `explorerSearchResultsForProvider`, a
/// `.family` keyed on the query string — no shared state to restore, so
/// there's nothing left to get wrong on teardown.
void main() {
  late ContentStore store;
  late UserStore userStore;

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());
    await store
        .into(store.biblePeople)
        .insert(
          const BiblePeopleCompanion(
            id: Value(1),
            slug: Value('saul'),
            name: Value('Saul'),
            displayTitle: Value('Saul'),
            verseCount: Value(1),
          ),
        );
  });

  tearDown(() async {
    await store.close();
    await userStore.close();
  });

  Future<({ProviderContainer container, ExplorerRef? Function() picked})>
  pumpAndOpen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
        peopleReadyProvider.overrideWith((ref) async => true),
        placesReadyProvider.overrideWith((ref) async => true),
        topicalIndexReadyProvider.overrideWith((ref) async => true),
      ],
    );
    addTearDown(container.dispose);

    ExplorerRef? picked;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                picked = await InsertEntityLinkDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return (container: container, picked: () => picked);
  }

  testWidgets('typing then cancelling closes cleanly without a ref-in-dispose '
      'crash', (tester) async {
    await pumpAndOpen(tester);

    await tester.enterText(find.byType(TextField), 'Saul');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Saul'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('picking a result returns its ExplorerRef and closes cleanly', (
    tester,
  ) async {
    final opened = await pumpAndOpen(tester);

    await tester.enterText(find.byType(TextField), 'Saul');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Saul'));
    await tester.pumpAndSettle();

    expect(opened.picked(), const ExplorerRef.person(1, 'Saul'));
    expect(tester.takeException(), isNull);
  });
}
