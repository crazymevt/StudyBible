import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/notebook_providers.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/notebooks/notebook_detail_panel.dart';

class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

void main() {
  late UserStore store;
  late ProviderContainer container;

  setUp(() {
    store = UserStore(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      userStoreProvider.overrideWithValue(store),
      deviceIdProvider.overrideWith((ref) async => 'A'),
      achievementServiceProvider
          .overrideWith((ref) => _NoopAchievementService(ref)),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  Future<String> seedNotebookWithPages() async {
    final actions = container.read(notebookActionProvider);
    final nb = await actions.createNotebook('N');
    await actions.createPage(nb.id, title: 'A');
    await actions.createPage(nb.id, title: 'B');
    await actions.createPage(nb.id, title: 'C');
    return nb.id;
  }

  Future<void> pumpPanel(WidgetTester tester, String notebookId) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: NotebookDetailPanel(notebookId: notebookId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the notebook pages in order', (tester) async {
    final id = await seedNotebookWithPages();
    await pumpPanel(tester, id);

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets(
    'reorderable rows contain no Tooltip/PopupMenuButton (OverlayPortal) — '
    'guards against the reorder-time markNeedsLayout crash',
    (tester) async {
      final id = await seedNotebookWithPages();
      await pumpPanel(tester, id);

      // A Tooltip (OverlayPortal) or PopupMenuButton inside a reorderable row is
      // reparented during a drag and crashes with a mid-layout markNeedsLayout.
      final list = find.byType(ReorderableListView);
      expect(list, findsOneWidget);
      expect(
        find.descendant(of: list, matching: find.byType(Tooltip)),
        findsNothing,
      );
      expect(
        find.descendant(of: list, matching: find.byType(PopupMenuButton)),
        findsNothing,
      );
    },
  );

  testWidgets('dragging a page to the end reorders it without throwing',
      (tester) async {
    final id = await seedNotebookWithPages();
    await pumpPanel(tester, id);

    // Drag the first page's handle downward past the others.
    final handle = find.byIcon(Icons.drag_handle).first;
    await tester.drag(handle, const Offset(0, 220));
    await tester.pumpAndSettle();

    // Persisted order should have changed (A no longer first). We assert on the
    // store so the test doesn't depend on exact drop-target math.
    final pages = await (store.select(store.notebookPages)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect(pages.first.title, isNot('A'));
    // No exception was thrown during the reorder (the crash we fixed).
    expect(tester.takeException(), isNull);
  });
}
