import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_store.dart';
import 'action_providers.dart';
import 'notification_providers.dart';
import 'shared_prefs.dart';

/// Whether action items with a due date also get a system notification (in
/// addition to the always-on in-app due banner). Off by default — opt-in,
/// mirrors `reminderEnabledProvider` in `app_state.dart`.
class ActionDueNotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('actionDueNotificationsEnabled') ?? false;
  }

  void set(bool value) {
    state = value;
    ref
        .read(sharedPreferencesProvider)
        .setBool('actionDueNotificationsEnabled', value);
  }
}

final actionDueNotificationsEnabledProvider =
    NotifierProvider<ActionDueNotificationsEnabledNotifier, bool>(
  ActionDueNotificationsEnabledNotifier.new,
);

/// Derives a stable notification id from [key], fitting the plugin's 32-bit
/// int id and offset away from `kDailyReminderNotificationId`. Two distinct
/// keys are vanishingly unlikely to collide, so the heads-up and due-time
/// notifications for the same action item just hash a different suffix.
int _notificationIdFor(String key) => 1000 + (key.hashCode & 0x7fffffff) % 2000000000;

int _headsUpNotificationId(String actionId) =>
    _notificationIdFor('action_headsup_$actionId');

int _dueNotificationId(String actionId) =>
    _notificationIdFor('action_due_$actionId');

/// Schedules (or cancels) each action item's due-date notifications to
/// reflect the current item list and the enabled setting: one at
/// [kActionLeadMs] ahead of its due time ("due soon") and one at the due
/// time itself ("due now"). Idempotent — safe to call whenever the action
/// list or setting changes, on app launch/resume, and periodically (see
/// [ActionNotificationSyncer]'s timer).
///
/// A threshold that's already passed by the time this runs — either because
/// the app only just noticed (near-term due date racing the sync pipeline)
/// or because the OS's alarm hasn't fired yet (Android's
/// `inexactAllowWhileIdle` can slip by minutes) — fires immediately via
/// [NotificationService.showNow] instead of silently dropping it. Each
/// item+kind only fires once this way per becoming-due transition; the
/// dedup sets are cleared once the item stops being active (done/deleted/no
/// due date) so editing the due date to a fresh future time schedules a
/// normal one-off again.
class ActionNotificationScheduler {
  final Ref ref;
  ActionNotificationScheduler(this.ref);

  final Set<String> _headsUpFired = {};
  final Set<String> _dueFired = {};

  Future<void> syncAll() async {
    final items = ref.read(actionItemsProvider).value ?? const <ActionItem>[];
    // Nothing to schedule or cancel — skip grabbing the notification service
    // so this stays a no-op (rather than an UnimplementedError) wherever
    // that provider isn't overridden, e.g. widget tests that boot the app
    // without any action items.
    if (items.isEmpty) return;

    final service = ref.read(notificationServiceProvider);
    final enabled = ref.read(actionDueNotificationsEnabledProvider);
    final activeIds = <String>{};

    for (final item in items) {
      final headsUpId = _headsUpNotificationId(item.id);
      final dueId = _dueNotificationId(item.id);

      if (!enabled ||
          item.deleted ||
          item.completedAt != null ||
          item.dueAt == null) {
        await service.cancel(headsUpId);
        await service.cancel(dueId);
        continue;
      }
      activeIds.add(item.id);

      final now = DateTime.now();
      final due = DateTime.fromMillisecondsSinceEpoch(item.dueAt!);
      final headsUpAt = due.subtract(const Duration(milliseconds: kActionLeadMs));
      final payload = 'action_item:${item.id}';

      if (due.isAfter(now)) {
        await service.scheduleOneOff(
          id: dueId,
          title: 'Action due now',
          body: item.title,
          dateTime: due,
          payload: payload,
        );
      } else if (_dueFired.add(item.id)) {
        await service.showNow(
          id: dueId,
          title: 'Action due now',
          body: item.title,
          payload: payload,
        );
      }

      if (!due.isAfter(now)) {
        // Already due — the heads-up window is moot, and its notification
        // (if pending) was superseded by the "due now" one above.
        await service.cancel(headsUpId);
      } else if (headsUpAt.isAfter(now)) {
        await service.scheduleOneOff(
          id: headsUpId,
          title: 'Action due soon',
          body: item.title,
          dateTime: headsUpAt,
          payload: payload,
        );
      } else if (_headsUpFired.add(item.id)) {
        await service.showNow(
          id: headsUpId,
          title: 'Action due soon',
          body: item.title,
          payload: payload,
        );
      }
    }

    _headsUpFired.removeWhere((id) => !activeIds.contains(id));
    _dueFired.removeWhere((id) => !activeIds.contains(id));
  }
}

final actionNotificationSchedulerProvider = Provider<ActionNotificationScheduler>(
  (ref) => ActionNotificationScheduler(ref),
);

/// Keeps scheduled action-item notifications in sync with the live action
/// list and the enabled setting. Has no state of its own worth reading —
/// just needs to stay alive, which it does by being watched alongside
/// `actionDueControllerProvider` in `main.dart`'s app builder (see
/// `ActionDueBanner`'s neighboring `Consumer`).
///
/// Also rechecks every minute (mirroring `ActionDueController`'s timer) so an
/// item crossing its heads-up/due threshold gets its immediate-fire fallback
/// promptly while the app is open, rather than waiting for the action list to
/// next change for some unrelated reason.
class ActionNotificationSyncer extends Notifier<void> {
  Timer? _timer;

  @override
  void build() {
    ref.listen(actionItemsProvider, (_, _) => _sync());
    ref.listen(actionDueNotificationsEnabledProvider, (_, _) => _sync());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _sync());
    ref.onDispose(() => _timer?.cancel());
    _sync();
  }

  void _sync() {
    unawaited(ref.read(actionNotificationSchedulerProvider).syncAll());
  }
}

final actionNotificationSyncProvider = NotifierProvider<ActionNotificationSyncer, void>(
  ActionNotificationSyncer.new,
);
