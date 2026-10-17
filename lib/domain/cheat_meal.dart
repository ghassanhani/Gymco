/// Cheat meals.
///
/// Banked: planned ahead. A slice comes off each day from today until the
/// meal (never below the floor), so the week still averages on target. Over
/// 300 a day is flagged as steep. Protein is never part of the slice.
///
/// Free: not logged at all. That day leaves the expenditure average and still
/// counts as a meal for the streak.
library;

import 'dart:math' as math;

import 'energy.dart';

enum CheatAllowance { off, oncePerWeek, twicePerWeek }

extension CheatAllowanceX on CheatAllowance {
  int get perWeek => index;
}

const double steepSliceKcal = 300;

class BankDay {
  const BankDay({required this.date, required this.target, required this.slice});
  final DateTime date;
  final Macros target;
  final double slice;
}

class BankPlan {
  const BankPlan({required this.days, required this.banked, required this.requested, required this.mealDayTarget});

  /// The days the slice comes off, today first.
  final List<BankDay> days;

  /// What the floor allowed to bank in total.
  final double banked;
  final double requested;

  /// The meal day's target with the banked kcal added on.
  final Macros mealDayTarget;

  double get slicePerDay => days.isEmpty ? 0 : banked / days.length;
  bool get steep => slicePerDay > steepSliceKcal;
  bool get capped => banked + 0.5 < requested;
}

/// Take [extraKcal] off the days from [today] up to (not including) [mealDay].
/// The slice comes out of carbs and fat in proportion; protein is untouched.
BankPlan planBankedCheat({
  required DateTime today,
  required DateTime mealDay,
  required double extraKcal,
  required Macros dailyTarget,
  double floor = defaultKcalFloor,
}) {
  final start = DateTime(today.year, today.month, today.day);
  final end = DateTime(mealDay.year, mealDay.month, mealDay.day);
  final n = math.max(1, end.difference(start).inDays);

  final perDayWanted = extraKcal / n;
  final room = math.max(0.0, dailyTarget.kcal - floor);
  final slice = math.min(perDayWanted, room);

  final nonProtein = dailyTarget.carbs * 4 + dailyTarget.fat * 9;
  final carbShare = nonProtein == 0 ? 0.5 : dailyTarget.carbs * 4 / nonProtein;

  Macros cut(double kcal) => Macros(
    protein: dailyTarget.protein,
    carbs: math.max(0, dailyTarget.carbs - kcal * carbShare / 4),
    fat: math.max(0, dailyTarget.fat - kcal * (1 - carbShare) / 9),
  );
  Macros add(double kcal) => Macros(
    protein: dailyTarget.protein,
    carbs: dailyTarget.carbs + kcal * carbShare / 4,
    fat: dailyTarget.fat + kcal * (1 - carbShare) / 9,
  );

  final days = [
    for (var i = 0; i < n; i++)
      BankDay(date: DateTime(start.year, start.month, start.day + i), target: cut(slice), slice: slice),
  ];
  final banked = slice * n;
  return BankPlan(days: days, banked: banked, requested: extraKcal, mealDayTarget: add(banked));
}
