import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/photo_store.dart';
import '../data/training.dart';
import '../domain/checkin.dart';
import '../domain/energy.dart';
import '../domain/volume.dart';
import '../domain/workout.dart';
import 'providers.dart';
import 'training_providers.dart';

DateTime parseDay(String k) => DateTime.parse(k);

/// The weight story: every weigh-in, its smoothed trend, and the rate.
class WeightSummary {
  const WeightSummary({required this.points, required this.trend, required this.startKg, this.ratePct});

  /// Weigh-ins, oldest first.
  final List<(DateTime, double)> points;

  /// The trend at each weigh-in, same order.
  final List<double> trend;
  final double startKg;

  /// Signed % of body weight a week, over the last two weeks of trend.
  final double? ratePct;

  double? get current => trend.isEmpty ? null : trend.last;
  double? get sinceStart => current == null ? null : current! - startKg;
}

final weightSummaryProvider = FutureProvider<WeightSummary>((ref) async {
  final ins = await ref.watch(weighInsProvider.future);
  final profile = ref.watch(profileProvider);
  final points = [for (final (d, kg) in ins) (parseDay(d), kg)];
  final trend = trendWeights([for (final p in points) p.$2]);
  double? rate;
  if (points.length >= 2) {
    final last = points.last.$1;
    var i = points.length - 1;
    while (i > 0 && last.difference(points[i - 1].$1).inDays <= 14) {
      i--;
    }
    final span = last.difference(points[i].$1).inDays;
    if (span >= 7) rate = observedRatePctPerWeek(fromKg: trend[i], toKg: trend.last, days: span);
  }
  return WeightSummary(
    points: points,
    trend: trend,
    startKg: points.isEmpty ? (profile?.weightKg ?? 0) : points.first.$2,
    ratePct: rate,
  );
});

final measurementsProvider = FutureProvider.family<List<(String, double)>, String>(
  (ref, kind) => ref.watch(dbProvider).measurements(kind),
);

class ProgressActions {
  ProgressActions(this.ref);
  final Ref ref;

  Future<void> weigh(DateTime day, double kg) async {
    await ref.read(dbProvider).setWeight(dayKey(day), kg);
    ref.invalidate(weighInsProvider);
    toHealth(ref, (h) => h.writeWeight(kg, ref.read(clockProvider)()));
  }

  Future<void> unweigh(String day) async {
    await ref.read(dbProvider).deleteWeight(day);
    ref.invalidate(weighInsProvider);
  }

  Future<void> measure(DateTime day, String kind, double v) async {
    await ref.read(dbProvider).setMeasurement(dayKey(day), kind, v);
    ref.invalidate(measurementsProvider(kind));
  }

  /// Take the check-in's target and remember what was measured.
  Future<void> acceptCheckIn(CheckIn c) async {
    final p = ref.read(profileProvider);
    if (p == null) return;
    await ref.read(profileProvider.notifier).save(p.withTargets(c.nextKcal, c.nextMacros));
    final prefs = ref.read(prefsProvider);
    await prefs.setString('lastCheckIn', ref.read(clockProvider)().toIso8601String());
    if (c.expenditure != null) await prefs.setDouble('lastExpenditure', c.expenditure!);
    ref.invalidate(checkInProvider);
  }

  /// Change the target by [deltaKcal]; carbs take it.
  Future<void> shiftTarget(double deltaKcal) async {
    final p = ref.read(profileProvider);
    if (p == null) return;
    await ref
        .read(profileProvider.notifier)
        .save(p.withTargets(p.targetKcal + deltaKcal, shiftCarbs(p.targets, deltaKcal)));
    await ref.read(prefsProvider).setString('lastCheckIn', ref.read(clockProvider)().toIso8601String());
    ref.invalidate(checkInProvider);
  }
}

final progressActionsProvider = Provider<ProgressActions>(ProgressActions.new);

/// The last 28 days as the energy engine reads them. A day counts when
/// breakfast, lunch and dinner are all logged.
final energyDaysProvider = FutureProvider<List<EnergyDay>>((ref) async {
  final now = ref.watch(clockProvider)();
  ref.watch(loggedDaysProvider);
  final ws = await ref.watch(weightSummaryProvider.future);
  final today = DateTime(now.year, now.month, now.day);
  final from = DateTime(today.year, today.month, today.day - 27);
  final totals = await ref.watch(dbProvider).dayTotals(dayKey(from), dayKey(today));
  final trendOn = {for (var i = 0; i < ws.points.length; i++) dayKey(ws.points[i].$1): ws.trend[i]};
  const needed = {Meal.breakfast, Meal.lunch, Meal.dinner};
  return [
    for (var i = 0; i < 28; i++)
      () {
        final d = DateTime(from.year, from.month, from.day + i);
        final t = totals[dayKey(d)];
        return EnergyDay(
          date: d,
          intakeKcal: t?.kcal ?? 0,
          complete: t != null && t.meals.containsAll(needed),
          trendWeightKg: trendOn[dayKey(d)],
        );
      }(),
  ];
});

final checkInProvider = FutureProvider<CheckIn?>((ref) async {
  final p = ref.watch(profileProvider);
  if (p == null) return null;
  final days = await ref.watch(energyDaysProvider.future);
  final ws = await ref.watch(weightSummaryProvider.future);
  return weeklyCheckIn(
    days: days,
    goal: p.goal,
    goalRatePct: p.ratePctPerWeek,
    weightKg: ws.current ?? p.weightKg,
    currentKcal: p.targetKcal,
    currentMacros: p.targets,
    previousExpenditure: ref.watch(prefsProvider).getDouble('lastExpenditure'),
  );
});

/// Hard sets this week per muscle group; a secondary muscle counts half.
final weekGroupSetsProvider = FutureProvider<Map<MuscleGroup, double>>((ref) async {
  final sets = await ref.watch(setsThisWeekProvider.future);
  final lib = await ref.watch(exerciseLibraryProvider.future);
  final out = <MuscleGroup, double>{};
  for (final s in sets) {
    final e = lib[s.exerciseId];
    if (e == null) continue;
    final w = s.type.hardSetWeight;
    if (w == 0) continue;
    final main = {for (final m in e.primary) ?groupOf(m)};
    for (final g in main) {
      out[g] = (out[g] ?? 0) + w;
    }
    for (final g in {for (final m in e.secondary) ?groupOf(m)}.difference(main)) {
      out[g] = (out[g] ?? 0) + w / 2;
    }
  }
  return out;
});

/// A lift's estimated 1RM now and eight weeks ago.
class LiftTrend {
  const LiftTrend({required this.exercise, required this.now, this.before, required this.sessions});
  final Exercise exercise;
  final double now;
  final double? before;
  final int sessions;

  double? get changePct => before == null || before == 0 ? null : (now - before!) / before! * 100;
}

/// The lifts trained most in the last 16 weeks, most-trained first.
final liftTrendsProvider = FutureProvider<List<LiftTrend>>((ref) async {
  final now = ref.watch(clockProvider)();
  ref.watch(recentWorkoutsProvider);
  final lib = await ref.watch(exerciseLibraryProvider.future);
  final since = now.subtract(const Duration(days: 112));
  final sets = await ref.watch(dbProvider).setsSince(since);
  final byEx = <String, List<LoggedExerciseSet>>{};
  for (final s in sets) {
    byEx.putIfAbsent(s.exerciseId, () => []).add(s);
  }
  final out = <LiftTrend>[];
  for (final id in byEx.keys) {
    final e = lib[id];
    if (e == null) continue;
    final hist = await ref.watch(exerciseHistoryProvider(id).future);
    final pts = [
      for (final (at, ss) in hist)
        if (ss
                .where((x) => x.type != SetType.warmup)
                .map((x) => estimatedOneRepMax(x.weightKg, x.reps))
                .whereType<double>()
                .fold<double?>(null, (b, v) => b == null || v > b ? v : b)
            case final rm?)
          (at, rm),
    ];
    if (pts.isEmpty) continue;
    final old = pts.where((p) => now.difference(p.$1).inDays >= 56).firstOrNull;
    out.add(LiftTrend(exercise: e, now: pts.first.$2, before: old?.$2, sessions: pts.length));
  }
  out.sort((a, b) => b.sessions.compareTo(a.sessions));
  return out;
});

final photoStoreProvider = Provider<PhotoStore>((_) => DevicePhotoStore());

/// Progress photos by day, newest day first.
final progressPhotosProvider = FutureProvider<List<(String, Map<Pose, ProgressPhoto>)>>((ref) async {
  final all = await ref.watch(photoStoreProvider).list();
  final byDay = <String, Map<Pose, ProgressPhoto>>{};
  for (final p in all) {
    (byDay[p.day] ??= {})[p.pose] = p;
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final d in days) (d, byDay[d]!)];
});
