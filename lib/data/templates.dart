import 'training.dart';

/// Starter blocks, with the weekly set volume already inside the 10–20
/// range for the muscles each one trains. Every exercise is in the bundled
/// library.
enum TemplateKind { upperLower, pushPullLegs, fullBody }

/// One routine of a template: its role (for the localised name), the
/// weekday it lands on, and the plan.
class TemplateRoutine {
  const TemplateRoutine(this.role, this.weekday, this.items);
  final String role;
  final int weekday;
  final List<RoutineItem> items;
}

RoutineItem _i(String id, int sets, int lo, int hi, int rest, [int rir = 2]) =>
    RoutineItem(exerciseId: id, sets: sets, repLow: lo, repHigh: hi, restSeconds: rest, rir: rir);

const _bench = 'Barbell_Bench_Press_-_Medium_Grip';
const _incline = 'Incline_Dumbbell_Press';
const _ohp = 'Standing_Military_Press';
const _lateral = 'Side_Lateral_Raise';
const _pushdown = 'Triceps_Pushdown';
const _pullups = 'Weighted_Pull_Ups';
const _row = 'Bent_Over_Barbell_Row';
const _cableRow = 'Seated_Cable_Rows';
const _pulldown = 'Wide-Grip_Lat_Pulldown';
const _facePull = 'Face_Pull';
const _curl = 'Incline_Dumbbell_Curl';
const _hammer = 'Hammer_Curls';
const _squat = 'Barbell_Squat';
const _rdl = 'Romanian_Deadlift';
const _legPress = 'Leg_Press';
const _legCurl = 'Seated_Leg_Curl';
const _legExt = 'Leg_Extensions';
const _calf = 'Standing_Calf_Raises';
const _hipThrust = 'Barbell_Hip_Thrust';
const _dbBench = 'Dumbbell_Bench_Press';
const _dbPress = 'Dumbbell_Shoulder_Press';

List<TemplateRoutine> templateRoutines(TemplateKind k) => switch (k) {
  // Monday, Tuesday, Thursday, Friday.
  TemplateKind.upperLower => [
    TemplateRoutine('upperA', 0, [
      _i(_bench, 4, 5, 8, 180),
      _i(_row, 4, 6, 10, 150),
      _i(_ohp, 3, 6, 8, 150),
      _i(_pulldown, 3, 10, 12, 120),
      _i(_lateral, 3, 12, 15, 60, 1),
      _i(_pushdown, 3, 10, 12, 90, 1),
    ]),
    TemplateRoutine('lowerA', 1, [
      _i(_squat, 4, 5, 8, 210),
      _i(_rdl, 4, 6, 10, 180),
      _i(_legPress, 3, 8, 12, 150),
      _i(_legCurl, 3, 10, 12, 90, 1),
      _i(_calf, 4, 12, 15, 60, 1),
    ]),
    TemplateRoutine('upperB', 3, [
      _i(_incline, 4, 8, 10, 150),
      _i(_pullups, 4, 5, 8, 180),
      _i(_dbPress, 3, 8, 12, 120),
      _i(_cableRow, 3, 10, 12, 120),
      _i(_lateral, 3, 12, 15, 60, 1),
      _i(_curl, 3, 10, 12, 90, 1),
    ]),
    TemplateRoutine('lowerB', 4, [
      _i(_hipThrust, 4, 8, 10, 150),
      _i(_legPress, 4, 10, 12, 150),
      _i(_legCurl, 4, 10, 12, 90, 1),
      _i(_legExt, 3, 12, 15, 75, 1),
      _i(_calf, 4, 12, 15, 60, 1),
    ]),
  ],
  // Monday to Saturday.
  TemplateKind.pushPullLegs => [
    for (final (week, offset) in [('A', 0), ('B', 3)]) ...[
      TemplateRoutine('push$week', offset, [
        _i(week == 'A' ? _bench : _ohp, 4, 5, 8, 180),
        _i(week == 'A' ? _incline : _dbBench, 3, 8, 10, 150),
        _i(week == 'A' ? _ohp : _incline, 3, 6, 10, 150),
        _i(_lateral, 4, 12, 15, 60, 1),
        _i(_pushdown, 3, 10, 12, 90, 1),
      ]),
      TemplateRoutine('pull$week', offset + 1, [
        _i(week == 'A' ? _pullups : _row, 4, 5, 8, 180),
        _i(week == 'A' ? _cableRow : _pulldown, 3, 8, 12, 150),
        _i(_facePull, 3, 12, 15, 60, 1),
        _i(week == 'A' ? _curl : _hammer, 3, 10, 12, 90, 1),
      ]),
      TemplateRoutine('legs$week', offset + 2, [
        _i(week == 'A' ? _squat : _hipThrust, 4, 5, 8, 210),
        _i(_rdl, 3, 6, 10, 180),
        _i(_legPress, 3, 10, 12, 150),
        _i(_legCurl, 3, 10, 12, 90, 1),
        _i(_calf, 3, 12, 15, 60, 1),
      ]),
    ],
  ],
  // Monday, Wednesday, Friday.
  TemplateKind.fullBody => [
    for (final (role, day, press, pull, legs) in [
      ('fullA', 0, _bench, _row, _squat),
      ('fullB', 2, _ohp, _pullups, _rdl),
      ('fullC', 4, _incline, _cableRow, _legPress),
    ])
      TemplateRoutine(role, day, [
        _i(legs, 3, 6, 10, 180),
        _i(press, 3, 6, 10, 150),
        _i(pull, 3, 8, 10, 150),
        _i(_lateral, 2, 12, 15, 60, 1),
        _i(_curl, 2, 10, 12, 75, 1),
        _i(_pushdown, 2, 10, 12, 75, 1),
      ]),
  ],
};
