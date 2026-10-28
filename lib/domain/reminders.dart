typedef ClockTime = (int, int);

/// The reminder switches, one per reminder, as the Me tab lists them.
enum NoteGroup { meals, protein, water, workout, weighIn, streak, checkIn, iron, timer, account }

/// Which reminders are on, and when each goes off. [mealAt] is null until
/// the meal times are changed: then the region's own hours apply.
class ReminderSettings {
  const ReminderSettings({
    this.on = const {},
    this.allowed = false,
    this.mealAt,
    this.waterAt = waterTimes,
    this.workoutAt,
    this.weighAt = (7, 30),
    this.weighDays = const {0, 3},
    this.quietFrom = (23, 0),
    this.quietTo = (7, 0),
  });

  final Set<NoteGroup> on;

  /// The phone has allowed notifications at least once.
  final bool allowed;
  final Map<ReminderKind, ClockTime>? mealAt;
  final List<ClockTime> waterAt;

  /// The usual training time, when set by hand; otherwise it is learned.
  final ClockTime? workoutAt;
  final ClockTime weighAt;

  /// Weigh-in mornings, 0 = Monday.
  final Set<int> weighDays;
  final ClockTime quietFrom, quietTo;

  bool get meals => on.contains(NoteGroup.meals);
  bool get water => on.contains(NoteGroup.water);
  bool get workout => on.contains(NoteGroup.workout);
  bool get any => allowed && on.isNotEmpty;
  bool isOn(NoteGroup g) => on.contains(g);

  ReminderSettings copyWith({
    Set<NoteGroup>? on,
    bool? allowed,
    Map<ReminderKind, ClockTime>? mealAt,
    List<ClockTime>? waterAt,
    ClockTime? workoutAt,
    ClockTime? weighAt,
    Set<int>? weighDays,
    ClockTime? quietFrom,
    ClockTime? quietTo,
  }) => ReminderSettings(
    on: on ?? this.on,
    allowed: allowed ?? this.allowed,
    mealAt: mealAt ?? this.mealAt,
    waterAt: waterAt ?? this.waterAt,
    workoutAt: workoutAt ?? this.workoutAt,
    weighAt: weighAt ?? this.weighAt,
    weighDays: weighDays ?? this.weighDays,
    quietFrom: quietFrom ?? this.quietFrom,
    quietTo: quietTo ?? this.quietTo,
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

/// When the water nudges go off, and the usual training time when none is
/// learned yet, as (hour, minute).
const waterTimes = [(11, 0), (15, 0), (18, 0)];
const workoutTime = (17, 0);

/// The water a day should have reached by [hour]:[minute], drinking evenly
/// from 8:00 to 22:00.
int waterPaceMl(int goalMl, int hour, int minute) {
  final t = ((hour * 60 + minute) - 8 * 60) / (14 * 60);
  return (goalMl * t.clamp(0.0, 1.0)).round();
}
