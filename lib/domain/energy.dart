/// Energy maths for Gymco.
///
/// Expenditure is derived, never guessed: average logged intake minus the
/// energy implied by the change in trend weight, over a rolling 14–28 day
/// window. Mifflin-St Jeor only seeds week one.
library;

import 'dart:math' as math;

enum Sex { male, female }

enum Goal { cut, maintain, bulk }

/// Energy stored in a kilogram of body mass change, kcal.
const double kcalPerKg = 7700;

/// Weekly target changes are capped at ±120 kcal.
const double maxWeeklyTargetChange = 120;

/// Rate of change is capped at 1% of body weight per week.
const double maxRatePctPerWeek = 1.0;

/// Above this rate the app warns explicitly.
const double warnRatePctPerWeek = 0.85;

/// Default floor no daily target goes below.
const double defaultKcalFloor = 1700;

/// Smallest and largest windows the adaptive estimate uses.
const int minWindowDays = 14;
const int maxWindowDays = 28;

/// Activity multipliers used only to seed week one.
enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  high(1.725),
  athlete(1.9);

  const ActivityLevel(this.multiplier);
  final double multiplier;
}

/// Mifflin-St Jeor resting energy, kcal/day.
double mifflinStJeor({required Sex sex, required double weightKg, required double heightCm, required int ageYears}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
  return sex == Sex.male ? base + 5 : base - 161;
}

/// The week-one expenditure seed.
double seedExpenditure({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int ageYears,
  required ActivityLevel activity,
}) => mifflinStJeor(sex: sex, weightKg: weightKg, heightCm: heightCm, ageYears: ageYears) * activity.multiplier;

/// Exponentially smoothed trend weight. One noisy weigh-in moves it a tenth
/// of the way, so a bloated Tuesday never reads as a gain.
List<double> trendWeights(List<double> weighIns, {double alpha = 0.1}) {
  final out = <double>[];
  for (final w in weighIns) {
    out.add(out.isEmpty ? w : out.last + alpha * (w - out.last));
  }
  return out;
}

/// One day as the expenditure estimate sees it.
class EnergyDay {
  const EnergyDay({
    required this.date,
    required this.intakeKcal,
    this.complete = true,
    this.freeCheat = false,
    this.trendWeightKg,
  });

  final DateTime date;
  final double intakeKcal;

  /// A day with gaps is dropped rather than counted as low intake.
  final bool complete;

  /// A free cheat meal is not logged, so its day leaves the average.
  final bool freeCheat;

  final double? trendWeightKg;

  bool get countsForIntake => complete && !freeCheat;
}

/// Adaptive expenditure from logged days, or null when there is not yet
/// enough data (fewer than [minWindowDays] usable days, or no weight span).
double? adaptiveExpenditure(List<EnergyDay> days) {
  if (days.isEmpty) return null;
  final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
  final window = sorted.length > maxWindowDays ? sorted.sublist(sorted.length - maxWindowDays) : sorted;

  final usable = window.where((d) => d.countsForIntake).toList();
  if (usable.length < minWindowDays) return null;

  final weighed = window.where((d) => d.trendWeightKg != null).toList();
  if (weighed.length < 2) return null;
  final first = weighed.first;
  final last = weighed.last;
  final spanDays = last.date.difference(first.date).inDays;
  if (spanDays <= 0) return null;

  final avgIntake = usable.map((d) => d.intakeKcal).reduce((a, b) => a + b) / usable.length;
  final storedPerDay = (last.trendWeightKg! - first.trendWeightKg!) * kcalPerKg / spanDays;
  return avgIntake - storedPerDay;
}

/// Clamp a requested rate (% body weight per week, signed: negative loses)
/// to the safe range for the goal.
double clampRate(Goal goal, double ratePctPerWeek) {
  switch (goal) {
    case Goal.maintain:
      return 0;
    case Goal.cut:
      return -ratePctPerWeek.abs().clamp(0, maxRatePctPerWeek).toDouble();
    case Goal.bulk:
      return ratePctPerWeek.abs().clamp(0, maxRatePctPerWeek / 2).toDouble();
  }
}

/// Whether a rate (signed) needs the explicit warning.
bool rateNeedsWarning(double ratePctPerWeek) => ratePctPerWeek.abs() > warnRatePctPerWeek;

/// Daily energy target for an expenditure and a signed weekly rate.
double dailyTarget({
  required double expenditure,
  required double weightKg,
  required double ratePctPerWeek,
  double floor = defaultKcalFloor,
}) {
  final weeklyKg = weightKg * ratePctPerWeek / 100;
  final dailyDelta = weeklyKg * kcalPerKg / 7;
  return math.max(floor, expenditure + dailyDelta);
}

/// The weekly check-in: move toward the new target, never more than ±120.
double checkInTarget({required double current, required double proposed}) {
  final delta = (proposed - current).clamp(-maxWeeklyTargetChange, maxWeeklyTargetChange);
  return current + delta;
}

/// Actual weekly rate from trend weights, % of body weight per week.
double observedRatePctPerWeek({required double fromKg, required double toKg, required int days}) {
  if (days <= 0 || fromKg <= 0) return 0;
  return (toKg - fromKg) / fromKg * 100 * 7 / days;
}

/// A genuine stall: on a cut, at least 14 complete days, and the trend has
/// moved less than 0.1% a week.
bool isStall({required Goal goal, required int completeDays, required double observedRatePct}) =>
    goal == Goal.cut && completeDays >= minWindowDays && observedRatePct > -0.1;

/// Daily macro targets in grams.
class Macros {
  const Macros({required this.protein, required this.carbs, required this.fat});
  final double protein;
  final double carbs;
  final double fat;

  double get kcal => protein * 4 + carbs * 4 + fat * 9;

  Macros operator +(Macros o) => Macros(protein: protein + o.protein, carbs: carbs + o.carbs, fat: fat + o.fat);

  @override
  String toString() => 'Macros(p: $protein, c: $carbs, f: $fat)';
}

/// Split a kcal target: protein per kg first, then fat as a share of energy,
/// carbs take what is left.
Macros macroTargets({
  required double kcal,
  required double weightKg,
  required Goal goal,
  double? proteinPerKg,
  double fatShare = 0.25,
}) {
  final ppk = proteinPerKg ?? (goal == Goal.cut ? 2.2 : 1.8);
  final protein = (weightKg * ppk).roundToDouble();
  final fat = (kcal * fatShare / 9).roundToDouble();
  final carbs = math.max(0.0, ((kcal - protein * 4 - fat * 9) / 4).roundToDouble());
  return Macros(protein: protein, carbs: carbs, fat: fat);
}
