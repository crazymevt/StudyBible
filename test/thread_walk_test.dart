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

  test(
      'with no stored seen set, only pre-tracking threads count as seen — '
      'threads added later badge as new until opened', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await containerWithPrefs();

    final seen = container.read(seenThreadsProvider);
    // Phase-1 threads predate the badge and must never wear it…
    expect(seen, contains('living_water'));
    expect(seen, contains('i_am'));
    // …while a thread added alongside/after the tracking starts out new.
    expect(seen, isNot(contains('the_shepherd')));

    container.read(seenThreadsProvider.notifier).markSeen('the_shepherd');
    expect(
      container.read(seenThreadsProvider),
      contains('the_shepherd'),
    );
    // The write persisted the seed set along with the new id.
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(kSeenThreadsKey)!;
    expect(stored, contains('the_shepherd'));
    expect(stored, contains('living_water'));
  });

  test('a stored seen set wins over the pre-tracking seed', () async {
    SharedPreferences.setMockInitialValues({
      kSeenThreadsKey: ['the_shepherd'],
    });
    final container = await containerWithPrefs();
    final seen = container.read(seenThreadsProvider);
    expect(seen, contains('the_shepherd'));
    expect(seen, isNot(contains('living_water')));
  });

  test('completed walks persist and restore across containers', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await containerWithPrefs();
    expect(container.read(completedThreadWalksProvider), isEmpty);

    container
        .read(completedThreadWalksProvider.notifier)
        .markCompleted('living_water');
    expect(
      container.read(completedThreadWalksProvider),
      contains('living_water'),
    );

    // A fresh container (an app restart) reads it back from prefs.
    final restarted = await containerWithPrefs();
    expect(
      restarted.read(completedThreadWalksProvider),
      contains('living_water'),
    );
  });
}
