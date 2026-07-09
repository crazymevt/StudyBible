import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';
import 'package:study_bible/ui/explorer/explorer_screen.dart';
import 'package:study_bible/ui/explorer/family_tree_screen.dart';

/// Drives the family tree screen on seeded data: it renders a node per
/// family member, and tapping a non-root node re-centers by pushing a new
/// instance of the screen.
void main() {
  late ContentStore store;

  Future<void> person(
    int id,
    String name, {
    int? father,
    int? mother,
  }) => store
      .into(store.biblePeople)
      .insert(
        BiblePeopleCompanion(
          id: Value(id),
          slug: Value(name.toLowerCase()),
          name: Value(name),
          displayTitle: Value(name),
          fatherId: Value(father),
          motherId: Value(mother),
          verseCount: const Value(0),
        ),
      );

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());
    await person(1, 'Jacob');
    await person(2, 'Joseph', father: 1);
    await person(3, 'Benjamin', father: 1);
  });

  tearDown(() async {
    await store.close();
  });

  Future<void> pump(WidgetTester tester, int personId) async {
    final container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        peopleReadyProvider.overrideWith((ref) async => true),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: FamilyTreeScreen(personId: personId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders a node for the root and each family member', (
    tester,
  ) async {
    await pump(tester, 1);

    expect(find.widgetWithText(AppBar, 'Jacob'), findsOneWidget);
    expect(find.text('Joseph'), findsOneWidget);
    expect(find.text('Benjamin'), findsOneWidget);
  });

  testWidgets('tapping a non-root node re-centers the chart on them', (
    tester,
  ) async {
    await pump(tester, 1);

    await tester.tap(find.text('Joseph'));
    await tester.pumpAndSettle();

    // A new screen pushed on top, now centered on Joseph.
    expect(find.widgetWithText(AppBar, 'Joseph'), findsOneWidget);
    expect(find.text('Jacob'), findsOneWidget); // Joseph's father, shown above
  });

  testWidgets('a person with no recorded family shows an empty state', (
    tester,
  ) async {
    await person(9, 'Nobody');
    await pump(tester, 9);

    expect(find.text('No recorded family for this person.'), findsOneWidget);
  });

  testWidgets(
    'centers the person the screen was opened for in the viewport, even '
    'when ancestors/descendants push them away from the canvas origin',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // A grandparent above the root pushes the root's own canvas position
      // well away from (0, 0) — without centering, it would render off in a
      // top-left corner the user has to scroll to find.
      await person(500, 'Root', father: 501);
      await person(501, 'Root Father', father: 502);
      await person(502, 'Root Grandfather');
      await person(503, 'Root Child', father: 500);

      await pump(tester, 500);

      // "Root" also appears as the AppBar title; find the node card's copy.
      final rootCenter = tester.getCenter(
        find.descendant(
          of: find.byType(InteractiveViewer),
          matching: find.text('Root'),
        ),
      );
      expect(rootCenter.dx, closeTo(400, 60));
      // Vertically centered within the body (the AppBar sits above it, so
      // compare against the body's own midpoint, not the full 600px window).
      final bodyTop =
          tester.getTopLeft(find.byType(Scaffold)).dy + AppBar().preferredSize.height;
      expect(rootCenter.dy, closeTo((bodyTop + 600) / 2, 60));
    },
  );

  testWidgets(
    '"Close family tree" exits the whole re-center stack in one tap, '
    'not just one level back',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          contentStoreProvider.overrideWithValue(store),
          peopleReadyProvider.overrideWith((ref) async => true),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).push(familyTreeRoute(1)),
                    child: const Text('Open from Explorer'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open from Explorer'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Jacob'), findsOneWidget);

      // Re-center once (family_tree stack is now two deep).
      await tester.tap(find.text('Joseph'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Joseph'), findsOneWidget);

      await tester.tap(find.byTooltip('Close family tree'));
      await tester.pumpAndSettle();

      expect(find.text('Open from Explorer'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Jacob'), findsNothing);
      expect(find.widgetWithText(AppBar, 'Joseph'), findsNothing);
    },
  );

  group('open in Explorer', () {
    late UserStore userStore;

    Future<ProviderContainer> explorerContainer(WidgetTester tester) async {
      userStore = UserStore(NativeDatabase.memory());
      addTearDown(userStore.close);
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
          curatedTopicsReadyProvider.overrideWith((ref) async => true),
          deviceIdProvider.overrideWith((ref) async => 'test-device'),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<ProviderContainer> pumpWithExplorer(
      WidgetTester tester,
      int personId,
    ) async {
      final container = await explorerContainer(tester);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: FamilyTreeScreen(personId: personId)),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('tapping the root card opens it in a fresh Explorer view', (
      tester,
    ) async {
      final container = await pumpWithExplorer(tester, 1);

      // "Jacob" also appears as the AppBar title; tap the node card's copy.
      await tester.tap(
        find.descendant(
          of: find.byType(InteractiveViewer),
          matching: find.text('Jacob'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExplorerScreen), findsOneWidget);
      expect(container.read(explorerTrailProvider), [
        const ExplorerRef.person(1, 'Jacob'),
      ]);
    });

    testWidgets(
      'popping back out of a fresh Explorer (opened from the Reader, not '
      "nested inside another) leaves the trail as browsed, so reopening "
      "Explorer elsewhere resumes it instead of starting over",
      (tester) async {
        final container = await pumpWithExplorer(tester, 1);

        await tester.tap(
          find.descendant(
            of: find.byType(InteractiveViewer),
            matching: find.text('Jacob'),
          ),
        );
        await tester.pumpAndSettle();
        expect(container.read(explorerTrailProvider), [
          const ExplorerRef.person(1, 'Jacob'),
        ]);

        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();

        expect(find.byType(ExplorerScreen), findsNothing);
        expect(container.read(explorerTrailProvider), [
          const ExplorerRef.person(1, 'Jacob'),
        ]);
        expect(container.read(insideExplorerProvider), isFalse);
      },
    );

    testWidgets(
      "the AppBar's \"Open in Explorer\" action does the same",
      (tester) async {
        final container = await pumpWithExplorer(tester, 1);

        await tester.tap(find.widgetWithIcon(IconButton, Icons.explore_outlined));
        await tester.pumpAndSettle();

        expect(find.byType(ExplorerScreen), findsOneWidget);
        expect(container.read(explorerTrailProvider), [
          const ExplorerRef.person(1, 'Jacob'),
        ]);
      },
    );

    testWidgets(
      'long-pressing a non-root node opens it in Explorer directly, '
      'without re-centering the chart first',
      (tester) async {
        final container = await pumpWithExplorer(tester, 1);

        await tester.longPress(find.text('Joseph'));
        await tester.pumpAndSettle();

        expect(find.byType(ExplorerScreen), findsOneWidget);
        expect(container.read(explorerTrailProvider), [
          const ExplorerRef.person(2, 'Joseph'),
        ]);
      },
    );

    testWidgets(
      'backing all the way out of a second Explorer (opened from the '
      "family tree of an already-open one) restores the first one's own "
      "person, not the second one's",
      (tester) async {
        final container = await explorerContainer(tester);
        // Land straight on Jacob's Explorer page, as if already browsed
        // there — the trail is global/session-wide, so this is the state a
        // real, already-open ExplorerScreen would have left behind.
        container
            .read(explorerTrailProvider.notifier)
            .open(const ExplorerRef.person(1, 'Jacob'));
        container.read(insideExplorerProvider.notifier).set(true);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ExplorerScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Jacob'), findsWidgets); // page title + breadcrumb

        // Open Jacob's family tree from his Explorer page.
        await tester.tap(find.byTooltip('View family tree'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(AppBar, 'Jacob'), findsOneWidget);

        // From there, open a *different* person (Joseph) in a second,
        // freshly pushed Explorer.
        await tester.longPress(find.text('Joseph'));
        await tester.pumpAndSettle();
        expect(find.byType(ExplorerScreen), findsOneWidget);
        expect(container.read(explorerTrailProvider), [
          const ExplorerRef.person(2, 'Joseph'),
        ]);

        // Back button twice: out of the second Explorer, then out of the
        // family tree — landing back on the *first* Explorer instance.
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();
        navigator.pop();
        await tester.pumpAndSettle();

        // The first Explorer must show Jacob again, not Joseph.
        expect(find.byType(ExplorerScreen), findsOneWidget);
        expect(container.read(explorerTrailProvider), [
          const ExplorerRef.person(1, 'Jacob'),
        ]);
        expect(find.text('Jacob'), findsWidgets);
      },
    );
  });
}
