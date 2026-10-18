/// How a day counts toward the streak.
///
/// A day is kept when meals are logged and the user either trains or takes a
/// planned rest day. Logging counts, not eating less. One freeze is earned
/// every 7 kept days (hold up to 3), and a missed day can be repaired until
/// 23:59 the next day. A broken streak keeps the best run on record.
library;

const int daysPerFreeze = 7;
const int maxFreezes = 3;

class StreakDay {
  const StreakDay({
    required this.date,
    this.mealsLogged = false,
    this.trained = false,
    this.plannedRest = false,
    this.paused = false,
  });

  final DateTime date;

  /// Meals logged for the day; a free cheat meal counts as a logged meal.
  final bool mealsLogged;
  final bool trained;
  final bool plannedRest;

  /// Inside a pause (ill, travelling): the day neither counts nor breaks.
  final bool paused;

  bool get kept => mealsLogged && (trained || plannedRest);
}

enum DayMark { kept, frozen, repairable, missed, today, open }

class StreakState {
  const StreakState({
    required this.current,
    required this.best,
    required this.freezes,
    required this.keptTotal,
    required this.marks,
  });

  /// Kept days in the current run (frozen days hold it, they do not add).
  final int current;
  final int best;
  final int freezes;
  final int keptTotal;
  final Map<DateTime, DayMark> marks;

  /// Yesterday is missed but still inside its repair window.
  bool get canRepair => marks.values.contains(DayMark.repairable);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Walk the history from [start] to [now] and work out the streak.
StreakState computeStreak({required List<StreakDay> history, required DateTime start, required DateTime now}) {
  final byDay = {for (final d in history) _day(d.date): d};
  final today = _day(now);
  final yesterday = today.subtract(const Duration(days: 1));

  var current = 0;
  var best = 0;
  var freezes = 0;
  var keptTotal = 0;
  var keptSinceFreeze = 0;
  final marks = <DateTime, DayMark>{};

  void keep(DateTime d) {
    current++;
    keptTotal++;
    keptSinceFreeze++;
    if (keptSinceFreeze == daysPerFreeze) {
      keptSinceFreeze = 0;
      if (freezes < maxFreezes) freezes++;
    }
    if (current > best) best = current;
    marks[d] = DayMark.kept;
  }

  for (var d = _day(start); !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) {
    final entry = byDay[d];
    if (entry != null && entry.kept) {
      keep(d);
      continue;
    }
    if (entry != null && entry.paused && d != today) {
      marks[d] = DayMark.frozen;
      continue;
    }
    if (d == today) {
      marks[d] = DayMark.today;
    } else if (d == yesterday) {
      // Still inside the 23:59 window: the run is held, not broken.
      marks[d] = DayMark.repairable;
    } else if (freezes > 0) {
      freezes--;
      marks[d] = DayMark.frozen;
    } else {
      marks[d] = DayMark.missed;
      current = 0;
      keptSinceFreeze = 0;
    }
  }

  return StreakState(current: current, best: best, freezes: freezes, keptTotal: keptTotal, marks: marks);
}
