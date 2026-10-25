import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/training.dart';
import 'package:gymco/domain/routine_ai.dart';

import '../helpers.dart';

void main() {
  test('names are matched exactly, then by search; unknown ones are listed', () {
    final plan = planFrom({
      'summary': 'Two days.',
      'routines': [
        {
          'name': 'Upper',
          'days': [0, 3],
          'items': [
            {'exercise': 'barbell bench press', 'sets': 4, 'rep_low': 6, 'rep_high': 8, 'rest_seconds': 150},
            {'exercise': 'Lateral Raise', 'sets': 3, 'rep_low': 12, 'rep_high': 15, 'rest_seconds': 60},
            {'exercise': 'Cable Unicorn Fly', 'sets': 3, 'rep_low': 10, 'rep_high': 12, 'rest_seconds': 60},
          ],
        },
      ],
    }, testLibrary);
    final r = plan.routines.single;
    expect(r.items.map((i) => i.exerciseId), ['bench', 'lat']);
    expect(r.days, {0, 3});
    expect(r.folder, RoutineFolder.plan);
    expect(plan.missing, ['Cable Unicorn Fly']);
    expect(plan.summary, 'Two days.');
  });

  test('numbers out of range are pulled back, and an empty routine is dropped', () {
    final plan = planFrom({
      'routines': [
        {
          'name': 'Legs',
          'days': [9, 4],
          'items': [
            {'exercise': 'Barbell Squat', 'sets': 40, 'rep_low': 10, 'rep_high': 5, 'rest_seconds': 5},
          ],
        },
        {'name': 'Nothing', 'days': <int>[], 'items': <Object>[]},
      ],
    }, testLibrary);
    final it = plan.routines.single.items.single;
    expect((it.sets, it.repLow, it.repHigh, it.restSeconds), (10, 10, 10, 30));
    expect(plan.routines.single.days, {4});
  });

  test('a routine with no day is kept for any time', () {
    final plan = planFrom({
      'routines': [
        {
          'name': 'Quick',
          'days': <int>[],
          'items': [
            {'exercise': 'Standing Military Press', 'sets': 3, 'rep_low': 8, 'rep_high': 10, 'rest_seconds': 90},
          ],
        },
      ],
    }, testLibrary);
    expect(plan.routines.single.folder, RoutineFolder.mine);
  });
}
