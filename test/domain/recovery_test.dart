import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/recovery.dart';

void main() {
  final now = DateTime(2026, 10, 25, 9);
  DateTime day(int back, [int hour = 7]) => DateTime(2026, 10, 25 - back, hour);

  /// One night per day: [mins] asleep, ending at 7am.
  List<Sample> nights(List<int> mins, {String source = 'watch'}) => [
    for (var i = 0; i < mins.length; i++)
      Sample(day(i).subtract(Duration(minutes: mins[i])), day(i), mins[i].toDouble(), source: source),
  ];
  List<Sample> daily(List<double> v) => [for (var i = 0; i < v.length; i++) Sample(day(i), day(i), v[i])];

  test('the normal is the middle of the earlier days, and needs three', () {
    expect(baseline([60, 50, 55]), 55);
    expect(baseline([60, 50, 55, 70]), 57.5);
    expect(baseline([60, 50]), isNull);
  });

  test('a good night and a rested heart say ready', () {
    final r = recoveryFrom(
      now: now,
      sleep: nights([470, 420, 430, 410]),
      restingHr: daily([50, 54, 53, 55]),
      hrv: daily([70, 60, 62, 58]),
      activeKcal: const [],
    );
    expect(r.sleepMin, 470);
    expect(r.sleepBase, 420);
    expect(r.restingHr, 50);
    expect(r.restingBase, 54);
    expect(r.readiness, Readiness.ready);
  });

  test('short sleep and a raised resting heart rate say go easy', () {
    final r = recoveryFrom(
      now: now,
      sleep: nights([300, 420, 430, 410]),
      restingHr: daily([62, 54, 53, 55]),
      hrv: daily([60, 60, 62, 58]),
      activeKcal: const [],
    );
    expect(r.readiness, Readiness.easy);
  });

  test('one sign off says steady', () {
    final r = recoveryFrom(
      now: now,
      sleep: nights([440, 420, 430, 410]),
      restingHr: daily([54, 54, 53, 55]),
      hrv: daily([45, 60, 62, 58]),
      activeKcal: const [],
    );
    expect(r.readiness, Readiness.steady);
  });

  test('without a normal yet, Gymco is still learning', () {
    final r = recoveryFrom(now: now, sleep: nights([450]), restingHr: daily([55]), hrv: const [], activeKcal: const []);
    expect(r.readiness, Readiness.learning);
  });

  test('two sources counting the same night are not added together', () {
    final r = recoveryFrom(
      now: now,
      sleep: [
        ...nights([420], source: 'watch'),
        ...nights([400], source: 'ring'),
      ],
      restingHr: const [],
      hrv: const [],
      activeKcal: [
        Sample(day(0, 8), day(0, 8), 300, source: 'watch'),
        Sample(day(0, 8), day(0, 8), 250, source: 'phone'),
        Sample(day(0, 9), day(0, 9), 50, source: 'watch'),
      ],
    );
    expect(r.sleepMin, 420);
    expect(r.activeKcal, 350);
  });

  test('watch workouts of ten minutes or more keep their day', () {
    WatchWorkout w(DateTime start, int min) => WatchWorkout(
      start: start,
      end: start.add(Duration(minutes: min)),
      kind: WorkoutKind.run,
      source: 'Watch',
    );
    final days = watchWorkoutDays([w(day(0), 32), w(day(1), 6), w(day(2), 10)]);
    expect(days, {'2026-10-25', '2026-10-23'});
  });

  test('heart rate across a session: average, peak and slices', () {
    final start = DateTime(2026, 10, 25, 18);
    final end = start.add(const Duration(minutes: 48));
    final samples = [
      for (var m = 0; m < 48; m += 2)
        Sample(start.add(Duration(minutes: m)), start.add(Duration(minutes: m)), 100.0 + m),
      Sample(start.subtract(const Duration(minutes: 5)), start, 180), // before it began
    ];
    final h = HeartSummary.of(samples, start, end)!;
    expect(h.peak, 146);
    expect(h.avg, 123);
    expect(h.bars.length, HeartSummary.slices);
    expect(h.bars.whereType<double>().length, HeartSummary.slices);
    expect(HeartSummary.of(samples.take(2), start, end), isNull);
  });

  test('the score weighs sleep 40 and the heart 60, against the usual', () {
    expect(
      const Recovery(sleepMin: 470, sleepBase: 420, restingHr: 50, restingBase: 54, hrv: 70, hrvBase: 60).score,
      99,
    );
    // A usual night and a usual heart are ready.
    expect(
      const Recovery(sleepMin: 420, sleepBase: 420, restingHr: 54, restingBase: 54, hrv: 60, hrvBase: 60).score,
      85,
    );
    expect(
      const Recovery(sleepMin: 300, sleepBase: 420, restingHr: 62, restingBase: 54, hrv: 60, hrvBase: 60).score,
      46,
    );
    // Sleep alone gives no score yet.
    expect(const Recovery(sleepMin: 450).score, isNull);
  });
}
