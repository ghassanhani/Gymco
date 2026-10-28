/// Every notification Gymco can schedule on the phone, and the rules that
/// keep them few and welcome: at most 3 a day (the workout timer aside),
/// none in quiet hours, none during Friday prayer in the Gulf, none for
/// something already done, and fewer when one keeps being ignored.
library;

import 'reminders.dart';

/// In order of value: when more than 3 are due on a day, the first win.
enum NoteKind {
  streakRisk,
  streakRepair,
  freezeUsed,
  workout,
  sessionMoved,
  checkIn,
  breakfast,
  lunch,
  dinner,
  protein,
  weighIn,
  water,
  challengeNew,
  challengeNear,
  ironTip,
  welcomeBack,
  backup,
  restOver,
  workoutOpen,
}

/// The workout timer goes off whatever else the day held.
const _uncapped = {NoteKind.restOver, NoteKind.workoutOpen};

/// Reminders that back off when ignored.
const backOffKinds = {
  NoteKind.breakfast,
  NoteKind.lunch,
  NoteKind.dinner,
  NoteKind.water,
  NoteKind.workout,
  NoteKind.protein,
  NoteKind.weighIn,
};

/// Where the phone is: meal hours, the weekend and the check-in day follow it.
enum Region { gulf, spain, other }

const _gulf = {'SA', 'AE', 'KW', 'QA', 'BH', 'OM'};

Region regionOf(String? country, String language) => switch (country?.toUpperCase()) {
  final c? when _gulf.contains(c) => Region.gulf,
  'ES' => Region.spain,
  null || '' when language == 'ar' => Region.gulf,
  _ => Region.other,
};

/// The region's usual meal hours; a reminder goes 45 minutes after.
Map<ReminderKind, ClockTime> regionMealTimes(Region r) => switch (r) {
  Region.gulf => const {ReminderKind.breakfast: (8, 30), ReminderKind.lunch: (14, 0), ReminderKind.dinner: (21, 0)},
  Region.spain => const {ReminderKind.breakfast: (8, 30), ReminderKind.lunch: (15, 0), ReminderKind.dinner: (22, 0)},
  Region.other => const {ReminderKind.breakfast: (8, 0), ReminderKind.lunch: (13, 0), ReminderKind.dinner: (19, 30)},
};

/// The weekly check-in: the first morning of the weekend in the Gulf
/// (Saturday 10:00), Monday 09:00 elsewhere. Weekday 0 = Monday.
(int, ClockTime) regionCheckIn(Region r) => r == Region.gulf ? (5, (10, 0)) : (0, (9, 0));

const mealDelay = Duration(minutes: 45);

/// One notification to put on the phone. [data] holds what its words need.
class Note {
  const Note(this.id, this.at, this.kind, [this.data = const {}]);
  final int id;
  final DateTime at;
  final NoteKind kind;
  final Map<String, Object> data;

  @override
  String toString() => 'Note($kind @ $at $data)';
}

/// What the routine a day holds needs to say.
class PlanDay {
  const PlanDay({required this.name, required this.exercises, required this.minutes});
  final String name;
  final int exercises;
  final int minutes;
}

/// Everything the planner reads, gathered from the phone.
class NoteFacts {
  const NoteFacts({
    required this.now,
    required this.region,
    this.mealsLoggedToday = const {},
    this.proteinToday = 0,
    this.proteinTarget = 0,
    this.waterToday = 0,
    this.waterGoal = 0,
    this.trainedToday = false,
    this.weighedToday = false,
    this.keptToday = false,
    this.streak = 0,
    this.yesterdayFrozen = false,
    this.freezesLeft = 0,
    this.canRepair = false,
    this.plan = const {},
    this.movesTo = const {},
    this.usualTraining = (17, 0),
    this.checkInTarget,
    this.checkInStall = false,
    this.checkInFast = false,
    this.stallWeeks = 3,
    this.ironTipToday,
    this.restDaysBeforeToday = 0,
    this.challengeTarget = 12,
    this.challengeTitle,
    this.workoutsThisMonth = 0,
    this.lastLogged,
    this.lastBackup,
    this.signedIn = false,
    this.restEndsAt,
    this.restExercise,
    this.restSet,
    this.workoutActiveAt,
    this.backedOff = const {},
  });

  final DateTime now;
  final Region region;
  final Set<ReminderKind> mealsLoggedToday;
  final double proteinToday, proteinTarget;
  final int waterToday, waterGoal;
  final bool trainedToday, weighedToday, keptToday;

  final int streak;
  final bool yesterdayFrozen;
  final int freezesLeft;
  final bool canRepair;

  /// The routine each day holds, by day offset from today (0 = today).
  final Map<int, PlanDay> plan;

  /// For a day holding a routine: the weekday (0 = Monday) it slides to if
  /// skipped.
  final Map<int, int> movesTo;

  /// When workouts usually start, learned from past sessions.
  final ClockTime usualTraining;

  /// The week's check-in: the new target, and what it found.
  final int? checkInTarget;
  final bool checkInStall, checkInFast;
  final int stallWeeks;

  /// Today's first tip from Iron, if it has given one.
  final String? ironTipToday;

  /// Rest days already passed this week (tips go on the first two).
  final int restDaysBeforeToday;

  final int challengeTarget;
  final String? challengeTitle;
  final int workoutsThisMonth;

  final DateTime? lastLogged, lastBackup;
  final bool signedIn;

  /// The running workout: when its rest ends, and what comes next.
  final DateTime? restEndsAt;
  final String? restExercise;
  final int? restSet;
  final DateTime? workoutActiveAt;

  /// Reminders ignored for 5 days running: these go every other day.
  final Set<NoteKind> backedOff;
}

/// What is switched on, and the hours to keep quiet.
class NoteSwitches {
  const NoteSwitches({
    this.meals = false,
    this.protein = false,
    this.water = false,
    this.workout = false,
    this.weighIn = false,
    this.streak = false,
    this.checkIn = false,
    this.iron = false,
    this.timer = false,
    this.account = false,
    this.mealAt = const {},
    this.waterAt = waterTimes,
    this.weighAt = (7, 30),
    this.weighDays = const {0, 3},
    this.quietFrom = (23, 0),
    this.quietTo = (7, 0),
  });

  final bool meals, protein, water, workout, weighIn, streak, checkIn, iron, timer, account;
  final Map<ReminderKind, ClockTime> mealAt;
  final List<ClockTime> waterAt;
  final ClockTime weighAt;
  final Set<int> weighDays;
  final ClockTime quietFrom, quietTo;
}

/// The notifications for the next [days] days.
List<Note> planNotes(NoteFacts f, NoteSwitches s, {int days = 7}) {
  final now = f.now;
  final today = DateTime(now.year, now.month, now.day);
  final out = <Note>[];
  for (var d = 0; d < days; d++) {
    final day = DateTime(today.year, today.month, today.day + d);
    final first = d == 0;
    DateTime at(ClockTime t) => DateTime(day.year, day.month, day.day, t.$1, t.$2);
    void add(NoteKind k, DateTime when, [Map<String, Object> data = const {}, int slot = 0]) =>
        out.add(Note(d * 64 + k.index * 3 + slot, when, k, data));
    final plan = f.plan[d];

    if (s.meals) {
      for (final MapEntry(key: meal, value: t) in s.mealAt.entries) {
        if (first && f.mealsLoggedToday.contains(meal)) continue;
        add(switch (meal) {
          ReminderKind.breakfast => NoteKind.breakfast,
          ReminderKind.lunch => NoteKind.lunch,
          _ => NoteKind.dinner,
        }, at(t).add(mealDelay));
      }
    }
    // Only today knows how far short it is.
    if (s.protein && first && f.proteinTarget > 0 && f.proteinToday < f.proteinTarget * 0.7) {
      final dinner = s.mealAt[ReminderKind.dinner] ?? regionMealTimes(f.region)[ReminderKind.dinner]!;
      add(NoteKind.protein, at(dinner).subtract(const Duration(hours: 2)), {
        'grams': (f.proteinTarget - f.proteinToday).round(),
      });
    }
    if (s.water && f.waterGoal > 0) {
      for (final (i, t) in s.waterAt.indexed) {
        if (first && f.waterToday >= waterPaceMl(f.waterGoal, t.$1, t.$2)) continue;
        final left = f.waterGoal - (first ? f.waterToday : 0);
        add(NoteKind.water, at(t), {'ml': left}, i);
      }
    }
    if (s.workout && plan != null && !(first && f.trainedToday)) {
      add(NoteKind.workout, at(f.usualTraining).subtract(const Duration(hours: 1)), {
        'routine': plan.name,
        'exercises': plan.exercises,
        'minutes': plan.minutes,
      });
      if (f.movesTo[d] case final to?) add(NoteKind.sessionMoved, at((21, 0)), {'routine': plan.name, 'to': to});
    }
    if (s.weighIn && s.weighDays.contains(day.weekday - 1) && !(first && f.weighedToday)) {
      add(NoteKind.weighIn, at(s.weighAt));
    }

    if (s.streak) {
      if (!(first && f.keptToday)) {
        add(NoteKind.streakRisk, at((20, 30)), {if (first && f.streak > 0) 'days': f.streak});
      }
      if (first && f.yesterdayFrozen) add(NoteKind.freezeUsed, at((9, 0)), {'left': f.freezesLeft});
      if (first && f.canRepair) add(NoteKind.streakRepair, at((10, 0)));
      if (day.day == 1) {
        add(NoteKind.challengeNew, at((10, 0)), {'target': f.challengeTarget, 'title': ?f.challengeTitle});
      }
      final daysLeft = DateTime(day.year, day.month + 1, 0).day - day.day;
      if (first && f.trainedToday && f.challengeTarget - f.workoutsThisMonth == 2 && daysLeft >= 5) {
        add(NoteKind.challengeNear, at((19, 0)));
      }
    }
    if (s.checkIn) {
      final (wd, t) = regionCheckIn(f.region);
      if (day.weekday - 1 == wd) {
        add(NoteKind.checkIn, at(t), {
          'target': ?f.checkInTarget,
          if (f.checkInStall) 'stall': f.stallWeeks,
          if (f.checkInFast) 'fast': true,
        });
      }
    }
    // A tip on a rest day at noon, on at most two of the week's rest days.
    if (s.iron && first && plan == null && f.ironTipToday != null && f.restDaysBeforeToday < 2) {
      add(NoteKind.ironTip, at((12, 0)), {'tip': f.ironTipToday!});
    }
  }

  if (s.account) {
    if (f.lastLogged case final last?) {
      final back = DateTime(last.year, last.month, last.day + 3, 19);
      out.add(Note(4000, back, NoteKind.welcomeBack));
    }
    if (f.signedIn && f.lastBackup != null) {
      out.add(Note(4001, f.lastBackup!.add(const Duration(days: 3)), NoteKind.backup));
    }
  }
  if (s.timer) {
    if (f.restEndsAt case final end?) {
      out.add(Note(4002, end, NoteKind.restOver, {'exercise': ?f.restExercise, 'set': ?f.restSet}));
    }
    if (f.workoutActiveAt case final active?) {
      out.add(Note(4003, active.add(const Duration(hours: 3)), NoteKind.workoutOpen));
    }
  }

  return applyNoteRules(out, f, s, today: today);
}

int _min(ClockTime t) => t.$1 * 60 + t.$2;

/// Quiet hours, Friday prayer, backing off, the daily cap and the phone's
/// limit of 64 waiting notifications.
List<Note> applyNoteRules(List<Note> notes, NoteFacts f, NoteSwitches s, {required DateTime today}) {
  bool quiet(DateTime t) {
    final m = t.hour * 60 + t.minute, from = _min(s.quietFrom), to = _min(s.quietTo);
    return from <= to ? m >= from && m < to : m >= from || m < to;
  }

  final kept = <Note>[];
  for (var n in notes) {
    if (!n.at.isAfter(f.now)) continue;
    final timer = n.kind == NoteKind.restOver;
    // Friday prayer in the Gulf, about 11:30 to 13:30: held until after.
    if (!timer && f.region == Region.gulf && n.at.weekday == DateTime.friday) {
      final m = n.at.hour * 60 + n.at.minute;
      if (m >= 11 * 60 + 30 && m < 13 * 60 + 30) {
        n = Note(n.id, DateTime(n.at.year, n.at.month, n.at.day, 13, 30), n.kind, n.data);
      }
    }
    if (!timer && quiet(n.at)) continue;
    final offset = DateTime(n.at.year, n.at.month, n.at.day).difference(today).inDays;
    if (f.backedOff.contains(n.kind) && offset.isOdd) continue;
    kept.add(n);
  }

  // At most 3 a day, keeping the most valuable.
  final byDay = <int, List<Note>>{};
  for (final n in kept) {
    if (_uncapped.contains(n.kind)) continue;
    (byDay[DateTime(n.at.year, n.at.month, n.at.day).millisecondsSinceEpoch] ??= []).add(n);
  }
  final dropped = <Note>{};
  for (final list in byDay.values) {
    list.sort((a, b) => a.kind.index.compareTo(b.kind.index));
    dropped.addAll(list.skip(3));
  }
  final out = [
    for (final n in kept)
      if (!dropped.contains(n)) n,
  ]..sort((a, b) => a.at.compareTo(b.at));
  return out.take(60).toList();
}

/// A reminder ignored on each of the last [days] days it was due goes
/// every other day. [ignoredByDay] holds, newest day first, whether each
/// day it was due went unanswered.
Set<NoteKind> backedOffKinds(Map<NoteKind, List<bool>> ignoredByDay, {int days = 5}) => {
  for (final MapEntry(key: k, value: v) in ignoredByDay.entries)
    if (v.length >= days && v.take(days).every((x) => x)) k,
};
