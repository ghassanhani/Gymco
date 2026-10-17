import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/volume.dart';

void main() {
  test('sets add on top of the rest of the week, grouped and ranked', () {
    final v = weeklyVolume(
      [('chest', 8), ('shoulders', 4), ('triceps', 8)],
      [('chest', 6), ('lats', 14), ('shoulders', 4)],
    );
    expect(v.map((g) => g.group), [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps]);
    expect(v.first.total, 14);
    expect(v.first.state, VolumeState.inRange);
    expect(v[1].state, VolumeState.under);
  });

  test('over twenty is over range', () {
    expect(weeklyVolume([('quadriceps', 12)], [('hamstrings', 10)]).single.state, VolumeState.over);
  });

  test('duration matches the prototype for Push A: 68 min', () {
    expect(planMinutes([(4, 180), (4, 150), (4, 150), (4, 60), (4, 150), (4, 90)]), 68);
  });
}
