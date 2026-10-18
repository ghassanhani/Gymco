typedef ClockTime = (int, int);

/// Which reminders are on, and when each goes off.
class ReminderSettings {
  const ReminderSettings({
    this.meals = false,
    this.water = false,
    this.workout = false,
    this.mealAt = mealTimes,
    this.waterAt = waterTimes,
    this.workoutAt = workoutTime,
  });
  final bool meals;
  final bool water;
  final bool workout;
  final Map<ReminderKind, ClockTime> mealAt;
  final List<ClockTime> waterAt;
  final ClockTime workoutAt;

  bool get any => meals || water || workout;

  ReminderSettings copyWith({
    bool? meals,
    bool? water,
    bool? workout,
    Map<ReminderKind, ClockTime>? mealAt,
    List<ClockTime>? waterAt,
    ClockTime? workoutAt,
  }) => ReminderSettings(
    meals: meals ?? this.meals,
    water: water ?? this.water,
    workout: workout ?? this.workout,
    mealAt: mealAt ?? this.mealAt,
    waterAt: waterAt ?? this.waterAt,
    workoutAt: workoutAt ?? this.workoutAt,
  );
}

/// "9:30" ↔ (9, 30), as stored.
String encodeClock(ClockTime t) => '${t.$1}:${t.$2.toString().padLeft(2, '0')}';
ClockTime? decodeClock(String? s) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s ?? '');
  if (m == null) return null;
  final (h, min) = (int.parse(m[1]!), int.parse(m[2]!));
  return h < 24 && min < 60 ? (h, min) : null;
}

enum ReminderKind { breakfast, lunch, dinner, water, workout }

/// One reminder to put on the phone.
class PlannedReminder {
  const PlannedReminder({required this.id, required this.at, required this.kind, this.routine});
  final int id;
  final DateTime at;
  final ReminderKind kind;

  /// The plan's routine, for a workout reminder.
  final String? routine;
}

/// When each nudge goes off, as (hour, minute).
const mealTimes = {ReminderKind.breakfast: (9, 30), ReminderKind.lunch: (13, 30), ReminderKind.dinner: (20, 0)};
const waterTimes = [(11, 0), (15, 0), (18, 30)];
const workoutTime = (17, 0);

/// The water a day should have reached by [hour]:[minute], drinking evenly
/// from 8:00 to 22:00.
int waterPaceMl(int goalMl, int hour, int minute) {
  final t = ((hour * 60 + minute) - 8 * 60) / (14 * 60);
  return (goalMl * t.clamp(0.0, 1.0)).round();
}

/// The reminders for the next [days] days from [now]. Today's are left
/// out once their reason is gone: the meal is logged, the water is on
/// pace, the workout is done. Ids are stable per day and kind, so a new
/// plan replaces the old one cleanly.
List<PlannedReminder> planReminders({
  required DateTime now,
  required ReminderSettings settings,
  required Set<ReminderKind> mealsLoggedToday,
  required int waterMlToday,
  required int waterGoalMl,
  required bool trainedToday,
  required Map<int, String> planByWeekday,
  int days = 7,
}) {
  final out = <PlannedReminder>[];
  final today = DateTime(now.year, now.month, now.day);
  for (var d = 0; d < days; d++) {
    final day = today.add(Duration(days: d));
    DateTime at((int, int) t) => DateTime(day.year, day.month, day.day, t.$1, t.$2);
    int id(int slot) => d * 10 + slot;
    void add(int slot, DateTime when, ReminderKind kind, {String? routine}) {
      if (when.isAfter(now)) out.add(PlannedReminder(id: id(slot), at: when, kind: kind, routine: routine));
    }

    if (settings.meals) {
      for (final (i, MapEntry(key: kind, value: t)) in settings.mealAt.entries.indexed) {
        if (d == 0 && mealsLoggedToday.contains(kind)) continue;
        add(i, at(t), kind);
      }
    }
    if (settings.water) {
      for (final (i, t) in settings.waterAt.indexed) {
        if (d == 0 && waterMlToday >= waterPaceMl(waterGoalMl, t.$1, t.$2)) continue;
        add(3 + i, at(t), ReminderKind.water);
      }
    }
    if (settings.workout) {
      final routine = planByWeekday[day.weekday - 1];
      if (routine != null && !(d == 0 && trainedToday)) {
        add(6, at(settings.workoutAt), ReminderKind.workout, routine: routine);
      }
    }
  }
  return out;
}
