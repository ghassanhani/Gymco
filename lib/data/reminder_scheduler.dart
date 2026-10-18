import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A reminder ready for the phone: when, and what it says.
typedef ReminderNote = ({int id, DateTime at, String title, String body});

/// Puts reminders on the phone. Everything is local; nothing leaves it.
abstract class ReminderScheduler {
  /// Asks to show notifications; false when the person says no.
  Future<bool> requestPermission();

  /// Replaces whatever was scheduled with [notes].
  Future<void> replaceAll(List<ReminderNote> notes);
}

/// For tests and platforms without notifications.
class NoReminders implements ReminderScheduler {
  const NoReminders();
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<ReminderNote> notes) async {}
}

class DeviceReminders implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (_) {
      // An unknown zone name: times are then read as UTC, which is late or
      // early but never lost.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_gymco'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Meal, water and workout reminders',
      importance: Importance.defaultImportance,
      color: Color(0xFFC6F432),
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> replaceAll(List<ReminderNote> notes) async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
    for (final n in notes) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime.from(n.at, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.title,
        body: n.body,
      );
    }
  }
}
