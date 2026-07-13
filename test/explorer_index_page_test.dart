import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/thread_walk_providers.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';
import 'package:study_bible/domain/threads/thread_data.dart';
import 'package:study_bible/ui/explorer/explorer_index_page.dart';

/// Exercises the browsable index page's three interactions: the A-Z letter
/// strip filtering to one initial, the sort toggle re-ordering by weight,
/// and a tile tap drilling into the entity via the trail.
void main() {
  const entries = [
    ExplorerIndexEntry(ExplorerRef.person(1, 'Aaron'),
        subtitle: '5 verses', weight: 5),
    ExplorerIndexEntry(ExplorerRef.person(2, 'Abel'),
        subtitle: '2 verses', weight: 2),
    ExplorerIndexEntry(ExplorerRef.person(3, 'Barak'),
        subtitle: '9 verses', weight: 9),
    ExplorerIndexEntry(ExplorerRef.person(4, 'Caleb'),
        subtitle: '1 verse', weight: 1),
  ];

  Future<void> pumpIndex(
    WidgetTester tester, {
    ExplorerEntityType kind = ExplorerEntityType.person,
    String? category,
    List<ExplorerIndexEntry> data = entries,
    Map<String, String> sections = const {},
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          explorerIndexProvider.overrideWith((ref, spec) async => data),
          prophetSectionsProvider.overrideWithValue(sections),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ExplorerIndexPage(kind: kind, category: category),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> visibleTitles(WidgetTester tester) => [
        for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
          ((tile.title as Text).data!),
      ];

  testWidgets('A-Z view groups under letter headers with the count shown',
      (tester) async {
    await pumpIndex(tester);
    expect(find.text('4 people'), findsOneWidget);
    expect(visibleTitles(tester), ['Aaron', 'Abel', 'Barak', 'Caleb']);
    // 'A' appears in the jump strip and again as a group header.
    expect(find.text('A'), findsNWidgets(2));
    expect(find.text('5 verses'), findsOneWidget);
  });

  testWidgets('tapping a strip letter filters to that initial and back',
      (tester) async {
    await pumpIndex(tester);
    await tester.tap(find.widgetWithText(InkWell, 'B').first);
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['Barak']);

    // Same letter again clears the filter.
    await tester.tap(find.widgetWithText(InkWell, 'B').first);
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['Aaron', 'Abel', 'Barak', 'Caleb']);
  });

  testWidgets('rank sort orders by weight and hides the letter strip',
      (tester) async {
    await pumpIndex(tester);
    await tester.tap(find.text('Most verses'));
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['Barak', 'Aaron', 'Abel', 'Caleb']);
    // No group headers or jump strip in rank mode: 'A' no longer appears.
    expect(find.text('A'), findsNothing);
  });

  testWidgets('feast index defaults to the provider\'s calendar order '
      'and offers a Calendar toggle', (tester) async {
    // Deliberately non-alphabetical: the natural (calendar) order must be
    // preserved as given, not re-sorted.
    const feastEntries = [
      ExplorerIndexEntry(ExplorerRef.topic(1, 'PASSOVER')),
      ExplorerIndexEntry(ExplorerRef.topic(2, 'FIRSTFRUITS')),
      ExplorerIndexEntry(ExplorerRef.topic(3, 'DAY OF ATONEMENT')),
    ];
    await pumpIndex(
      tester,
      kind: ExplorerEntityType.topic,
      category: 'feast',
      data: feastEntries,
    );
    expect(find.text('3 feasts'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(
      visibleTitles(tester),
      ['PASSOVER', 'FIRSTFRUITS', 'DAY OF ATONEMENT'],
    );

    await tester.tap(find.text('A–Z'));
    await tester.pumpAndSettle();
    expect(
      visibleTitles(tester),
      ['DAY OF ATONEMENT', 'FIRSTFRUITS', 'PASSOVER'],
    );
  });

  testWidgets('story index is alphabetical only — no sort toggle',
      (tester) async {
    await pumpIndex(
      tester,
      kind: ExplorerEntityType.topic,
      category: 'story',
      data: const [
        ExplorerIndexEntry(ExplorerRef.topic(1, 'CREATION')),
        ExplorerIndexEntry(ExplorerRef.topic(2, 'THE EXODUS')),
      ],
    );
    expect(find.text('2 stories'), findsOneWidget);
    expect(find.text('A–Z'), findsNothing);
    expect(find.text('Most verses'), findsNothing);
  });

  testWidgets('quoted titles file under their first letter, not up front '
      'on the opening quote', (tester) async {
    const data = [
      // Deliberately in the DB's plain ORDER BY order: the quote sorts
      // before 'A', which is exactly the bug the page must correct.
      ExplorerIndexEntry(
          ExplorerRef.topic(1, '"I KNOW THAT MY REDEEMER LIVES"')),
      ExplorerIndexEntry(ExplorerRef.topic(2, 'ABRAHAM AND LOT SEPARATE')),
      ExplorerIndexEntry(ExplorerRef.topic(3, 'JACOB\'S LADDER')),
    ];
    await pumpIndex(
      tester,
      kind: ExplorerEntityType.topic,
      category: 'story',
      data: data,
    );
    expect(visibleTitles(tester), [
      'ABRAHAM AND LOT SEPARATE',
      '"I KNOW THAT MY REDEEMER LIVES"',
      'JACOB\'S LADDER',
    ]);
  });

  testWidgets(
      'typing in the filter field narrows the list and hides the letter '
      'strip', (tester) async {
    await pumpIndex(tester);
    expect(find.byKey(const Key('explorerIndexLetterStrip')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'aa');
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['Aaron']);
    expect(find.text('1 of 4 people'), findsOneWidget);
    // Filtering hides the jump strip and its group headers.
    expect(find.byKey(const Key('explorerIndexLetterStrip')), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['Aaron', 'Abel', 'Barak', 'Caleb']);
    expect(find.text('4 people'), findsOneWidget);
  });

  testWidgets('filter matching is case-insensitive', (tester) async {
    await pumpIndex(tester);
    await tester.enterText(find.byType(TextField), 'BARAK');
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['Barak']);
  });

  testWidgets('tapping a tile opens the entity on the trail', (tester) async {
    await pumpIndex(tester);
    await tester.tap(find.text('Abel'));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ExplorerIndexPage)),
    );
    expect(
      container.read(explorerTrailProvider),
      [const ExplorerRef.person(2, 'Abel')],
    );
  });

  group('prophet section headers', () {
    const prophetEntries = [
      ExplorerIndexEntry(ExplorerRef.topic(1, 'ISAIAH')),
      ExplorerIndexEntry(ExplorerRef.topic(2, 'DANIEL')),
      ExplorerIndexEntry(ExplorerRef.topic(3, 'HOSEA')),
      ExplorerIndexEntry(ExplorerRef.topic(4, 'MALACHI')),
      ExplorerIndexEntry(ExplorerRef.topic(5, 'ELIJAH')),
    ];
    const sections = {
      'ISAIAH': 'Major Prophets',
      'DANIEL': 'Major Prophets',
      'HOSEA': 'Minor Prophets',
      'MALACHI': 'Minor Prophets',
      'ELIJAH': 'Other Prophets',
    };

    testWidgets(
        'Traditional order shows Major/Minor/Other headers grouping the '
        'given order, not alphabetical', (tester) async {
      await pumpIndex(
        tester,
        kind: ExplorerEntityType.topic,
        category: 'prophet',
        data: prophetEntries,
        sections: sections,
      );

      expect(find.text('Traditional order'), findsOneWidget);
      expect(find.text('Major Prophets'), findsOneWidget);
      expect(find.text('Minor Prophets'), findsOneWidget);
      expect(find.text('Other Prophets'), findsOneWidget);
      expect(visibleTitles(tester),
          ['ISAIAH', 'DANIEL', 'HOSEA', 'MALACHI', 'ELIJAH']);
    });

    testWidgets('switching to A-Z hides the section headers', (tester) async {
      await pumpIndex(
        tester,
        kind: ExplorerEntityType.topic,
        category: 'prophet',
        data: prophetEntries,
        sections: sections,
      );

      await tester.tap(find.text('A–Z'));
      await tester.pumpAndSettle();

      expect(find.text('Major Prophets'), findsNothing);
      expect(find.text('Minor Prophets'), findsNothing);
      expect(find.text('Other Prophets'), findsNothing);
      expect(visibleTitles(tester),
          ['DANIEL', 'ELIJAH', 'HOSEA', 'ISAIAH', 'MALACHI']);
    });
  });

  group('thread status badges', () {
    // Real dataset entries: one pre-tracking thread (seeded as seen) and one
    // added after tracking shipped, so the badge logic is exercised against
    // the actual seed list.
    final livingWater = threads.indexWhere((t) => t.id == 'living_water');
    final shepherd = threads.indexWhere((t) => t.id == 'the_shepherd');

    Future<void> pumpThreads(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final sharedPrefs = await SharedPreferences.getInstance();
      final data = [
        ExplorerIndexEntry(
          ExplorerRef.thread(livingWater, threads[livingWater].title),
        ),
        ExplorerIndexEntry(
          ExplorerRef.thread(shepherd, threads[shepherd].title),
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            explorerIndexProvider.overrideWith((ref, spec) async => data),
            prophetSectionsProvider.overrideWithValue(const {}),
            sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExplorerIndexPage(kind: ExplorerEntityType.thread),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'a thread added after tracking wears a New pill; pre-tracking '
        'threads never do', (tester) async {
      await pumpThreads(tester);
      expect(find.text('New'), findsOneWidget);
      final badged = find.ancestor(
        of: find.text('New'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: badged,
          matching: find.text(threads[shepherd].title),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'a seen thread loses the pill and a completed walk shows a check',
        (tester) async {
      await pumpThreads(tester, prefs: {
        kSeenThreadsKey: <String>['the_shepherd', 'living_water'],
        kCompletedThreadWalksKey: <String>['living_water'],
      });
      expect(find.text('New'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('the active walk shows its progress fraction',
        (tester) async {
      await pumpThreads(tester, prefs: {
        kActiveThreadWalkKey: 'living_water|2',
      });
      expect(
        find.text('3/${threads[livingWater].stops.length}'),
        findsOneWidget,
      );
    });
  });
}
