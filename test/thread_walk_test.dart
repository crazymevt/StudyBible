import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/thread_walk_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/scripture/passage_citation.dart';
import 'package:study_bible/domain/threads/thread_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWithPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Navigation records reading history, which touches both stores and
        // the device id — in-memory stand-ins, same as scripture_nav_bar_test.
        contentStoreProvider.overrideWithValue(
          ContentStore(NativeDatabase.memory()),
        ),
        userStoreProvider.overrideWithValue(UserStore(NativeDatabase.memory())),
        deviceIdProvider.overrideWith((ref) async => 'test-device'),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('no stored walk means no active walk', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await containerWithPrefs();
    expect(container.read(threadWalkProvider), isNull);
  });

  test(
      'start, advance, and back persist the walk and steer the reader '
      'without selecting verses', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await containerWithPrefs();
    final notifier = container.read(threadWalkProvider.notifier);

    notifier.start(0);
    expect(container.read(threadWalkProvider)!.stop, 0);

    notifier.advance();
    notifier.advance();
    final walk = container.read(threadWalkProvider)!;
    expect(walk.stop, 2);
    expect(walk.thread.id, threads[0].id);

    // The reader followed the walk to the stop's passage…
    final citation = PassageCitation.parse(walk.currentStop.passage);
    expect(container.read(selectedBookNameProvider), citation.book);
    expect(container.read(selectedChapterProvider), citation.chapter);
    expect(
      container.read(targetVerseToScrollProvider),
      citation.verse ?? 1,
    );
    // …as a temporary nav highlight, never a selection (selections would
    // summon the verse action bar and force a deselect between hops).
    expect(container.read(selectedVersesProvider), isEmpty);
    expect(walk.routeStop, isNotNull);
    expect(walk.routeStop!.bookName, citation.book);

    notifier.back();
    expect(container.read(threadWalkProvider)!.stop, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kActiveThreadWalkKey), '${threads[0].id}|1');

    // Let the fire-and-forget reading-history write finish before the
    // container is torn down, or its ref.read lands after dispose.
    await pumpEventQueue();
  });

  test('a stored walk is restored across containers (an app restart)',
      () async {
    SharedPreferences.setMockInitialValues({
      kActiveThreadWalkKey: '${threads[1].id}|3',
    });
    final container = await containerWithPrefs();
    final walk = container.read(threadWalkProvider)!;
    expect(walk.threadIndex, 1);
    expect(walk.stop, 3);
  });

  test('a stored walk for a removed thread id is dropped, not crashed on',
      () async {
    SharedPreferences.setMockInitialValues({
      kActiveThreadWalkKey: 'no_such_thread|2',
    });
    final container = await containerWithPrefs();
    expect(container.read(threadWalkProvider), isNull);
  });

  test('a stored stop beyond the thread length clamps to the last stop',
      () async {
    SharedPreferences.setMockInitialValues({
      kActiveThreadWalkKey: '${threads[0].id}|999',
    });
    final container = await containerWithPrefs();
    final walk = container.read(threadWalkProvider)!;
    expect(walk.stop, threads[0].stops.length - 1);
    expect(walk.isLast, isTrue);
  });

  test('advance stops at the last stop; clear removes the stored walk',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = await containerWithPrefs();
    final notifier = container.read(threadWalkProvider.notifier);

    notifier.start(0, stop: threads[0].stops.length - 1);
    notifier.advance();
    expect(container.read(threadWalkProvider)!.isLast, isTrue);

    notifier.clear();
    expect(container.read(threadWalkProvider), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kActiveThreadWalkKey), isNull);

    // Same event-queue drain as above: start() kicked off a history write.
    await pumpEventQueue();
  });
}
