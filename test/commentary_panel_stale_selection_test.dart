import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/ui/reader/commentary_panel.dart';

void main() {
  // Regression test: the "DropdownButton's value: 3" assertion crash. The
  // dropdown's value came straight from selectedCommentaryProvider, which is
  // just a persisted shared_preferences int with no guarantee it still names
  // a commentary in the current list (e.g. reimported with a new id, or a
  // stale synced pref) — so the dropdown could be given a value with zero
  // matching items.
  testWidgets(
    'CommentaryPanel does not crash when the stored selection is stale',
    (tester) async {
      final store = ContentStore(NativeDatabase.memory());
      addTearDown(store.close);
      await store
          .into(store.commentaries)
          .insert(
            CommentariesCompanion.insert(abbreviation: 'MHC', name: 'Matthew Henry'),
          );

      SharedPreferences.setMockInitialValues({
        // Stale id: no commentary in the store has id 3.
        'selectedCommentary': 3,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          contentStoreProvider.overrideWithValue(store),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: CommentaryPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(errors, isEmpty);
      // Self-heals to the only real commentary instead of the stale id.
      expect(container.read(selectedCommentaryProvider), 1);
    },
  );
}
