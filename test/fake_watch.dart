import 'dart:math' as math;

import 'package:gymco/data/health_sync.dart';
import 'package:gymco/domain/recovery.dart';

import 'helpers.dart';

/// A health store fed by a watch: two weeks of nights and heart readings, a
/// run this morning, and heart rate through the afternoon.
class FakeWatch extends NoHealth {
  FakeWatch({this.lastNight = 442, this.restingToday = 52, this.hrvToday = 68});
  final int lastNight;
  final double restingToday;
  final double hrvToday;
  var connects = 0;

  DateTime _wake(int back) => DateTime(testNow.year, testNow.month, testNow.day - back, 6, 50);

  @override
  Future<bool> available() async => true;
  @override
  Future<bool> connect() async {
    connects++;
    return true;
  }

  @override
  Future<int?> stepsToday(DateTime now) async => 8410;

  @override
  Future<List<Sample>> samples(Metric metric, DateTime from, DateTime to) async {
    final out = <Sample>[];
    void day(int back, double v, {int minutes = 0}) {
      final end = _wake(back);
      final s = Sample(end.subtract(Duration(minutes: minutes)), end, v, source: 'Apple Watch');
      if (!s.to.isBefore(from) && !s.to.isAfter(to)) out.add(s);
    }

    switch (metric) {
      case Metric.sleep:
        for (var b = 0; b < 14; b++) {
          final m = b == 0 ? lastNight : 395 + (b * 37) % 40;
          day(b, m.toDouble(), minutes: m);
        }
      case Metric.restingHr:
        for (var b = 0; b < 14; b++) {
          day(b, b == 0 ? restingToday : 55 + (b % 3));
        }
      case Metric.hrv:
        for (var b = 0; b < 14; b++) {
          day(b, b == 0 ? hrvToday : 58 + (b * 7) % 8);
        }
      case Metric.activeKcal:
        out.add(Sample(from, to, 486, source: 'Apple Watch'));
      case Metric.heartRate:
        final span = to.difference(from).inMinutes;
        for (var m = 0; m <= span; m++) {
          // Up during each set, down through the rest after it.
          final effort = math.max(0, math.sin(m / 3.2));
          final v = 96 + 34 * effort + 18 * (m / math.max(1, span));
          final at = from.add(Duration(minutes: m));
          out.add(Sample(at, at, v.roundToDouble(), source: 'Apple Watch'));
        }
    }
    return out;
  }

  @override
  Future<List<WatchWorkout>> workouts(DateTime from, DateTime to) async {
    final start = DateTime(testNow.year, testNow.month, testNow.day, 7, 10);
    return [
      if (!start.isBefore(from) && !start.isAfter(to))
        WatchWorkout(
          start: start,
          end: start.add(const Duration(minutes: 34)),
          kind: WorkoutKind.run,
          source: 'Apple Watch',
          kcal: 352,
        ),
    ];
  }
}
