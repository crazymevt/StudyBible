// Smoke test: boots the real StudyBibleApp and verifies its widget/provider
// graph (theming, localization, routing into the shell) wires up and renders
// without throwing.
//
// The content database and ph4.org catalog are not available in the headless
// test VM, so we override the data-loading providers with empty results. With
// no installed bibles, the shell routes to the onboarding screen — exercising
// the full theme + MainShell build path without touching SQLite or the network.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:study_bible/main.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/content_manager_providers.dart';
import 'package:study_bible/ui/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('App boots into the onboarding shell with no content installed',
      (WidgetTester tester) async {
    // The theme builds its text theme via GoogleFonts; keep it from making
    // (timer-scheduling) network requests for fonts in the headless test VM.
    GoogleFonts.config.allowRuntimeFetching = false;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Own the container so we can dispose it (and drain Drift's async stream
    // cleanup, which schedules a zero-duration timer on close) before the test
    // framework's teardown runs its pending-timer assertion.
    await tester.runAsync(() async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          bibleVersionsProvider.overrideWith((ref) async => []),
          ph4CatalogProvider.overrideWith((ref) async => []),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const StudyBibleApp(),
        ),
      );
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Detach the tree, dispose providers, and let Drift's cleanup timer fire.
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await Future<void>.delayed(Duration.zero);
    });
  });
}
