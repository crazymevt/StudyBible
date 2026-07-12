import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/explorer_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';
import 'package:study_bible/ui/common/global_search_bar.dart';

/// The global search bar's "Explore:" suggestions — Explorer entities matched
/// by name and opened straight from the autocomplete dropdown.
void main() {
  late ContentStore store;
  late UserStore userStore;

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());
    userStore = UserStore(NativeDatabase.memory());
    await store.into(store.biblePeople).insert(
          const BiblePeopleCompanion(
            id: Value(1),
            slug: Value('saul'),
            name: Value('Saul'),
            displayTitle: Value('Saul'),
            verseCount: Value(1),
          ),
        );
  });

  tearDown(() async {
    await store.close();
    await userStore.close();
  });

  Future<ProviderContainer> pumpSearchBar(
    WidgetTester tester, {
    Future<bool> Function(Ref)? ready,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        userStoreProvider.overrideWithValue(userStore),
        sharedPreferencesProvider.overrideWithValue(prefs),
        explorerReadyProvider.overrideWith(ready ?? (ref) async => true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const GlobalSearchBar()),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('typing an entity name offers an Explore suggestion',
      (tester) async {
    await pumpSearchBar(tester);

    await tester.enterText(find.byType(TextField), 'Saul');
    await tester.pumpAndSettle();

    expect(find.text('Explore: Saul · Person · 1 verse'), findsOneWidget);
  });

  testWidgets('selecting an Explore suggestion opens that entity in the '
      'Explorer', (tester) async {
    final container = await pumpSearchBar(tester);

    await tester.enterText(find.byType(TextField), 'Saul');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore: Saul · Person · 1 verse'));
    // Plain pumps, not pumpAndSettle: the pushed ExplorerScreen's loading
    // shimmer animates forever and would never settle.
    await tester.pump();
    await tester.pump();

    expect(
      container.read(explorerTrailProvider).last,
      const ExplorerRef.person(1, 'Saul'),
    );
    expect(container.read(insideExplorerProvider), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('datasets still importing: suggestions are skipped, not '
      'awaited', (tester) async {
    // A never-completing readiness future: if the search bar awaited the
    // Explorer fan-out (which blocks on readiness) instead of skipping it,
    // the options below would never resolve.
    await pumpSearchBar(tester, ready: (ref) => Completer<bool>().future);

    await tester.enterText(find.byType(TextField), 'Saul');
    // Pump past the fan-out's wait cap so its timeout timer fires and the
    // other (empty, in this bare store) suggestions resolve.
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Explore: '), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two people sharing a name get distinguishable suggestions '
      '(regression: the bundled dataset has ~450 such collisions, e.g. the '
      'prophet Elijah vs. the unrelated Elijah of Ezra 10:21)',
      (tester) async {
    // A second "Saul" — same name as the seeded row, far fewer verses, the
    // way a minor genealogical mention shares a name with a major figure.
    await store.into(store.biblePeople).insert(
          const BiblePeopleCompanion(
            id: Value(2),
            slug: Value('saul_2'),
            name: Value('Saul'),
            displayTitle: Value('Saul'),
            verseCount: Value(37),
          ),
        );
    await pumpSearchBar(tester);

    await tester.enterText(find.byType(TextField), 'Saul');
    await tester.pumpAndSettle();

    expect(find.text('Explore: Saul · Person · 1 verse'), findsOneWidget);
    expect(find.text('Explore: Saul · Person · 37 verses'), findsOneWidget);
  });
}
