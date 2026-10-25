import 'dart:math' as math;

import '../data/models.dart';

/// What a watch or another app recorded as a workout.
enum WorkoutKind { run, walk, ride, swim, strength, hiit, yoga, other }

class WatchWorkout {
  const WatchWorkout({required this.start, required this.end, required this.kind, required this.source, this.kcal});
  final DateTime start;
  final DateTime end;
  final WorkoutKind kind;

  /// The app or watch that recorded it, as the health store names it.
  final String source;
  final int? kcal;

  Duration get length => end.difference(start);
}

/// Shorter than this is a walk to the shop, not a workout.
const minWatchWorkout = Duration(minutes: 10);

/// The days a watch workout keeps for the streak.
Set<String> watchWorkoutDays(Iterable<WatchWorkout> all) => {
  for (final w in all)
    if (w.length >= minWatchWorkout) dayKey(w.start),
};

/// How ready the body looks today, from sleep, resting heart rate and HRV.
enum Readiness { ready, steady, easy, learning }

/// Last night and this morning, next to the person's own normal.
class Recovery {
  const Recovery({
    this.sleepMin,
    this.sleepBase,
    this.restingHr,
    this.restingBase,
    this.hrv,
    this.hrvBase,
    this.activeKcal,
    this.workouts = const [],
    this.kcalWeek = const [],
  });

  final int? sleepMin;
  final double? sleepBase;
  final double? restingHr;
  final double? restingBase;
  final double? hrv;
  final double? hrvBase;
  final int? activeKcal;

  /// Today's, from a watch or another app; Gymco's own are left out.
  final List<WatchWorkout> workouts;

  /// Active energy for the last seven days, oldest first and today last;
  /// null where nothing was read.
  final List<double?> kcalWeek;

  bool get hasBody => sleepMin != null || restingHr != null || hrv != null;
  bool get isEmpty => !hasBody && activeKcal == null && workouts.isEmpty;

  /// Each sign that is off counts one. Two off says go easy, one says hold
  /// steady. Without a normal to compare with, Gymco is still learning,
  /// except that under six hours of sleep is short for anyone.
  Readiness get readiness {
    var off = 0, known = 0;
    if (sleepMin case final s?) {
      known++;
      if (s < 360) off++;
    }
    if ((restingHr, restingBase) case (final r?, final b?)) {
      known++;
      if (r > b + 5) off++;
    }
    if ((hrv, hrvBase) case (final h?, final b?)) {
      known++;
      if (h < b * 0.85) off++;
    }
    if (off >= 2) return Readiness.easy;
    if (off == 1) return Readiness.steady;
    // Sleep alone says little; wait for a heart normal too.
    if (known < 2) return Readiness.learning;
    return Readiness.ready;
  }
}

/// The middle of the day-by-day values: one bad night does not move it.
/// Null until there are three days to go on.
double? baseline(Iterable<double> daily) {
  final v = daily.toList()..sort();
  if (v.length < 3) return null;
  final m = v.length ~/ 2;
  return v.length.isOdd ? v[m] : (v[m - 1] + v[m]) / 2;
}

/// What Gymco reads from the health store besides weight and steps.
enum Metric { heartRate, restingHr, hrv, sleep, activeKcal, steps }

/// One reading. Sleep is in minutes asleep, energy in kcal.
class Sample {
  const Sample(this.from, this.to, this.value, {this.source = ''});
  final DateTime from;
  final DateTime to;
  final double value;
  final String source;
}

/// One value per day, by the day each reading ends (a night belongs to the
/// morning you wake up). Heart readings are averaged. Sleep and energy are
/// added up, but per source, keeping the source with the most: a watch and
/// a phone both counting the same steps of the day must not count twice.
Map<String, double> perDay(Iterable<Sample> samples, {required bool sum}) {
  final acc = <String, Map<String, (double, int)>>{};
  for (final x in samples) {
    final bySource = acc.putIfAbsent(dayKey(x.to), () => {});
    final (s, n) = bySource[sum ? x.source : ''] ?? (0.0, 0);
    bySource[sum ? x.source : ''] = (s + x.value, n + 1);
  }
  return {
    for (final MapEntry(:key, value: bySource) in acc.entries)
      key: sum
          ? bySource.values.map((v) => v.$1).reduce(math.max)
          : bySource.values.first.$1 / bySource.values.first.$2,
  };
}

/// Today's value and the normal from the days before it.
(double?, double?) todayAndBase(Iterable<Sample> samples, DateTime now, {bool sum = false}) {
  final byDay = perDay(samples, sum: sum);
  final today = byDay.remove(dayKey(now));
  return (today, baseline(byDay.values));
}

/// The seven days up to [now] from a day-by-day map, oldest first.
List<double?> lastWeek(Map<String, double> byDay, DateTime now) => [
  for (var i = 6; i >= 0; i--) byDay[dayKey(DateTime(now.year, now.month, now.day - i))],
];

/// Builds today's card from 15 days of readings and today's workouts.
Recovery recoveryFrom({
  required DateTime now,
  required List<Sample> sleep,
  required List<Sample> restingHr,
  required List<Sample> hrv,
  required List<Sample> activeKcal,
  List<WatchWorkout> workouts = const [],
}) {
  final (s, sb) = todayAndBase(sleep, now, sum: true);
  final (r, rb) = todayAndBase(restingHr, now);
  final (h, hb) = todayAndBase(hrv, now);
  final kcalByDay = perDay(activeKcal, sum: true);
  final kcal = kcalByDay[dayKey(now)];
  return Recovery(
    kcalWeek: lastWeek(kcalByDay, now),
    sleepMin: s?.round(),
    sleepBase: sb,
    restingHr: r,
    restingBase: rb,
    hrv: h,
    hrvBase: hb,
    activeKcal: kcal?.round(),
    workouts: [
      for (final w in workouts)
        if (dayKey(w.start) == dayKey(now) && w.length >= minWatchWorkout) w,
    ],
  );
}

/// Heart rate across a Gymco workout.
class HeartSummary {
  const HeartSummary({required this.avg, required this.peak, required this.bars});
  final int avg;
  final int peak;

  /// Average per slice of the session, in order; null where nothing was read.
  final List<double?> bars;

  static const slices = 24;

  /// Null when the watch sent too little to say anything.
  static HeartSummary? of(Iterable<Sample> samples, DateTime start, DateTime end) {
    final span = end.difference(start).inMilliseconds;
    final inside = [
      for (final x in samples)
        if (!x.from.isBefore(start) && !x.from.isAfter(end) && x.value > 25 && x.value < 250) (x.from, x.value),
    ];
    if (span <= 0 || inside.length < 3) return null;
    final sums = List.filled(slices, 0.0), counts = List.filled(slices, 0);
    for (final (at, bpm) in inside) {
      final i = math.min(slices - 1, at.difference(start).inMilliseconds * slices ~/ span);
      sums[i] += bpm;
      counts[i]++;
    }
    return HeartSummary(
      avg: (inside.fold<double>(0, (s, r) => s + r.$2) / inside.length).round(),
      peak: inside.map((r) => r.$2).reduce(math.max).round(),
      bars: [for (var i = 0; i < slices; i++) counts[i] == 0 ? null : sums[i] / counts[i]],
    );
  }
}
