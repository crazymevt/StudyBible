import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';
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
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          explorerIndexProvider.overrideWith((ref, spec) async => data),
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
}
