import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/checkin.dart';
import 'package:gymco/domain/energy.dart';

/// [n] days ending today, eating [kcal] while the trend moves [kgPerDay].
List<EnergyDay> run(int n, {double kcal = 2500, double startKg = 80, double kgPerDay = 0, bool weigh = true}) => [
  for (var i = 0; i < n; i++)
    EnergyDay(
      date: DateTime(2026, 9, 1 + i),
      intakeKcal: kcal,
      complete: true,
      trendWeightKg: weigh ? startKg + kgPerDay * i : null,
    ),
];

const macros = Macros(protein: 176, carbs: 245, fat: 64);

CheckIn check(List<EnergyDay> days, {double current = 2319, double rate = -0.5}) => weeklyCheckIn(
  days: days,
  goal: Goal.cut,
  goalRatePct: rate,
  weightKg: 80,
  currentKcal: current,
  currentMacros: macros,
);

void main() {
  test('under two weeks of logging is not enough, and targets stay', () {
    final c = check(run(10));
    expect(c.kind, CheckInKind.notEnough);
    expect(c.nextKcal, 2319);
    expect(c.daysToMeasure, 4);
  });

  test('measured expenditure moves the target at most 120 a week', () {
    // 2,500 in and 0.057 kg a day lost: about 2,940 out.
    final c = check(run(21, kgPerDay: -0.4 / 7));
    expect(c.kind, CheckInKind.onPlan);
    expect(c.expenditure, closeTo(2940, 1));
    // The plan asks for ~2,500; one week can only move it +120.
    expect(c.nextKcal, 2439);
    // Protein and fat stay; carbs take all 120 kcal.
    expect(c.nextMacros.protein, 176);
    expect(c.nextMacros.fat, 64);
    expect(c.nextMacros.carbs, 275);
  });

  test('losing far faster than asked is flagged with a way back', () {
    // 1.3 % a week of 80 kg.
    final c = check(run(21, kcal: 1900, kgPerDay: -1.04 / 7));
    expect(c.kind, CheckInKind.fast);
    expect(c.observedRatePct, lessThan(-1.2));
    expect(c.fastExtraKcal, inInclusiveRange(10, 300));
  });

  test('a flat trend for two weeks on a cut is a stall', () {
    final c = check(run(21));
    expect(c.kind, CheckInKind.stall);
    expect(c.expenditure, closeTo(2500, 1));
  });

  test('the last seven days report intake, change and days logged', () {
    final days = run(21, kgPerDay: -0.05);
    days[20] = EnergyDay(date: days[20].date, intakeKcal: 0, complete: false, trendWeightKg: days[20].trendWeightKg);
    final c = check(days);
    expect(c.daysLogged, 6);
    expect(c.avgIntake, 2500);
    expect(c.trendChangeKg, closeTo(-0.3, 1e-9));
  });
}
