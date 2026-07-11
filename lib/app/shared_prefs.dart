import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

/// The current "search index generation" — bump this by 1 whenever a change to
/// how content is indexed for search requires existing users to rebuild their
/// index (do it in the same release as the change). Users whose last rebuild
/// predates the current generation are prompted once, in the What's New dialog,
/// to rebuild.
///
/// History:
///   1 — markup-stripping of verse text (release 26.6.24+1).
const int kSearchIndexGeneration = 1;

/// The [kSearchIndexGeneration] the user last rebuilt their search index for
/// (absent / 0 means "older than generation 1"). Set to the current generation
/// on a fresh install (born clean) and whenever a rebuild runs, so the prompt
/// re-fires for each future generation but never nags after a rebuild. See
/// [WhatsNewDialog] and `MainShell._checkWhatsNew`.
const String kSearchIndexRebuiltGenKey = 'searchIndexRebuiltGeneration';

const String kHasSeenTutorialKey = 'hasSeenTutorial';

class HasSeenTutorialNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(kHasSeenTutorialKey) ?? false;
  }

  Future<void> setSeen(bool seen) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(kHasSeenTutorialKey, seen);
    state = seen;
  }
}

final hasSeenTutorialProvider = NotifierProvider<HasSeenTutorialNotifier, bool>(() {
  return HasSeenTutorialNotifier();
});

/// Whether the Content Manager's "Get more study resources" banner has been
/// dismissed or fulfilled. KJV and Easton's now ship bundled with the app, so
/// [main_shell.dart]'s onboarding screen — the only other place offering the
/// curated [recommendedPh4Modules] set — no longer appears for most installs;
/// this banner is the replacement entry point. Set on manual dismiss and on a
/// fully-successful [ContentManagerController.downloadRecommended] run, so it
/// doesn't linger after the set is installed.
const String kHasDismissedRecommendedBannerKey = 'hasDismissedRecommendedBanner';

class HasDismissedRecommendedBannerNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(kHasDismissedRecommendedBannerKey) ?? false;
  }

  Future<void> setDismissed(bool dismissed) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(kHasDismissedRecommendedBannerKey, dismissed);
    state = dismissed;
  }
}

final hasDismissedRecommendedBannerProvider =
    NotifierProvider<HasDismissedRecommendedBannerNotifier, bool>(() {
  return HasDismissedRecommendedBannerNotifier();
});
