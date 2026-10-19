/// The weekly check-in: what the last weeks of logging and weighing say,
/// and what next week's target should be.
///
/// Expenditure is measured, not guessed: average intake minus what the
/// trend weight says was stored or lost. The target then moves toward what
/// that expenditure and the chosen rate call for, never more than 120 kcal
/// in a week. Two cases get their own screen: losing much faster than asked
/// (muscle is at risk) and a genuine stall.
library;

import 'dart:math' as math;

import 'energy.dart';

enum CheckInKind {
  /// Fewer than two weeks of usable days, or no weight span yet.
  notEnough,

  /// Measured, and the rate is about where it was asked to be.
  onPlan,

  /// Losing much faster than the plan.
  fast,

  /// A cut that has stopped moving for at least two weeks.
  stall,
}

class CheckIn {
  const CheckIn({
    required this.kind,
    required this.currentKcal,
    required this.nextKcal,
    required this.nextMacros,
    required this.goalRatePct,
    required this.daysLogged,
    this.expenditure,
    this.previousExpenditure,
    this.avgIntake,
    this.trendChangeKg,
    this.observedRatePct,
    this.usableDays = 0,
    this.fastExtraKcal = 0,
  });

  final CheckInKind kind;
  final double currentKcal;

  /// The target to accept: capped at ±120 from [currentKcal].
  final double nextKcal;
  final Macros nextMacros;

  /// Signed, % of body weight per week; negative loses.
  final double goalRatePct;

  /// Days with food logged in the last seven.
  final int daysLogged;

  final double? expenditure;
  final double? previousExpenditure;

  /// The last seven days' average, over the days that count.
  final double? avgIntake;

  /// Trend weight over the last seven days.
  final double? trendChangeKg;
  final double? observedRatePct;

  /// Days in the window that count toward the measurement.
  final int usableDays;

  /// For [CheckInKind.fast]: kcal a day to add to get back near the plan.
  final double fastExtraKcal;

  double get change => nextKcal - currentKcal;

  /// Days still needed before expenditure can be measured.
  int get daysToMeasure => math.max(0, minWindowDays - usableDays);

  /// About right: within 0.25 % a week of the plan.
  bool get rateOnPlan => observedRatePct != null && (observedRatePct! - goalRatePct).abs() <= 0.25;
}

/// Kcal to move: macros keep protein and fat, carbs take the difference.
Macros shiftCarbs(Macros m, double deltaKcal) =>
    Macros(protein: m.protein, fat: m.fat, carbs: math.max(0, (m.carbs + deltaKcal / 4).roundToDouble()));

/// Work out this week's check-in from up to 28 days, oldest first. Each
/// day carries its intake, whether it was fully logged, and the trend
/// weight on days with a weigh-in.
CheckIn weeklyCheckIn({
  required List<EnergyDay> days,
  required Goal goal,
  required double goalRatePct,
  required double weightKg,
  required double currentKcal,
  required Macros currentMacros,
  double? previousExpenditure,
  double? floor,
}) {
  floor ??= defaultKcalFloor;
  final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
  final window = sorted.length > maxWindowDays ? sorted.sublist(sorted.length - maxWindowDays) : sorted;
  final last7 = window.length > 7 ? window.sublist(window.length - 7) : window;
  final usable = window.where((d) => d.countsForIntake).length;
  final logged7 = last7.where((d) => d.complete).toList();
  final avg7 = logged7.where((d) => !d.freeCheat).map((d) => d.intakeKcal).toList();

  double? trendAt(Iterable<EnergyDay> ds, {required bool first}) {
    final w = ds.where((d) => d.trendWeightKg != null);
    if (w.isEmpty) return null;
    return (first ? w.first : w.last).trendWeightKg;
  }

  // Rate from the last two weeks of trend, when they span at least a week.
  final last14 = window.length > 14 ? window.sublist(window.length - 14) : window;
  final weighed14 = last14.where((d) => d.trendWeightKg != null).toList();
  double? rate;
  if (weighed14.length >= 2) {
    final span = weighed14.last.date.difference(weighed14.first.date).inDays;
    if (span >= 7) {
      rate = observedRatePctPerWeek(
        fromKg: weighed14.first.trendWeightKg!,
        toKg: weighed14.last.trendWeightKg!,
        days: span,
      );
    }
  }
  final t0 = trendAt(last7, first: true), t1 = trendAt(last7, first: false);

  final expenditure = adaptiveExpenditure(window);
  final base = (
    previousExpenditure: previousExpenditure,
    avgIntake: avg7.isEmpty ? null : avg7.reduce((a, b) => a + b) / avg7.length,
    trendChangeKg: t0 == null || t1 == null ? null : t1 - t0,
    daysLogged: logged7.length,
  );

  if (expenditure == null) {
    return CheckIn(
      kind: CheckInKind.notEnough,
      currentKcal: currentKcal,
      nextKcal: currentKcal,
      nextMacros: currentMacros,
      goalRatePct: goalRatePct,
      daysLogged: base.daysLogged,
      previousExpenditure: base.previousExpenditure,
      avgIntake: base.avgIntake,
      trendChangeKg: base.trendChangeKg,
      observedRatePct: rate,
      usableDays: usable,
    );
  }

  final proposed = dailyTarget(expenditure: expenditure, weightKg: weightKg, ratePctPerWeek: goalRatePct, floor: floor);
  final next = checkInTarget(current: currentKcal, proposed: proposed).roundToDouble();

  var kind = CheckInKind.onPlan;
  var extra = 0.0;
  final r = rate;
  if (r != null && goal.losing && r <= -math.max(warnRatePctPerWeek, goalRatePct.abs() * 1.5)) {
    kind = CheckInKind.fast;
    // Half the gap: some of a fast drop is water, and the rest of the
    // correction comes from next week's measurement.
    final gapKcal = (r.abs() - goalRatePct.abs()) * weightKg / 100 * kcalPerKg / 7;
    extra = (math.min(300.0, gapKcal / 2) / 10).round() * 10.0;
  } else if (r != null && isStall(goal: goal, completeDays: usable, observedRatePct: r)) {
    kind = CheckInKind.stall;
  }

  return CheckIn(
    kind: kind,
    currentKcal: currentKcal,
    nextKcal: next,
    nextMacros: shiftCarbs(currentMacros, next - currentKcal),
    goalRatePct: goalRatePct,
    daysLogged: base.daysLogged,
    expenditure: expenditure,
    previousExpenditure: base.previousExpenditure,
    avgIntake: base.avgIntake,
    trendChangeKg: base.trendChangeKg,
    observedRatePct: rate,
    usableDays: usable,
    fastExtraKcal: extra,
  );
}
