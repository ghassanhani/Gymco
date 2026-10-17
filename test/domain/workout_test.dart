import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/workout.dart';

void main() {
  test('warm-ups add no volume and no hard sets', () {
    const sets = [
      LoggedSet(weightKg: 60, reps: 10, type: SetType.warmup),
      LoggedSet(weightKg: 100, reps: 5),
      LoggedSet(weightKg: 100, reps: 4, type: SetType.failure),
      LoggedSet(weightKg: 80, reps: 8, type: SetType.drop),
      LoggedSet(weightKg: 100, reps: 5, done: false),
    ];
    expect(totalVolume(sets), 500 + 400 + 640);
    expect(hardSets(sets), 2.5);
  });

  test('Epley 1RM', () {
    expect(estimatedOneRepMax(100, 1), 100);
    expect(estimatedOneRepMax(100, 5), closeTo(116.67, 0.01));
    expect(estimatedOneRepMax(100, 20), isNull);
  });

  test('deload rounds to the plate step', () {
    expect(deloadWeight(100), 60);
    expect(deloadWeight(87.5), 52.5);
  });
}
