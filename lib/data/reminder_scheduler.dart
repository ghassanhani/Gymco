import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A reminder ready for the phone: when, and what it says.
/// [urgent] is the rest timer: it rings through Focus and sounds.
typedef ReminderNote = ({int id, DateTime at, String title, String body, bool urgent});

/// The workout timer's own ids, kept out of the day's plan.
const timerNoteIds = {4002, 4003};

/// Puts reminders on the phone. Everything is local; nothing leaves it.
abstract class ReminderScheduler {
  /// Asks to show notifications; false when the person says no.
  Future<bool> requestPermission();

  /// Replaces the day's plan with [notes], leaving the workout timer.
  Future<void> replaceAll(List<ReminderNote> notes);

  /// Replaces the workout timer's notes.
  Future<void> replaceTimer(List<ReminderNote> notes);
}

/// For tests and platforms without notifications.
class NoReminders implements ReminderScheduler {
  const NoReminders();
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<ReminderNote> notes) async {}
  @override
  Future<void> replaceTimer(List<ReminderNote> notes) async {}
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

  static const _timer = NotificationDetails(
    android: AndroidNotificationDetails(
      'workout_timer',
      'Workout timer',
      channelDescription: 'When rest is over',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFC6F432),
    ),
    iOS: DarwinNotificationDetails(presentSound: true, interruptionLevel: InterruptionLevel.timeSensitive),
  );

  Future<void> _schedule(List<ReminderNote> notes) async {
    for (final n in notes) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime.from(n.at, tz.local),
        notificationDetails: n.urgent ? _timer : _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.title,
        body: n.body,
      );
    }
  }

  @override
  Future<void> replaceAll(List<ReminderNote> notes) async {
    await _init();
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (!timerNoteIds.contains(p.id)) await _plugin.cancel(id: p.id);
    }
    await _schedule(notes);
  }

  @override
  Future<void> replaceTimer(List<ReminderNote> notes) async {
    await _init();
    for (final id in timerNoteIds) {
      await _plugin.cancel(id: id);
    }
    await _schedule(notes);
  }
}
