part of 'explorer_providers.dart';

// --- Exploration trail (breadcrumb navigation stack) ---

/// The chain of entities the user has drilled through, oldest first. Empty
/// means the Explorer home (search) page. Session-global so reopening the
/// Explorer resumes where the user left off.
class ExplorerTrailNotifier extends Notifier<List<ExplorerRef>> {
  @override
  List<ExplorerRef> build() => const [];

  void open(ExplorerRef ref) {
    if (state.isNotEmpty && state.last == ref) return;
    state = [...state, ref];
  }

  /// Cut the trail back so [index] is the last (current) entry.
  void truncateTo(int index) {
    if (index < 0 || index >= state.length - 1) return;
    state = state.sublist(0, index + 1);
  }

  void pop() {
    if (state.isNotEmpty) state = state.sublist(0, state.length - 1);
  }

  void clear() => state = const [];

  /// Replaces the trail wholesale. Used to put back whatever a temporarily
  /// hijacked trail held before — see `openInFreshExplorer` in
  /// `explorer_common.dart`: the trail is one global, session-wide stack,
  /// not one per pushed [ExplorerScreen], so a second Explorer instance
  /// pushed on top of a first must restore the first's trail on the way
  /// back out, or popping back to it would show whatever the second one
  /// left behind instead.
  void restore(List<ExplorerRef> trail) => state = trail;
}

final explorerTrailProvider =
    NotifierProvider<ExplorerTrailNotifier, List<ExplorerRef>>(
      () => ExplorerTrailNotifier(),
    );

/// Whether an [ExplorerScreen] pushed by `openInFreshExplorer` is currently
/// showing. Lets that function tell a nested open (from inside an
/// already-open Explorer, e.g. a family tree node) apart from a fresh,
/// top-level open (from the Reader or a side panel) — only the nested case
/// needs its trail protected from the detour.
class InsideExplorerNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final insideExplorerProvider = NotifierProvider<InsideExplorerNotifier, bool>(
  () => InsideExplorerNotifier(),
);
