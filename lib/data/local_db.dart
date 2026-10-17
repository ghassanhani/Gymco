import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/session.dart';
import '../domain/workout.dart';
import 'models.dart';
import 'seed_foods.dart';
import 'training.dart';

/// The on-phone database. Everything the app shows is read from here; the
/// network only ever adds foods to it.
class LocalDb {
  LocalDb(this._db);

  final Database _db;

  /// 1: diet. 2: training.
  static const _version = 2;

  static Future<void> _createTraining(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE routines(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        created_at INTEGER NOT NULL)''');
    await db.execute('''
      CREATE TABLE routine_items(id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL REFERENCES routines(id) ON DELETE CASCADE, position INTEGER NOT NULL,
        exercise_id TEXT NOT NULL, sets INTEGER NOT NULL, rep_low INTEGER NOT NULL, rep_high INTEGER NOT NULL,
        rest_s INTEGER NOT NULL)''');
    await db.execute('''
      CREATE TABLE workouts(id INTEGER PRIMARY KEY AUTOINCREMENT, routine_id INTEGER, name TEXT NOT NULL,
        day TEXT NOT NULL, started_at INTEGER NOT NULL, ended_at INTEGER NOT NULL)''');
    await db.execute('CREATE INDEX workouts_day ON workouts(day)');
    await db.execute('''
      CREATE TABLE workout_sets(id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL REFERENCES workouts(id) ON DELETE CASCADE, ex_position INTEGER NOT NULL,
        exercise_id TEXT NOT NULL, exercise_name TEXT NOT NULL, set_index INTEGER NOT NULL, type TEXT NOT NULL,
        weight REAL NOT NULL, reps INTEGER NOT NULL)''');
    await db.execute('CREATE INDEX sets_exercise ON workout_sets(exercise_id)');
  }

  /// [singleInstance] false gives every open its own database (tests).
  static Future<LocalDb> open({DatabaseFactory? factory, String? path, bool singleInstance = true}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'gymco.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        singleInstance: singleInstance,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onUpgrade: (db, from, _) async {
          if (from < 2) await _createTraining(db);
        },
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE foods(
              id TEXT PRIMARY KEY, name TEXT NOT NULL, brand TEXT, barcode TEXT,
              kcal REAL NOT NULL, protein REAL NOT NULL, carbs REAL NOT NULL, fat REAL NOT NULL,
              serving_g REAL, source TEXT NOT NULL, last_used INTEGER)''');
          await db.execute('CREATE INDEX foods_barcode ON foods(barcode)');
          await db.execute('''
            CREATE TABLE log_entries(
              id INTEGER PRIMARY KEY AUTOINCREMENT, day TEXT NOT NULL, meal TEXT NOT NULL,
              food_id TEXT NOT NULL, food_name TEXT NOT NULL, grams REAL NOT NULL,
              kcal REAL NOT NULL, protein REAL NOT NULL, carbs REAL NOT NULL, fat REAL NOT NULL,
              created_at INTEGER NOT NULL)''');
          await db.execute('CREATE INDEX log_day ON log_entries(day)');
          await db.execute('''
            CREATE TABLE weigh_ins(day TEXT PRIMARY KEY, kg REAL NOT NULL)''');
          await _createTraining(db);
          final batch = db.batch();
          for (final f in seedFoods) {
            batch.insert('foods', f.toRow());
          }
          await batch.commit(noResult: true);
        },
      ),
    );
    return LocalDb(db);
  }

  Future<void> close() => _db.close();

  // ---- foods ----

  Future<List<Food>> searchFoods(String query, {int limit = 30}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return recentFoods(limit: limit);
    final words = q.split(RegExp(r'\s+'));
    final where = words.map((_) => "(lower(name) LIKE ? OR lower(ifnull(brand,'')) LIKE ?)").join(' AND ');
    final args = [
      for (final w in words) ...['%$w%', '%$w%'],
    ];
    final rows = await _db.query('foods', where: where, whereArgs: args, orderBy: 'last_used DESC, name', limit: limit);
    return rows.map(Food.fromRow).toList();
  }

  Future<List<Food>> recentFoods({int limit = 30}) async {
    final rows = await _db.query('foods', where: 'last_used IS NOT NULL', orderBy: 'last_used DESC', limit: limit);
    return rows.map(Food.fromRow).toList();
  }

  Future<Food?> foodByBarcode(String code) async {
    final rows = await _db.query('foods', where: 'barcode = ?', whereArgs: [code], limit: 1);
    return rows.isEmpty ? null : Food.fromRow(rows.first);
  }

  /// Save foods found online so the next search works offline.
  Future<void> upsertFoods(Iterable<Food> foods) async {
    final batch = _db.batch();
    for (final f in foods) {
      batch.insert('foods', f.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // ---- log ----

  Future<List<LogEntry>> entriesFor(String day) async {
    final rows = await _db.query('log_entries', where: 'day = ?', whereArgs: [day], orderBy: 'id');
    return rows.map(LogEntry.fromRow).toList();
  }

  Future<void> addEntry(LogEntry e) async {
    await _db.transaction((tx) async {
      await tx.insert('log_entries', {...e.toRow(), 'created_at': DateTime.now().millisecondsSinceEpoch});
      await tx.update(
        'foods',
        {'last_used': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [e.foodId],
      );
    });
  }

  Future<void> deleteEntry(int id) => _db.delete('log_entries', where: 'id = ?', whereArgs: [id]);

  /// Copy every entry of one meal from one day to another.
  Future<int> repeatMeal({required String from, required String to, required Meal meal}) async {
    final rows = await _db.query(
      'log_entries',
      where: 'day = ? AND meal = ?',
      whereArgs: [from, meal.name],
      orderBy: 'id',
    );
    for (final r in rows) {
      final e = LogEntry.fromRow(r);
      await addEntry(
        LogEntry(
          id: null,
          day: to,
          meal: meal,
          foodId: e.foodId,
          foodName: e.foodName,
          grams: e.grams,
          kcal: e.kcal,
          protein: e.protein,
          carbs: e.carbs,
          fat: e.fat,
        ),
      );
    }
    return rows.length;
  }

  // ---- weight ----

  Future<void> setWeight(String day, double kg) =>
      _db.insert('weigh_ins', {'day': day, 'kg': kg}, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<(String, double)>> weighIns() async {
    final rows = await _db.query('weigh_ins', orderBy: 'day');
    return [for (final r in rows) (r['day']! as String, (r['kg']! as num).toDouble())];
  }

  // ---- routines ----

  Future<List<Routine>> routines() async {
    final rs = await _db.query('routines', orderBy: 'created_at');
    final items = await _db.query('routine_items', orderBy: 'routine_id, position');
    return [
      for (final r in rs)
        Routine(
          id: r['id']! as int,
          name: r['name']! as String,
          items: [
            for (final i in items.where((i) => i['routine_id'] == r['id']))
              RoutineItem(
                exerciseId: i['exercise_id']! as String,
                sets: i['sets']! as int,
                repLow: i['rep_low']! as int,
                repHigh: i['rep_high']! as int,
                restSeconds: i['rest_s']! as int,
              ),
          ],
        ),
    ];
  }

  /// Insert or replace a routine; returns its id. Throws [DuplicateNameException]
  /// when another routine already uses the name.
  Future<int> saveRoutine(Routine r) async {
    try {
      return await _db.transaction((tx) async {
        int id;
        if (r.id == null) {
          id = await tx.insert('routines', {
            'name': r.name.trim(),
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        } else {
          id = r.id!;
          await tx.update('routines', {'name': r.name.trim()}, where: 'id = ?', whereArgs: [id]);
          await tx.delete('routine_items', where: 'routine_id = ?', whereArgs: [id]);
        }
        for (var i = 0; i < r.items.length; i++) {
          final it = r.items[i];
          await tx.insert('routine_items', {
            'routine_id': id,
            'position': i,
            'exercise_id': it.exerciseId,
            'sets': it.sets,
            'rep_low': it.repLow,
            'rep_high': it.repHigh,
            'rest_s': it.restSeconds,
          });
        }
        return id;
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateNameException(r.name);
      rethrow;
    }
  }

  Future<void> deleteRoutine(int id) => _db.delete('routines', where: 'id = ?', whereArgs: [id]);

  // ---- workouts ----

  /// Store the ticked sets of a finished session. Unticked sets are dropped.
  Future<int> saveWorkout(WorkoutSession s, DateTime endedAt) => _db.transaction((tx) async {
    final id = await tx.insert('workouts', {
      'routine_id': s.routineId,
      'name': s.name,
      'day': dayKey(s.startedAt),
      'started_at': s.startedAt.millisecondsSinceEpoch,
      'ended_at': endedAt.millisecondsSinceEpoch,
    });
    for (var e = 0; e < s.exercises.length; e++) {
      final ex = s.exercises[e];
      final done = ex.sets.where((x) => x.done).toList();
      for (var i = 0; i < done.length; i++) {
        await tx.insert('workout_sets', {
          'workout_id': id,
          'ex_position': e,
          'exercise_id': ex.exerciseId,
          'exercise_name': ex.name,
          'set_index': i,
          'type': done[i].type.name,
          'weight': done[i].weightKg ?? 0,
          'reps': done[i].reps ?? 0,
        });
      }
    }
    return id;
  });

  Future<List<WorkoutRecord>> recentWorkouts({int limit = 20}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT w.id, w.name, w.started_at, w.ended_at, COUNT(s.id) AS sets,
        COALESCE(SUM(CASE WHEN s.type != 'warmup' THEN s.weight * s.reps ELSE 0 END), 0) AS volume
      FROM workouts w LEFT JOIN workout_sets s ON s.workout_id = w.id
      GROUP BY w.id ORDER BY w.started_at DESC LIMIT ?''',
      [limit],
    );
    return [
      for (final r in rows)
        WorkoutRecord(
          id: r['id']! as int,
          name: r['name']! as String,
          startedAt: DateTime.fromMillisecondsSinceEpoch(r['started_at']! as int),
          endedAt: DateTime.fromMillisecondsSinceEpoch(r['ended_at']! as int),
          volume: (r['volume']! as num).toDouble(),
          sets: r['sets']! as int,
        ),
    ];
  }

  /// The sets from the last time this exercise was done, for the "previous" column.
  Future<List<SessionSet>> lastSetsFor(String exerciseId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT s.* FROM workout_sets s JOIN workouts w ON w.id = s.workout_id
      WHERE s.exercise_id = ? AND w.id = (
        SELECT w2.id FROM workouts w2 JOIN workout_sets s2 ON s2.workout_id = w2.id
        WHERE s2.exercise_id = ? ORDER BY w2.started_at DESC LIMIT 1)
      ORDER BY s.set_index''',
      [exerciseId, exerciseId],
    );
    return [
      for (final r in rows)
        SessionSet(
          weightKg: (r['weight']! as num).toDouble(),
          reps: r['reps']! as int,
          type: SetType.values.byName(r['type']! as String),
        ),
    ];
  }

  /// Best estimated 1RM per exercise across all history (warm-ups excluded).
  Future<Map<String, double>> bestOneRepMaxes(Iterable<String> exerciseIds) async {
    final ids = exerciseIds.toSet().toList();
    if (ids.isEmpty) return {};
    final rows = await _db.query(
      'workout_sets',
      where: "type != 'warmup' AND exercise_id IN (${List.filled(ids.length, '?').join(',')})",
      whereArgs: ids,
    );
    final out = <String, double>{};
    for (final r in rows) {
      final rm = estimatedOneRepMax((r['weight']! as num).toDouble(), r['reps']! as int);
      final id = r['exercise_id']! as String;
      if (rm != null && rm > (out[id] ?? 0)) out[id] = rm;
    }
    return out;
  }

  /// Days with a finished workout, for the streak.
  Future<Set<String>> trainedDays() async {
    final rows = await _db.rawQuery('SELECT DISTINCT day FROM workouts');
    return {for (final r in rows) r['day']! as String};
  }
}

class DuplicateNameException implements Exception {
  DuplicateNameException(this.name);
  final String name;
}
