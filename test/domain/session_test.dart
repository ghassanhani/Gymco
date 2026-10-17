import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/session.dart';
import 'package:gymco/domain/workout.dart';

void main() {
  final t0 = DateTime(2026, 9, 26, 18);
  WorkoutSession bench() => WorkoutSession.start(
    name: 'Push A',
    now: t0,
    exercises: [
      const SessionExercise(
        exerciseId: 'bench',
        name: 'Bench',
        restSeconds: 120,
        sets: [
          SessionSet(weightKg: 60, reps: 10, type: SetType.warmup),
          SessionSet(weightKg: 100, reps: 5),
        ],
      ),
    ],
  );

  test('a new set copies the last numbers', () {
    final s = bench().addSet(0);
    expect(s.exercises[0].sets.last.weightKg, 100);
    expect(s.exercises[0].sets.last.reps, 5);
    expect(s.setsPlanned, 3);
  });

  test('ticking starts rest, warm-ups rest shorter, unticking stops it', () {
    var s = bench().toggleDone(0, 1, t0);
    expect(s.restLeft(t0.add(const Duration(seconds: 20))), 100);
    expect(s.restLeft(t0.add(const Duration(seconds: 121))), isNull);
    s = s.toggleDone(0, 1, t0);
    expect(s.restLeft(t0), isNull);
    s = s.toggleDone(0, 0, t0);
    expect(s.restSeconds, 45);
  });

  test('an incomplete set cannot be ticked', () {
    final s = bench().addSet(0).updateSet(0, 2, (x) => x.copyWith(reps: () => null));
    expect(s.toggleDone(0, 2, t0).setsDone, 0);
  });

  test('rest can be stretched and skipped', () {
    final s = bench().toggleDone(0, 1, t0).adjustRest(15);
    expect(s.restLeft(t0), 135);
    expect(s.skipRest().restLeft(t0), isNull);
  });

  test('stats move with every tick and skip warm-ups', () {
    final s = bench().toggleDone(0, 0, t0).toggleDone(0, 1, t0);
    expect(s.setsDone, 2);
    expect(s.volume, 500);
    expect(s.hasUnfinishedSets, isFalse);
  });

  test('survives a round trip through JSON, timer included', () {
    final s = bench().toggleDone(0, 1, t0);
    final back = WorkoutSession.fromJson(s.toJson());
    expect(back.volume, s.volume);
    expect(back.restLeft(t0.add(const Duration(seconds: 30))), 90);
    expect(back.exercises.single.restSeconds, 120);
  });

  test('new bests beat the previous estimated 1RM only', () {
    final s = bench().toggleDone(0, 1, t0);
    expect(newBests(s, {'bench': 110}).keys, ['bench']);
    expect(newBests(s, {'bench': 120}), isEmpty);
    // A first-ever lift has nothing to beat, so it is not called a record.
    expect(newBests(s, {}), isEmpty);
  });

  test('a rest of 0 turns the timer off for that exercise', () {
    final s = bench().setRest(0, 0).toggleDone(0, 1, t0);
    expect(s.restLeft(t0), isNull);
    expect(s.setsDone, 1);
  });

  test('notes and the next set survive', () {
    final s = bench().setNote(0, 'Seat 4').toggleDone(0, 0, t0);
    expect(WorkoutSession.fromJson(s.toJson()).exercises.single.note, 'Seat 4');
    expect(s.nextSet, (0, 1));
    expect(s.hardSetsDone, 0);
  });

  test('a typed weight fills the empty sets after it, not warm-ups or ticked ones', () {
    final s = WorkoutSession.start(
      name: 'x',
      now: t0,
      exercises: const [
        SessionExercise(
          exerciseId: 'bench',
          name: 'Bench',
          sets: [
            SessionSet(),
            SessionSet(),
            SessionSet(type: SetType.warmup),
            SessionSet(weightKg: 90),
          ],
        ),
      ],
    ).editSet(0, 0, weightKg: 100, reps: 5);
    expect(s.exercises.single.sets.map((x) => x.weightKg), [100, 100, null, 90]);
    expect(s.exercises.single.sets.first.reps, 5);
  });

  test('ticking a set with a weight but no reps takes last time\'s reps', () {
    final s = WorkoutSession.start(
      name: 'x',
      now: t0,
      exercises: const [
        SessionExercise(
          exerciseId: 'bench',
          name: 'Bench',
          repLow: 6,
          previous: [SessionSet(weightKg: 100, reps: 8, rir: 2)],
          sets: [SessionSet(weightKg: 100), SessionSet(weightKg: 100)],
        ),
      ],
    ).toggleDone(0, 0, t0).toggleDone(0, 1, t0);
    expect(s.exercises.single.sets.map((x) => x.reps), [8, 6]);
    expect(s.setsDone, 2);
  });

  test('a superset rests only after its second half', () {
    SessionExercise ex(String id) =>
        SessionExercise(exerciseId: id, name: id, restSeconds: 120, sets: const [SessionSet(weightKg: 20, reps: 10)]);
    var s = WorkoutSession.start(name: 'x', now: t0, exercises: [ex('a'), ex('b')]).link(0, true);
    s = s.toggleDone(0, 0, t0);
    expect(s.restLeft(t0), isNull);
    s = s.toggleDone(1, 0, t0);
    expect(s.restLeft(t0), 120);
    expect(WorkoutSession.fromJson(s.toJson()).exercises.first.linkNext, isTrue);
    // Removing either half drops the link.
    expect(s.removeExercise(1).exercises.single.linkNext, isFalse);
  });
}
