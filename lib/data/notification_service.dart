import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notifications/next_trigger.dart';
import 'logging.dart';

/// Fixed id for the (single) daily reading reminder notification, so
/// re-scheduling replaces rather than duplicates it.
const int kDailyReminderNotificationId = 1;

/// Windows requires a fixed GUID identifying this app's notification
/// channel. Generated once — must never change, or existing scheduled
/// notifications would be orphaned under a new identity.
const String _kWindowsNotificationGuid = '22b8c78f-eb7d-45a5-9eb2-002bcfb67aa8';

/// Thin wrapper over the platform local-notifications plugin, used for the
/// daily reading reminder. Mirrors [TtsService]'s shape: plugin calls are
/// guarded so they degrade to no-ops (logged via [logError], not silently
/// swallowed — a caught-but-unlogged failure here previously meant the
/// reminder just never fired, with no signal why) when the platform channel
/// is unavailable (e.g. in widget tests), instead of throwing
/// `MissingPluginException`. Initialization is deferred out of the
/// constructor so merely constructing the service (which Riverpod may do
/// eagerly) never touches the platform channel.
///
/// Two deliberate scope trade-offs, not oversights:
/// - No `RECEIVE_BOOT_COMPLETED` receiver on Android — a rebooted device
///   only recovers its scheduled reminder once the app is next opened
///   ([scheduleDaily] is called again on launch/resume by the app layer),
///   so a reminder can be silently dropped for the remainder of one day
///   after a reboot.
/// - On Linux, the Desktop Notification Specification has no native
///   "fire while the app isn't running" scheduling the way Android/iOS/
///   macOS/Windows alarm services do — a reminder there only reliably
///   fires while StudyBible is resident (foreground or backgrounded).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final void Function(String? payload)? onTap;

  NotificationService({this.onTap});

  /// `flutter_local_notifications` backs all five of the app's targets.
  static bool get isSupported => true;

  Future<void> _ensureInit() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Fall back to whatever the `timezone` package treats as local
      // (UTC) if the platform's timezone name can't be resolved/matched.
    }

    // Must name a resource of type `drawable` specifically — the plugin's
    // Android side looks it up via getIdentifier(name, "drawable", ...), so
    // neither the placeholder `app_icon` from the plugin's examples nor this
    // app's actual (mipmap-typed) `launcher_icon` resolves; both fail with
    // an `invalid_icon` PlatformException. `notification_icon` is a
    // drawable alias onto launcher_icon added for this purpose — see
    // android/app/src/main/res/drawable/notification_icon.xml.
    const androidSettings = AndroidInitializationSettings('notification_icon');
    const darwinSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open StudyBible',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'StudyBible',
      appUserModelId: 'com.studybible.app',
      guid: _kWindowsNotificationGuid,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        onTap?.call(response.payload);
      },
    );
    // Only marked done once `initialize()` actually succeeds — e.g. an
    // invalid icon resource name fails this call with a PlatformException,
    // and leaving `_initialized` false lets the next call retry rather than
    // permanently skipping init after a fixable error.
    _initialized = true;
  }

  /// Requests permission to show notifications. Android/iOS/macOS require an
  /// explicit runtime grant; Linux/Windows don't, so this returns `true`
  /// there without prompting.
  Future<bool> requestPermission() async {
    try {
      await _ensureInit();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final granted = await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
          return granted ?? false;
        case TargetPlatform.iOS:
          final granted = await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true);
          return granted ?? false;
        case TargetPlatform.macOS:
          final granted = await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true);
          return granted ?? false;
        default:
          return true;
      }
    } catch (e, stack) {
      logError(e, stack, context: 'NotificationService.requestPermission');
      return false;
    }
  }

  /// Schedules a daily-repeating notification at [hour]:[minute], replacing
  /// any previously scheduled one with the same [id]. Uses inexact/allow-
  /// while-idle delivery on Android so it never needs the
  /// `SCHEDULE_EXACT_ALARM` permission — a reading reminder doesn't need
  /// to-the-minute precision.
  ///
  /// Because the plugin fixes the title/body at schedule time and simply
  /// repeats them, the caller is expected to call this again (idempotently)
  /// whenever the content that should show up next might have changed (e.g.
  /// a new day's reading-plan passage) — see the app-layer reminder
  /// controller's resume/launch hooks.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      await _ensureInit();
      final next = computeNextTrigger(
        now: DateTime.now(),
        hour: hour,
        minute: minute,
      );
      final scheduledDate = tz.TZDateTime.from(next, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'daily_reading_reminder',
        'Daily Reading Reminder',
        channelDescription: 'Reminds you to read your Bible each day.',
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reading_reminder',
      );
    } catch (e, stack) {
      logError(e, stack, context: 'NotificationService.scheduleDaily');
    }
  }

  static const NotificationDetails _actionItemDueDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'action_item_due',
      'Action Item Reminders',
      channelDescription: 'Reminds you when an action item is due soon or now.',
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  /// Schedules a one-off notification at [dateTime] via the platform's OS-
  /// level alarm, replacing any previously scheduled one with the same [id].
  /// A [dateTime] that's already passed is treated as "nothing to schedule"
  /// and just cancels [id] instead — the plugin can't schedule into the past.
  ///
  /// On Android this uses `inexactAllowWhileIdle`, which trades precision for
  /// battery life and can slip by minutes (more under Doze) — callers that
  /// need the notification to reliably appear promptly while the app is
  /// still running (not just after it's been closed) should pair this with
  /// [showNow] on their own recheck (see `ActionNotificationSyncer`'s
  /// periodic timer), rather than relying on this alone.
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    required String payload,
  }) async {
    if (!dateTime.isAfter(DateTime.now())) {
      await cancel(id);
      return;
    }
    try {
      await _ensureInit();
      final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _actionItemDueDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e, stack) {
      logError(e, stack, context: 'NotificationService.scheduleOneOff');
    }
  }

  /// Shows a notification immediately — used as the reliable-delivery path
  /// for something that's already due (or overdue) by the time the app
  /// notices, sidestepping Android's inexact alarm delay entirely since
  /// there's no scheduling involved.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await _ensureInit();
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _actionItemDueDetails,
        payload: payload,
      );
    } catch (e, stack) {
      logError(e, stack, context: 'NotificationService.showNow');
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _ensureInit();
      await _plugin.cancel(id: id);
    } catch (e, stack) {
      logError(e, stack, context: 'NotificationService.cancel');
    }
  }
}
