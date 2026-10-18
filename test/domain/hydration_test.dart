import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/hydration.dart';

void main() {
  test('the goal follows body weight and adds half a litre for training', () {
    expect(waterGoalMl(weightKg: 80, trained: false), 2800);
    expect(waterGoalMl(weightKg: 80, trained: true), 3300);
    expect(waterGoalMl(weightKg: 30, trained: false), 1500);
    expect(waterGoalMl(weightKg: 160, trained: true), 5000);
  });

  test('a day round-trips, and an old total reads as one drink', () {
    const d = WaterDay([(minute: 480, ml: 250), (minute: 735, ml: 500)]);
    final back = WaterDay.decode(d.encode());
    expect(back.sips, d.sips);
    expect(back.ml, 750);
    expect(WaterDay.decode(null, legacyMl: 1000).ml, 1000);
    expect(WaterDay.decode('bad,480:250').ml, 250);
  });
}
