import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/journals/prayer_tracker_panel.dart';

class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

void main() {
  late UserStore user;
  late ProviderContainer container;

  setUp(() async {
    user = UserStore(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      userStoreProvider.overrideWithValue(user),
      sharedPreferencesProvider.overrideWithValue(prefs),
      deviceIdProvider.overrideWith((ref) async => 'test-device'),
      achievementServiceProvider
          .overrideWith((ref) => _NoopAchievementService(ref)),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await user.close();
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: PrayerTrackerPanel()),
        ),
      ),
    );
  }

  // Regression test: the header row (title + "Hide Answered" + Add button)
  // overflowed horizontally on real phone widths (~360-430dp), pushing the
  // Add button past the edge of the screen where it couldn't be tapped —
  // manifesting as "adding a prayer doesn't work" on mobile even though the
  // save logic itself was fine. Fixed by making the title Expanded/ellipsis
  // and dropping the "Hide Answered" label to an icon-only Switch on phones.
  for (final size in [const Size(360, 800), const Size(411, 891)]) {
    testWidgets(
        'adding a prayer saves it without layout overflow at ${size.width}x${size.height}',
        (tester) async {
      await pump(tester, size);
      await _settle(tester);
      expect(find.text('No prayers yet'), findsOneWidget);

      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.tap(find.byTooltip('Add Prayer'));
      await tester.pumpAndSettle();
      expect(find.text('Add Prayer'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'For patience');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await _settle(tester);
      await tester.pumpAndSettle();

      expect(find.text('For patience'), findsOneWidget,
          reason: 'the new prayer should appear in the list after saving');
      expect(
        errors.where((e) => e.exceptionAsString().contains('overflowed')),
        isEmpty,
      );
    });
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
}
