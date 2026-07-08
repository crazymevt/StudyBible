import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_service.dart';
import '../domain/reading_plan/today_reading_resolver.dart';
import 'app_state.dart';
import 'reading_plan_providers.dart';

/// Overridden in `main.dart` with a real [NotificationService] constructed
/// with a tap callback closure over the app's standalone `ProviderContainer`
/// — mirrors `sharedPreferencesProvider`'s override-at-startup pattern
/// (`lib/app/shared_prefs.dart`).
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError();
});

/// Resolves today's reading-plan day, if any active plan has one dated
/// today, with its passages ready to format into a notification body. Null
/// when no active plan has a day dated today (not started, already
/// finished, or no active plan at all).
final todaysReadingProvider = FutureProvider<TodayReadingDay?>((ref) async {
  final plans = await ref.watch(activeReadingPlansProvider.future);

  final daySummaries = <ReadingPlanDaySummary>[];
  for (final plan in plans) {
    final days = await ref.watch(readingPlanDaysProvider(plan.id).future);
    for (final day in days) {
      daySummaries.add(
        ReadingPlanDaySummary(
          planId: plan.id,
          dayId: day.id,
          dateEpochMs: day.date,
        ),
      );
    }
  }

  final match = resolveTodaysDay(days: daySummaries, today: DateTime.now());
  if (match == null) return null;

  final items = await ref.watch(readingPlanItemsProvider(match.dayId).future);
  final passages = items
      .map(
        (item) => ReadingPlanPassageSummary(
          bookName: item.bookName,
          startChapter: item.startChapter,
          endChapter: item.endChapter,
        ),
      )
      .toList();

  return TodayReadingDay(
    planId: match.planId,
    dayId: match.dayId,
    passages: passages,
  );
});

/// Schedules (or cancels) the daily reading reminder to reflect the current
/// settings and today's reading-plan content. Idempotent — safe to call
/// whenever the enabled/time settings change and on every app launch/resume,
/// which is also how the notification body picks up a new day's passage
/// (see [NotificationService.scheduleDaily]'s doc comment).
class ReminderController {
  final Ref _ref;

  ReminderController(this._ref);

  Future<void> reschedule() async {
    final service = _ref.read(notificationServiceProvider);
    final enabled = _ref.read(reminderEnabledProvider);

    if (!enabled) {
      await service.cancel(kDailyReminderNotificationId);
      return;
    }

    final time = _ref.read(reminderTimeProvider);
    final today = await _ref.read(todaysReadingProvider.future);

    final body = today != null
        ? 'Today: ${formatPassageSummary(today.passages)}'
        : 'Time for your Bible reading';

    await service.scheduleDaily(
      id: kDailyReminderNotificationId,
      title: 'Daily Reading Reminder',
      body: body,
      hour: time.hour,
      minute: time.minute,
    );
  }
}

final reminderControllerProvider = Provider<ReminderController>(
  (ref) => ReminderController(ref),
);
