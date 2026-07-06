import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/feast_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/journals/journal_editor_panel.dart';
import 'package:study_bible/ui/journals/journals_list_panel.dart';

/// A note on the Journal editor when the entry's day falls on a biblical
/// feast, gated by the "Show Feast Days on Journal Entries" setting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserStore store;

  setUp(() {
    store = UserStore(NativeDatabase.memory());
  });

  tearDown(() async {
    await store.close();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required DateTime date,
  }) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        userStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) async => 'test-device'),
      ],
    );
    addTearDown(container.dispose);

    container.read(selectedJournalDateProvider.notifier).setDate(date);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          home: Scaffold(body: JournalEditorPanel()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return container;
  }

  testWidgets('shows a banner when the entry falls on a feast day', (
    tester,
  ) async {
    // Rosh Hashana (Feast of Trumpets) 2026.
    await pump(tester, date: DateTime(2026, 9, 12));

    expect(find.textContaining('Feast of Trumpets'), findsOneWidget);
  });

  testWidgets('no banner on an ordinary day', (tester) async {
    await pump(tester, date: DateTime(2026, 1, 15));

    expect(find.byIcon(Icons.event), findsNothing);
  });

  testWidgets('"Hide" turns the setting off and removes the banner', (
    tester,
  ) async {
    await pump(tester, date: DateTime(2026, 9, 12));
    expect(find.textContaining('Feast of Trumpets'), findsOneWidget);

    await tester.tap(find.text('Hide'));
    await tester.pump();

    expect(find.textContaining('Feast of Trumpets'), findsNothing);
  });

  testWidgets('the setting being off suppresses the banner entirely', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'showFeastOnJournal': false});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        userStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) async => 'test-device'),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(selectedJournalDateProvider.notifier)
        .setDate(DateTime(2026, 9, 12));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          home: Scaffold(body: JournalEditorPanel()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(container.read(showFeastOnJournalProvider), isFalse);
    expect(find.textContaining('Feast of Trumpets'), findsNothing);
  });
}
