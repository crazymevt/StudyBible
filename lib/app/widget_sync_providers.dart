import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../data/verse_of_the_day_list.dart';
import '../domain/home_widgets/widget_deep_link.dart';
import '../domain/home_widgets/widget_payload.dart';
import 'action_providers.dart';
import 'app_state.dart';
import 'content_providers.dart';
import 'user_providers.dart';

/// Home-screen widgets are Android-only for now (see
/// docs/home-screen-widgets-plan.md; iOS/macOS WidgetKit is phase 2). Also
/// guards every `HomeWidget.*` call: on other platforms the plugin isn't
/// registered and would throw MissingPluginException — including under
/// `flutter test`, which runs on the host.
bool get homeWidgetsSupported => !kIsWeb && Platform.isAndroid;

/// Shared-storage keys the native widget renderers read
/// (android/…/HomeWidgetJson.kt must use the same names).
const String kVotdWidgetDataKey = 'votd_json';
const String kActionsWidgetDataKey = 'actions_json';
const String kRibbonsWidgetDataKey = 'ribbons_json';

/// Android `AppWidgetProvider` class names (unqualified; the plugin prefixes
/// the application's package name).
const String kVotdAndroidWidget = 'VerseOfTheDayWidgetProvider';
const String kActionsAndroidWidget = 'UpcomingActionsWidgetProvider';
const String kRibbonsAndroidWidget = 'RibbonsWidgetProvider';

/// Mirrors user data into the home-screen widgets' shared storage and pokes
/// the native side to re-render. Follows [ActionNotificationSyncer]'s
/// keep-alive pattern: watched once from `main.dart`'s app builder purely so
/// its `ref.listen`s stay registered.
///
/// Freshness model (from the plan): user data only changes while the app
/// runs, so push-on-change plus the write on startup is sufficient. The
/// verse-of-the-day payload carries the whole curated list and the native
/// side picks today's entry, so it never goes stale between launches.
class HomeWidgetSyncer extends Notifier<void> {
  Timer? _debounce;

  @override
  void build() {
    if (!homeWidgetsSupported) return;
    ref.listen(actionItemsProvider, (_, _) => _scheduleSync());
    ref.listen(allBookmarksProvider, (_, _) => _scheduleSync());
    ref.onDispose(() => _debounce?.cancel());
    _scheduleSync();
  }

  /// Coalesces bursts (e.g. a sync run touching many rows) into one write.
  void _scheduleSync() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => unawaited(_sync()));
  }

  Future<void> _sync() async {
    final votd = buildVerseOfTheDayPayload([
      for (final v in versesOfTheDay) (reference: v.reference, text: v.text),
    ]);

    final actions = ref.read(actionItemsProvider).value ?? const [];
    final actionsPayload = buildUpcomingActionsPayload(
      [
        for (final a in actions)
          (
            id: a.id,
            title: a.title,
            dueAt: a.dueAt,
            completedAt: a.completedAt,
            deleted: a.deleted,
          ),
      ],
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );

    final ribbons = ref.read(allBookmarksProvider).value ?? const [];
    final ribbonsPayload = buildRibbonsPayload([
      for (final r in ribbons)
        (
          bookName: r.bookName,
          chapter: r.chapter,
          verse: r.verse,
          label: r.label,
          updatedAt: r.updatedAt,
        ),
    ]);

    await HomeWidget.saveWidgetData<String>(
        kVotdWidgetDataKey, jsonEncode(votd));
    await HomeWidget.saveWidgetData<String>(
        kActionsWidgetDataKey, jsonEncode(actionsPayload));
    await HomeWidget.saveWidgetData<String>(
        kRibbonsWidgetDataKey, jsonEncode(ribbonsPayload));

    await HomeWidget.updateWidget(androidName: kVotdAndroidWidget);
    await HomeWidget.updateWidget(androidName: kActionsAndroidWidget);
    await HomeWidget.updateWidget(androidName: kRibbonsAndroidWidget);
  }
}

final homeWidgetSyncProvider = NotifierProvider<HomeWidgetSyncer, void>(
  HomeWidgetSyncer.new,
);

/// Dispatches a URI delivered by a widget tap (cold start or warm resume) to
/// the right screen. Unrecognized URIs are ignored.
void handleWidgetDeepLink(ProviderContainer container, Uri? uri) {
  if (uri == null) return;
  switch (parseWidgetDeepLink(uri)) {
    case ReadVerseDeepLink(:final bookName, :final chapter, :final verse):
      container.read(navigationControllerProvider).openVerse(
            bookName: bookName,
            chapter: chapter,
            verse: verse,
          );
    case OpenActionsDeepLink():
      container
          .read(journalsActiveTabProvider.notifier)
          .setTab(JournalsActiveTab.actions);
      container
          .read(appModuleProvider.notifier)
          .setModule(AppModule.journalsPrayers);
    case null:
      break;
  }
}

/// Hooks up widget-tap deep links. Called once from `main()` after the
/// container exists; the cold-start URI is checked immediately and later taps
/// arrive on the stream while the app stays alive.
void initHomeWidgetDeepLinks(ProviderContainer container) {
  if (!homeWidgetsSupported) return;
  unawaited(HomeWidget.initiallyLaunchedFromHomeWidget()
      .then((uri) => handleWidgetDeepLink(container, uri)));
  HomeWidget.widgetClicked
      .listen((uri) => handleWidgetDeepLink(container, uri));
}
