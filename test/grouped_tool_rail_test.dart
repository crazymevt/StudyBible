import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_bible/app/app_state.dart';
import 'package:study_bible/ui/common/tool_groups.dart';
import 'package:study_bible/ui/grouped_tool_rail.dart';

void main() {
  Future<ProviderContainer> pumpRail(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            // The shell hosts the rail in a scroll view (it can be taller
            // than short windows), so the test does too.
            body: SingleChildScrollView(child: GroupedToolRail()),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('shows every tool with a divider between each group',
      (tester) async {
    await pumpRail(tester);

    for (final group in toolGroups) {
      for (final item in group.items) {
        expect(find.text(item.railLabel), findsOneWidget);
      }
    }
    expect(find.byType(Divider), findsNWidgets(toolGroups.length - 1));
  });

  testWidgets('tapping a tool selects it and tapping again closes it',
      (tester) async {
    final container = await pumpRail(tester);

    await tester.tap(find.text('Notes'));
    await tester.pump();
    expect(container.read(activeToolProvider), ActiveTool.notes);

    await tester.tap(find.text('Notes'));
    await tester.pump();
    expect(container.read(activeToolProvider), ActiveTool.none);
  });

  testWidgets('natural height fits a typical laptop window without scrolling',
      (tester) async {
    await pumpRail(tester);

    // The rail lives in a scroll view for genuinely short windows, but its
    // resting height must stay under a typical laptop window's content
    // height (~750px on a 13" MacBook) or every user scrolls to reach the
    // Explore group. Densified metrics put it around 690px; this guards
    // against padding/label changes creeping back over the budget.
    final height = tester.getSize(find.byType(GroupedToolRail)).height;
    expect(height, lessThan(730));
  });

  testWidgets('tools further down the rail are reachable and selectable',
      (tester) async {
    final container = await pumpRail(tester);

    await tester.scrollUntilVisible(find.text('Devotionals'), 100);
    await tester.tap(find.text('Devotionals'));
    await tester.pump();
    expect(container.read(activeToolProvider), ActiveTool.devotionals);
  });
}
