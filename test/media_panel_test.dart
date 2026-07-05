import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/reader/media_panel.dart';

void main() {
  testWidgets('MediaPanel loads', (WidgetTester tester) async {
    // An in-memory user store so chapterAttachmentsProvider (a live Drift
    // stream) has a real DB to watch. Owned by the test and disposed in
    // addTearDown — an UncontrolledProviderScope keeps the container out of the
    // widget lifecycle so the stream's teardown timer doesn't trip the
    // pending-timer check when the tree unmounts.
    final userStore = UserStore(NativeDatabase.memory());
    addTearDown(userStore.close);
    final container = ProviderContainer(
      overrides: [userStoreProvider.overrideWithValue(userStore)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: MediaPanel(bookName: 'Genesis', chapter: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Media'), findsOneWidget);
  });
}
