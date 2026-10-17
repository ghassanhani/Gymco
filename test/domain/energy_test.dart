import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/energy.dart';

void main() {
  group('Mifflin-St Jeor seed', () {
    test('male and female formulas', () {
      expect(mifflinStJeor(sex: Sex.male, weightKg: 80, heightCm: 180, ageYears: 30), closeTo(1780, 0.01));
      expect(mifflinStJeor(sex: Sex.female, weightKg: 60, heightCm: 165, ageYears: 30), closeTo(1320.25, 0.01));
    });

    test('activity multiplier applies', () {
      final s = seedExpenditure(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activity: ActivityLevel.moderate,
      );
      expect(s, closeTo(1780 * 1.55, 0.01));
    });
  });

  group('trend weight', () {
    test('one spike moves the trend a tenth of the way', () {
      final t = trendWeights([80, 80, 82]);
      expect(t.last, closeTo(80.2, 1e-9));
    });
  });

  group('adaptive expenditure', () {
    final start = DateTime(2026, 9, 1);
    List<EnergyDay> days(
      int n,
      double intake,
      double fromKg,
      double toKg, {
      Set<int> incomplete = const {},
      Set<int> free = const {},
    }) {
      return [
        for (var i = 0; i < n; i++)
          EnergyDay(
            date: start.add(Duration(days: i)),
            intakeKcal: incomplete.contains(i) ? 600 : intake,
            complete: !incomplete.contains(i),
            freeCheat: free.contains(i),
            trendWeightKg: fromKg + (toKg - fromKg) * i / (n - 1),
          ),
      ];
    }

    test('null before 14 usable days', () {
      expect(adaptiveExpenditure(days(13, 2200, 80, 79.8)), isNull);
    });

    test('intake minus stored energy', () {
      // 21 days, losing 1 kg over 20 days -> 385 kcal/day deficit.
      final e = adaptiveExpenditure(days(21, 2200, 80, 79));
      expect(e, closeTo(2200 + 7700 / 20, 0.01));
    });

    test('incomplete and free-cheat days leave the average', () {
      final e = adaptiveExpenditure(days(21, 2200, 80, 80, incomplete: {3, 4}, free: {10}));
      expect(e, closeTo(2200, 0.01));
    });

    test('only the last 28 days count', () {
      final old = days(40, 3000, 80, 80);
      final recent = [for (final d in old.skip(12)) EnergyDay(date: d.date, intakeKcal: 2000, trendWeightKg: 80)];
      final e = adaptiveExpenditure([...old.take(12), ...recent]);
      expect(e, closeTo(2000, 0.01));
    });
  });

  group('rate and targets', () {
    test('cut rate is capped at 1%/week', () {
      expect(clampRate(Goal.cut, 1.5), -1.0);
      expect(clampRate(Goal.cut, -0.5), -0.5);
      expect(clampRate(Goal.maintain, 0.7), 0);
    });

    test('warning above 0.85%', () {
      expect(rateNeedsWarning(-0.9), isTrue);
      expect(rateNeedsWarning(-0.85), isFalse);
    });

    test('daily target honours the floor', () {
      expect(dailyTarget(expenditure: 2500, weightKg: 80, ratePctPerWeek: -0.5), closeTo(2500 - 0.4 * 7700 / 7, 0.01));
      expect(dailyTarget(expenditure: 1800, weightKg: 80, ratePctPerWeek: -1), defaultKcalFloor);
    });

    test('check-in moves at most 120 kcal', () {
      expect(checkInTarget(current: 2500, proposed: 2200), 2380);
      expect(checkInTarget(current: 2500, proposed: 2560), 2560);
      expect(checkInTarget(current: 2500, proposed: 2900), 2620);
    });

    test('stall needs a cut, 14 days and a flat trend', () {
      expect(isStall(goal: Goal.cut, completeDays: 14, observedRatePct: -0.05), isTrue);
      expect(isStall(goal: Goal.cut, completeDays: 10, observedRatePct: 0), isFalse);
      expect(isStall(goal: Goal.cut, completeDays: 20, observedRatePct: -0.5), isFalse);
    });

    test('macros add back up to the target', () {
      final m = macroTargets(kcal: 2500, weightKg: 80, goal: Goal.cut);
      expect(m.protein, 176);
      expect(m.kcal, closeTo(2500, 6));
    });
  });
}
