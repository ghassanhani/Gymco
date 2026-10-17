import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/cheat_meal.dart';
import 'package:gymco/domain/energy.dart';

void main() {
  const target = Macros(protein: 195, carbs: 262, fat: 72); // 2,476 kcal
  final today = DateTime(2026, 9, 26);

  test('slices evenly across the days before the meal', () {
    final p = planBankedCheat(today: today, mealDay: DateTime(2026, 9, 30), extraKcal: 800, dailyTarget: target);
    expect(p.days, hasLength(4));
    expect(p.slicePerDay, closeTo(200, 1e-9));
    expect(p.steep, isFalse);
    expect(p.days.first.target.kcal, closeTo(target.kcal - 200, 1e-6));
    expect(p.mealDayTarget.kcal, closeTo(target.kcal + 800, 1e-6));
  });

  test('protein is never part of the slice', () {
    final p = planBankedCheat(today: today, mealDay: DateTime(2026, 9, 28), extraKcal: 600, dailyTarget: target);
    for (final d in p.days) {
      expect(d.target.protein, target.protein);
    }
  });

  test('over 300 a day is steep', () {
    final p = planBankedCheat(today: today, mealDay: DateTime(2026, 9, 27), extraKcal: 500, dailyTarget: target);
    expect(p.steep, isTrue);
  });

  test('never below the floor', () {
    final p = planBankedCheat(today: today, mealDay: DateTime(2026, 9, 27), extraKcal: 1500, dailyTarget: target);
    expect(p.days.single.target.kcal, closeTo(defaultKcalFloor, 1e-6));
    expect(p.capped, isTrue);
    expect(p.banked, closeTo(target.kcal - defaultKcalFloor, 1e-6));
  });
}
