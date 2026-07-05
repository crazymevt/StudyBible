import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/notebook_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/notebooks/notebooks_panel.dart';

/// Regression coverage for a bug found by manual testing: with the notebooks
/// panel already showing one page, tapping a *different* page's link from
/// Explorer left the old page on screen instead of switching. The panel built
/// `NotebookPageEditorScreen(pageId: activePageId, ...)` with no `Key`, so
/// when `selectedNotebookPageIdProvider` changed to a new id, Flutter reused
/// the same State — and the editor only loads its content in `initState()`,
/// so the reload never happened. Fixed by keying the editor on the page id
/// (`notebooks_panel.dart`), the same pattern already used for
/// `ExplorerEntityPage` when the Explorer trail advances to a new entity.
void main() {
  late UserStore store;
  late ProviderContainer container;

  setUp(() async {
    store = UserStore(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        userStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) async => 'test-device'),
      ],
    );

    await store
        .into(store.notebooks)
        .insert(
          const NotebooksCompanion(
            id: Value('notebook-1'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            title: Value('Study Notes'),
          ),
        );
    await store
        .into(store.notebookPages)
        .insert(
          const NotebookPagesCompanion(
            id: Value('page-1'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            notebookId: Value('notebook-1'),
            title: Value('On Saul'),
            content: Value('[{"insert":"Saul hides.\\n"}]'),
          ),
        );
    await store
        .into(store.notebookPages)
        .insert(
          const NotebookPagesCompanion(
            id: Value('page-2'),
            createdAt: Value(0),
            updatedAt: Value(0),
            deviceId: Value('test-device'),
            notebookId: Value('notebook-1'),
            title: Value('On the Wilderness'),
            content: Value('[{"insert":"Reflections.\\n"}]'),
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  /// Pumps several frames interleaved with real async turns so in-memory
  /// Drift inserts/streams resolve, mirroring `sermon_lifecycle_test.dart` —
  /// `pumpAndSettle()` fights the Quill editor's own timers/async font loads
  /// in this harness.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpPanel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: NotebooksPanel()),
        ),
      ),
    );
    await settle(tester);
  }

  String visibleTitle(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!.text;

  testWidgets(
    'switching selectedNotebookPageIdProvider to a different page while '
    'the panel is already open loads the new page',
    (tester) async {
      await pumpPanel(tester);

      container.read(selectedNotebookPageIdProvider.notifier).set('page-1');
      await settle(tester);
      expect(visibleTitle(tester), 'On Saul');

      // Same code path an Explorer backlink tap drives: just re-set the
      // provider to a different id while the editor is already mounted.
      container.read(selectedNotebookPageIdProvider.notifier).set('page-2');
      await settle(tester);
      expect(visibleTitle(tester), 'On the Wilderness');
    },
  );
}
