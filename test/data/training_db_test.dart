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

  test('a phase-1 database upgrades without losing the food log', () async {
    final dir = await Directory.systemTemp.createTemp('gymco');
    final path = '${dir.path}/gymco.db';
    final old = await databaseFactoryFfiNoIsolate.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE log_entries(id INTEGER PRIMARY KEY, day TEXT)');
          await db.insert('log_entries', {'day': '2026-09-01'});
        },
      ),
    );
    await old.close();

    final db = await LocalDb.open(factory: databaseFactoryFfiNoIsolate, path: path, singleInstance: false);
    expect(await db.routines(), isEmpty);
    await db.close();
    final check = await databaseFactoryFfiNoIsolate.openDatabase(path);
    expect(await check.query('log_entries'), hasLength(1));
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
}
