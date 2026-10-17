/// The week's schedule, as the prototype defines it.
///
/// A routine names the weekday it belongs on. That is the plan, not a
/// contract: the week slides. Walking the week in order, a day you were meant
/// to train and didn't pushes its routine onto a queue, and the next free day
/// takes the head of that queue. So the block keeps its order even when the
/// dates move: miss Wednesday and Wednesday's session waits for you Thursday.
library;

/// What the schedule needs to know about a routine.
class PlannedRoutine {
  const PlannedRoutine({required this.id, required this.name, this.weekday});
  final int id;
  final String name;

  /// 0 = Monday … 6 = Sunday; null runs on any day, outside the rotation.
  final int? weekday;
}

/// One finished workout, by the day it started.
class DoneWorkout {
  const DoneWorkout({required this.day, required this.name, this.routineId});
  final DateTime day;
  final String name;
  final int? routineId;
}

class ScheduledDay {
  const ScheduledDay({
    required this.date,
    this.done,
    this.routine,
    this.missed,
    this.moved = false,
    this.today = false,
  });

  final DateTime date;

  /// A past day with a workout logged.
  final DoneWorkout? done;

  /// Today or ahead: the routine this day holds.
  final PlannedRoutine? routine;

  /// A past rest day that had a routine due, now carried forward.
  final PlannedRoutine? missed;

  /// The routine here was carried from an earlier missed day.
  final bool moved;
  final bool today;

  bool get rest => done == null && routine == null;
  bool get hasSession => done != null || routine != null;
}

/// Monday-based weekday, 0 … 6.
int weekdayIndex(DateTime d) => d.weekday - 1;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The strip the prototype shows: four days back, today, two ahead.
List<DateTime> stripDays(DateTime today, {int back = 4, int ahead = 2}) {
  final t = _day(today);
  return [for (var i = -back; i <= ahead; i++) DateTime(t.year, t.month, t.day + i)];
}

List<ScheduledDay> schedule({
  required List<DateTime> days,
  required DateTime today,
  required List<PlannedRoutine> routines,
  required List<DoneWorkout> workouts,
}) {
  final t = _day(today);
  PlannedRoutine? dueOn(DateTime d) {
    final w = weekdayIndex(d);
    for (final r in routines) {
      if (r.weekday == w) return r;
    }
    return null;
  }

  DoneWorkout? doneOn(DateTime d) {
    for (final w in workouts) {
      if (_day(w.day) == d) return w;
    }
    return null;
  }

  final queue = <PlannedRoutine>[];
  final out = <ScheduledDay>[];
  for (final raw in days) {
    final d = _day(raw);
    final due = dueOn(d);
    if (d.isBefore(t)) {
      // The past is the log, not the plan.
      final done = doneOn(d);
      if (done != null) {
        out.add(ScheduledDay(date: d, done: done));
      } else {
        if (due != null) queue.add(due);
        out.add(ScheduledDay(date: d, missed: due));
      }
      continue;
    }
    // Today and ahead: overdue work first, then what the day is for.
    final isToday = d == t;
    final done = isToday ? doneOn(d) : null;
    final r = queue.isNotEmpty ? queue.removeAt(0) : due;
    final moved = r != null && r != due;
    if (r != null && due != null && r != due) queue.add(due);
    out.add(ScheduledDay(date: d, routine: r, moved: moved, today: isToday, done: done));
  }
  return out;
}
