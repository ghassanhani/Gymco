import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/training.dart';
import 'package:gymco/domain/session.dart';
import 'package:gymco/domain/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers.dart';

void main() {
  final t0 = DateTime(2026, 9, 26, 18);

  WorkoutSession session({double weight = 100, int reps = 5}) => WorkoutSession.start(
    name: 'Push A',
    now: t0,
    exercises: [
      SessionExercise(
        exerciseId: 'bench',
        name: 'Bench',
        sets: [
          const SessionSet(weightKg: 60, reps: 10, type: SetType.warmup, done: true),
          SessionSet(weightKg: weight, reps: reps, done: true),
          SessionSet(weightKg: weight, reps: reps),
        ],
      ),
    ],
  );

  test('routines save, reload in order, and refuse a duplicate name', () async {
    final db = await openTestDb();
    final id = await db.saveRoutine(
      const Routine(
        id: null,
        name: 'Push A',
        items: [
          RoutineItem(exerciseId: 'bench', sets: 4, repLow: 5, repHigh: 8),
          RoutineItem(exerciseId: 'ohp'),
        ],
      ),
    );
    final r = (await db.routines()).single;
    expect(r.id, id);
    expect(r.items.map((i) => i.exerciseId), ['bench', 'ohp']);
    expect(r.totalSets, 7);
    expect(
      () => db.saveRoutine(
        const Routine(
          id: null,
          name: 'push a',
          items: [RoutineItem(exerciseId: 'x')],
        ),
      ),
      throwsA(isA<DuplicateNameException>()),
    );
    await db.deleteRoutine(id);
    expect(await db.routines(), isEmpty);
  });

  test('a finished workout keeps only ticked sets and feeds history', () async {
    final db = await openTestDb();
    await db.saveWorkout(session(), t0.add(const Duration(minutes: 50)));
    final w = (await db.recentWorkouts()).single;
    expect(w.sets, 2);
    expect(w.volume, 500);
    expect(w.duration.inMinutes, 50);
    expect(await db.trainedDays(), {'2026-09-26'});
  });

  test('previous sets and best 1RM come from the latest history', () async {
    final db = await openTestDb();
    await db.saveWorkout(session(weight: 100), t0);
    await db.saveWorkout(
      WorkoutSession.start(
        name: 'Push A',
        now: t0.add(const Duration(days: 3)),
        exercises: [
          const SessionExercise(
            exerciseId: 'bench',
            name: 'Bench',
            sets: [SessionSet(weightKg: 102.5, reps: 5, done: true)],
          ),
        ],
      ),
      t0.add(const Duration(days: 3)),
    );
    final prev = await db.lastSetsFor('bench');
    expect(prev.single.weightKg, 102.5);
    final best = await db.bestOneRepMaxes(['bench']);
    expect(best['bench'], closeTo(102.5 * (1 + 5 / 30), 1e-9));
  });

  test('a phase-1 database upgrades without losing the food log or foods', () async {
    final dir = await Directory.systemTemp.createTemp('gymco');
    final path = '${dir.path}/gymco.db';
    final old = await databaseFactoryFfiNoIsolate.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE log_entries(id INTEGER PRIMARY KEY, day TEXT)');
          await db.execute('CREATE TABLE foods(id TEXT PRIMARY KEY, name TEXT, source TEXT, last_used INTEGER)');
          await db.insert('log_entries', {'day': '2026-09-01'});
          await db.insert('foods', {'id': 'usda:oats', 'name': 'Oats', 'source': 'usda'});
        },
      ),
    );
    await old.close();

    final db = await LocalDb.open(factory: databaseFactoryFfiNoIsolate, path: path, singleInstance: false);
    expect(await db.routines(), isEmpty);
    expect(await db.savedMeals(), isEmpty);
    await db.close();
    final check = await databaseFactoryFfiNoIsolate.openDatabase(path);
    expect(await check.query('log_entries'), hasLength(1));
    expect((await check.query('foods')).single['favourite'], 0);
    await check.close();
    await dir.delete(recursive: true);
  });

  test('the bundled library loads and searches strength work first', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final lib = await ExerciseLibrary.load();
    expect(lib.all.length, 876);
    expect(lib['Barbell_Bench_Press_-_Medium_Grip']?.badge, 'BB');
    final hits = lib.search('bench press', muscle: 'chest');
    expect(hits.first.category, 'strength');
    expect(hits.every((e) => e.primary.contains('chest')), isTrue);
  });

  test('one routine per weekday: saving onto a taken day moves the other to any day', () async {
    final db = await openTestDb();
    await db.saveRoutine(
      const Routine(
        id: null,
        name: 'Push A',
        weekday: 5,
        folder: RoutineFolder.plan,
        items: [RoutineItem(exerciseId: 'bench', rir: 1)],
      ),
    );
    await db.saveRoutine(
      const Routine(
        id: null,
        name: 'Legs',
        weekday: 5,
        items: [RoutineItem(exerciseId: 'squat')],
      ),
    );
    final all = {for (final r in await db.routines()) r.name: r};
    expect(all['Legs']!.weekday, 5);
    expect(all['Push A']!.weekday, isNull);
    expect(all['Push A']!.folder, RoutineFolder.plan);
    expect(all['Push A']!.items.single.rir, 1);
  });

  test('history groups an exercise by workout, newest first, with RIR', () async {
    final db = await openTestDb();
    await db.saveWorkout(session(weight: 100), t0);
    await db.saveWorkout(
      WorkoutSession.start(
        name: 'Push A',
        now: t0.add(const Duration(days: 3)),
        exercises: const [
          SessionExercise(
            exerciseId: 'bench',
            name: 'Bench',
            sets: [SessionSet(weightKg: 105, reps: 5, rir: 1, done: true)],
          ),
        ],
      ),
      t0.add(const Duration(days: 3)),
    );
    final h = await db.historyOf('bench');
    expect(h, hasLength(2));
    expect(h.first.$2.single.rir, 1);
    expect(h.last.$2, hasLength(2));
    final week = await db.workoutsBetween(t0, t0.add(const Duration(days: 7)));
    expect(week, hasLength(2));
    expect(week.last.hardSets, 1);
  });
}
