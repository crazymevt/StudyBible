import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/journals/journal_editor_panel.dart';
import 'package:study_bible/ui/journals/journals_list_panel.dart';

/// Opening a journal straight from the Explorer or global search lands in the
/// editor before the journals-list stream has warmed up. The editor used to
/// seed an empty baseline on that cold miss and then mistake the row's first
/// real arrival for a remote edit, raising a false "changed on another device"
/// conflict banner. These tests pin the cold-load path.
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
    required String journalId,
  }) async {
    // A desktop-sized surface so the Quill toolbar row lays out without
    // overflowing.
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

    // Select the journal before the editor builds — mirrors the Explorer /
    // global-search handoff, where the id is set and the module switched with
    // no visit to the Journals tab (so journalsProvider stays cold).
    container.read(selectedJournalIdProvider.notifier).setId(journalId);

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
    // Let the drift streams emit their first rows (avoid pumpAndSettle: the
    // Quill editor's cursor blink never settles).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return container;
  }

  testWidgets(
    'cold-opening a journal loads its content without a false conflict',
    (tester) async {
      final content = jsonEncode([
        {'insert': 'Waited on the LORD instead of my own hand.\n'},
      ]);
      await store
          .into(store.journals)
          .insert(
            JournalsCompanion(
              id: const Value('j-1'),
              updatedAt: const Value(1000),
              deviceId: const Value('test-device'),
              title: const Value('On restraint'),
              content: Value(content),
              contentPlain: const Value(
                'Waited on the LORD instead of my own hand.',
              ),
            ),
          );

      await pump(tester, journalId: 'j-1');

      // The real row was adopted as the load: the title shows, and no conflict
      // banner appeared.
      expect(find.text('On restraint'), findsOneWidget);
      expect(find.textContaining('changed on another device'), findsNothing);
      expect(find.byIcon(Icons.sync_problem), findsNothing);
    },
  );

  testWidgets(
    'a genuine remote edit after a warm load still raises the conflict banner',
    (tester) async {
      final content = jsonEncode([
        {'insert': 'Original body.\n'},
      ]);
      await store
          .into(store.journals)
          .insert(
            JournalsCompanion(
              id: const Value('j-2'),
              updatedAt: const Value(1000),
              deviceId: const Value('test-device'),
              title: const Value('Original title'),
              content: Value(content),
              contentPlain: const Value('Original body.'),
            ),
          );

      await pump(tester, journalId: 'j-2');
      // Baseline is now established from the real row.
      expect(find.text('Original title'), findsOneWidget);

      // Simulate a sync overwriting the row from another device.
      await (store.update(
        store.journals,
      )..where((j) => j.id.equals('j-2'))).write(
        JournalsCompanion(
          title: const Value('Edited elsewhere'),
          content: Value(
            jsonEncode([
              {'insert': 'Rewritten on another device.\n'},
            ]),
          ),
          contentPlain: const Value('Rewritten on another device.'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('changed on another device'), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    },
  );
}
