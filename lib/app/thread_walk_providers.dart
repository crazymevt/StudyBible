import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/scripture/passage_citation.dart';
import '../domain/scripture/scripture_route.dart';
import '../domain/threads/thread.dart';
import '../domain/threads/thread_data.dart';
import 'app_state.dart';
import 'content_providers.dart';
import 'reader_state.dart';
import 'shared_prefs.dart';

/// Where the user is in a thread walk: [threadIndex] into the pure-Dart
/// `threads` list, and the 0-based [stop] they're currently reading.
class ThreadWalk {
  final int threadIndex;
  final int stop;
  const ThreadWalk(this.threadIndex, this.stop);

  Thread get thread => threads[threadIndex];
  ThreadStop get currentStop => thread.stops[stop];
  bool get isFirst => stop == 0;
  bool get isLast => stop == thread.stops.length - 1;

  /// The current stop as a scripture-route stop, so the reader can paint the
  /// same temporary navigation highlight sermon routes use (see
  /// `scriptureNavProvider` / `stopHighlightVerses`). Null only if the
  /// passage fails to parse, which `thread_data_test.dart` rules out.
  ScriptureRouteStop? get routeStop {
    final c = PassageCitation.tryParse(currentStop.passage);
    if (c == null) return null;
    return ScriptureRouteStop(
      bookName: c.book,
      chapter: c.chapter,
      verse: c.verse,
      endVerse: c.endVerse,
    );
  }
}

/// Prefs key for the active walk, stored as `<thread id>|<stop>`. Keyed by
/// the thread's stable string id rather than its list index, so a saved walk
/// survives the dataset being reordered or extended in a later release.
const String kActiveThreadWalkKey = 'activeThreadWalk';

/// The one active thread walk (or null), persisted across restarts so a walk
/// can be picked up days later — walking a thread is a multi-sitting
/// activity, unlike the session-scoped "return to sermon" chip.
class ThreadWalkNotifier extends Notifier<ThreadWalk?> {
  @override
  ThreadWalk? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(kActiveThreadWalkKey);
    if (raw == null) return null;
    final sep = raw.lastIndexOf('|');
    if (sep <= 0) return null;
    final id = raw.substring(0, sep);
    final stop = int.tryParse(raw.substring(sep + 1));
    final index = threads.indexWhere((t) => t.id == id);
    if (index < 0 || stop == null) return null;
    return ThreadWalk(index, stop.clamp(0, threads[index].stops.length - 1));
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    final walk = state;
    if (walk == null) {
      prefs.remove(kActiveThreadWalkKey);
    } else {
      prefs.setString(kActiveThreadWalkKey, '${walk.thread.id}|${walk.stop}');
    }
  }

  /// Starts (or restarts) walking a thread, optionally partway in — the
  /// thread page's per-stop "walk from here" action.
  void start(int threadIndex, {int stop = 0}) {
    if (threadIndex < 0 || threadIndex >= threads.length) return;
    state = ThreadWalk(
      threadIndex,
      stop.clamp(0, threads[threadIndex].stops.length - 1),
    );
    _persist();
    _navigateToCurrent();
  }

  /// Moves to the next stop; no-op on the last (the chip turns its next
  /// action into "finish" there instead).
  void advance() {
    final walk = state;
    if (walk == null || walk.isLast) return;
    state = ThreadWalk(walk.threadIndex, walk.stop + 1);
    _persist();
    _navigateToCurrent();
  }

  void back() {
    final walk = state;
    if (walk == null || walk.isFirst) return;
    state = ThreadWalk(walk.threadIndex, walk.stop - 1);
    _persist();
    _navigateToCurrent();
  }

  /// Re-sends the reader to the current stop without changing it — the walk
  /// chip's sheet uses this for "Read the passage".
  void goToCurrentStop() => _navigateToCurrent();

  /// Sends the reader to the current stop, mirroring the sermon route's
  /// [ScriptureNavNotifier._navigateToCurrent]: no verse selection — the
  /// walk's temporary navigation highlight marks the passage instead, so
  /// hopping stop-to-stop never leaves selections to clean up (and never
  /// summons the verse action bar, which would hide the walk chip).
  void _navigateToCurrent() {
    final stop = state?.routeStop;
    if (stop == null) return;
    ref.read(selectedBookNameProvider.notifier).set(stop.bookName);
    ref.read(selectedChapterProvider.notifier).set(stop.chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(stop.verse ?? 1);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(navigationControllerProvider).recordHistory(verse: stop.verse);
    ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
  }

  /// Ends the walk (dismissed or completed).
  void clear() {
    state = null;
    _persist();
  }
}

final threadWalkProvider = NotifierProvider<ThreadWalkNotifier, ThreadWalk?>(
  ThreadWalkNotifier.new,
);

/// Prefs key for the thread ids the user has opened in the Explorer, stored
/// as a string list. Ids not in the set wear a "New" badge on the threads
/// index — the badge means "added since you last looked", not "recently
/// written", so it needs per-user state rather than a date on the dataset.
const String kSeenThreadsKey = 'seenThreads';

/// Prefs key for the ids of threads whose walk was finished (the walk chip's
/// flag action on the last stop), stored as a string list.
const String kCompletedThreadWalksKey = 'completedThreadWalks';

/// The threads that existed before the seen/completed tracking shipped.
/// They seed [SeenThreadsNotifier] when no set is stored yet, so a user
/// updating (or installing) today is only badged on threads added after
/// these — everything is "new" on day one, which would make the badge noise.
const List<String> _preTrackingThreadIds = [
  'living_water',
  'god_with_us',
  'tree_of_life',
  'the_covenants',
  'the_lamb',
  'i_am',
];

/// Thread ids the user has opened; the threads index badges the rest as new.
class SeenThreadsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final stored =
        ref.watch(sharedPreferencesProvider).getStringList(kSeenThreadsKey);
    // No stored set (pre-tracking install or first run): only threads added
    // after tracking shipped count as unseen. markSeen persists the seed
    // along with its first id, so nothing needs writing here.
    return (stored ?? _preTrackingThreadIds).toSet();
  }

  /// Records that the thread's Explorer page was opened, clearing its badge.
  void markSeen(String id) {
    if (state.contains(id)) return;
    state = {...state, id};
    ref
        .read(sharedPreferencesProvider)
        .setStringList(kSeenThreadsKey, state.toList());
  }
}

final seenThreadsProvider = NotifierProvider<SeenThreadsNotifier, Set<String>>(
  SeenThreadsNotifier.new,
);

/// Thread ids walked to the end — the "which have I already read" half of
/// the index's status marks (the seen set only answers "which are new").
class CompletedThreadWalksNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return (prefs.getStringList(kCompletedThreadWalksKey) ?? const []).toSet();
  }

  void markCompleted(String id) {
    if (state.contains(id)) return;
    state = {...state, id};
    ref
        .read(sharedPreferencesProvider)
        .setStringList(kCompletedThreadWalksKey, state.toList());
  }
}

final completedThreadWalksProvider =
    NotifierProvider<CompletedThreadWalksNotifier, Set<String>>(
  CompletedThreadWalksNotifier.new,
);
