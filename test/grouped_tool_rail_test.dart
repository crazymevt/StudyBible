import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:study_bible/app/app_state.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/ui/grouped_tool_rail.dart';

void main() {
  Future<ProviderContainer> pumpRail(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
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

  testWidgets('shows default pinned tools and an edit button', (tester) async {
    await pumpRail(tester);

    // Default pinned tools: notes, highlights, scratch, sermons, notebooks, commentaries, media
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.text('Scratch'), findsOneWidget);
    expect(find.text('Sermons'), findsOneWidget);
    expect(find.text('Notebooks'), findsOneWidget);
    expect(find.text('Commentary'), findsOneWidget); // railLabel
    expect(find.text('Media'), findsOneWidget);

    // One divider before the edit button
    expect(find.byType(Divider), findsOneWidget);

    // Has edit button
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('tapping a tool selects it and tapping again closes it', (
    tester,
  ) async {
    final container = await pumpRail(tester);

    await tester.tap(find.text('Notes'));
    await tester.pump();
    expect(container.read(activeToolProvider), ActiveTool.notes);

    await tester.tap(find.text('Notes'));
    await tester.pump();
    expect(container.read(activeToolProvider), ActiveTool.none);
  });

  testWidgets('natural height fits a typical laptop window without scrolling', (
    tester,
  ) async {
    await pumpRail(tester);

    // With 7 default pinned tools and generous padding, it should still
    // comfortably fit inside a typical laptop window (< 730px).
    final height = tester.getSize(find.byType(GroupedToolRail)).height;
    expect(height, lessThan(730));
  });

  testWidgets('tools further down the rail are reachable and selectable', (
    tester,
  ) async {
    final container = await pumpRail(tester);

    await tester.scrollUntilVisible(find.text('Media'), 100);
    await tester.tap(find.text('Media'));
    await tester.pump();
    expect(container.read(activeToolProvider), ActiveTool.media);
  });

  testWidgets('edit button opens dialog to edit pinned favorites', (
    tester,
  ) async {
    await pumpRail(tester);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('Edit Favorites'), findsOneWidget);

    // Toggle off Notes
    await tester.tap(find.text('Notes').last);
    await tester.pumpAndSettle();

    // Toggle on Topics
    final topicsFinder = find.text('Topics');
    await tester.ensureVisible(topicsFinder);
    await tester.pumpAndSettle();
    await tester.tap(topicsFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsNothing); // Removed
    expect(find.text('Topics'), findsOneWidget); // Added
  });
}
