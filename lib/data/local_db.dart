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

  /// 1: diet. 2: training. 3: weekdays, folders, RIR. 4: favourites, saved meals.
  /// 5: body measurements.
  static const _version = 7;

  /// What a backup was written by, so a newer phone can read an older one.
  static const schemaVersion = _version;

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

  static Future<void> _addPlanColumns(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE routines ADD COLUMN weekday INTEGER');
    await db.execute("ALTER TABLE routines ADD COLUMN folder TEXT NOT NULL DEFAULT 'mine'");
    await db.execute('ALTER TABLE routine_items ADD COLUMN rir INTEGER NOT NULL DEFAULT 2');
    await db.execute('ALTER TABLE workout_sets ADD COLUMN rir INTEGER');
  }

  static Future<void> _addSavedMeals(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE foods ADD COLUMN favourite INTEGER NOT NULL DEFAULT 0');
    await db.execute(
      '''
      CREATE TABLE saved_meals(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created_at INTEGER NOT NULL)''',
    );
    await db.execute('''
      CREATE TABLE saved_meal_items(id INTEGER PRIMARY KEY AUTOINCREMENT,
        saved_meal_id INTEGER NOT NULL REFERENCES saved_meals(id) ON DELETE CASCADE, position INTEGER NOT NULL,
        food_id TEXT NOT NULL, grams REAL NOT NULL)''');
  }

  static Future<void> _addRecipes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE recipes(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, servings INTEGER NOT NULL,
        created_at INTEGER NOT NULL)''');
    await db.execute('''
      CREATE TABLE recipe_items(id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE, position INTEGER NOT NULL,
        food_id TEXT NOT NULL, grams REAL NOT NULL)''');
  }

  static Future<void> _addMeasurements(DatabaseExecutor db) => db.execute('''
    CREATE TABLE measurements(day TEXT NOT NULL, kind TEXT NOT NULL, value REAL NOT NULL, PRIMARY KEY(day, kind))''');

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
          if (from < 3) await _addPlanColumns(db);
          if (from < 4) await _addSavedMeals(db);
          if (from < 5) await _addMeasurements(db);
          if (from < 7) await _addRecipes(db);
          // Staples added since: insert the ones this phone does not have.
          final batch = db.batch();
          for (final f in seedFoods) {
            batch.insert('foods', f.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
          }
          await batch.commit(noResult: true);
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
          await _addPlanColumns(db);
          await _addSavedMeals(db);
          await _addMeasurements(db);
          await _addRecipes(db);
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

  // ---- your data ----

  static const _userTables = [
    'log_entries',
    'weigh_ins',
    'routines',
    'routine_items',
    'workouts',
    'workout_sets',
    'saved_meals',
    'saved_meal_items',
    'measurements',
    'recipes',
    'recipe_items',
  ];

  Future<({int entries, int sets, int weighIns})> counts() async {
    Future<int> n(String t) async => Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM $t')) ?? 0;
    return (entries: await n('log_entries'), sets: await n('workout_sets'), weighIns: await n('weigh_ins'));
  }

  /// Every table the user wrote to, plus the foods they made, as rows.
  Future<Map<String, List<Map<String, Object?>>>> exportAll() async => {
    for (final t in _userTables) t: await _db.query(t),
    'custom_foods': await _db.query('foods', where: "source = 'local'"),
  };

  /// Replaces everything the user made with [all], as [exportAll] wrote it.
  /// Columns this version does not know are dropped; the bundled foods stay.
  Future<void> importAll(Map<String, Object?> all) => _db.transaction((tx) async {
    for (final t in _userTables.reversed) {
      await tx.delete(t);
    }
    await tx.delete('foods', where: "source = 'local'");
    Future<void> put(String table, String from, {ConflictAlgorithm? conflict}) async {
      final known = {for (final c in await tx.rawQuery('PRAGMA table_info($table)')) c['name'] as String};
      for (final r in (all[from] as List? ?? const [])) {
        final row = {
          for (final MapEntry(:key, :value) in (r as Map).cast<String, Object?>().entries)
            if (known.contains(key)) key: value,
        };
        if (row.isNotEmpty) await tx.insert(table, row, conflictAlgorithm: conflict);
      }
    }

    await put('foods', 'custom_foods', conflict: ConflictAlgorithm.replace);
    for (final t in _userTables) {
      await put(t, t);
    }
  });

  /// Everything the user made goes; the bundled foods stay, untouched.
  Future<void> wipe() => _db.transaction((tx) async {
    for (final t in _userTables.reversed) {
      await tx.delete(t);
    }
    await tx.delete('foods', where: "source = 'local'");
    await tx.update('foods', {'last_used': null, 'favourite': 0});
  });

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
    final rows = await _db.query(
      'foods',
      where: 'last_used IS NOT NULL OR favourite = 1',
      orderBy: 'favourite DESC, last_used DESC',
      limit: limit,
    );
    return rows.map(Food.fromRow).toList();
  }

  Future<List<Food>> customFoods() async {
    final rows = await _db.query('foods', where: "source = 'local'", orderBy: 'name');
    return rows.map(Food.fromRow).toList();
  }

  Future<List<String>> favouriteIds() async => [
    for (final r in await _db.query('foods', columns: ['id'], where: 'favourite = 1')) r['id']! as String,
  ];

  Future<void> setFavourite(String id, bool on) =>
      _db.update('foods', {'favourite': on ? 1 : 0}, where: 'id = ?', whereArgs: [id]);

  /// A copy of [f] the user owns, so a pack that changes its label never
  /// changes what they log.
  Future<Food> saveAsCustom(Food f) async {
    final copy = Food(
      id: 'local:${DateTime.now().microsecondsSinceEpoch}',
      name: f.name,
      brand: f.brand,
      kcal: f.kcal,
      protein: f.protein,
      carbs: f.carbs,
      fat: f.fat,
      servingGrams: f.servingGrams,
    );
    await _db.insert('foods', copy.toRow());
    return copy;
  }

  // ---- saved meals ----

  Future<int> saveMeal(String name, List<LogEntry> entries) => _db.transaction((tx) async {
    final id = await tx.insert('saved_meals', {'name': name, 'created_at': DateTime.now().millisecondsSinceEpoch});
    for (var i = 0; i < entries.length; i++) {
      await tx.insert('saved_meal_items', {
        'saved_meal_id': id,
        'position': i,
        'food_id': entries[i].foodId,
        'grams': entries[i].grams,
      });
    }
    return id;
  });

  Future<List<SavedMeal>> savedMeals() async {
    final meals = await _db.query('saved_meals', orderBy: 'created_at DESC');
    final out = <SavedMeal>[];
    for (final m in meals) {
      final rows = await _db.rawQuery(
        'SELECT f.*, i.grams AS item_g FROM saved_meal_items i JOIN foods f ON f.id = i.food_id '
        'WHERE i.saved_meal_id = ? ORDER BY i.position',
        [m['id']],
      );
      out.add(
        SavedMeal(
          id: m['id']! as int,
          name: m['name']! as String,
          items: [for (final r in rows) (Food.fromRow(r), (r['item_g']! as num).toDouble())],
        ),
      );
    }
    return out;
  }

  Future<void> deleteSavedMeal(int id) => _db.delete('saved_meals', where: 'id = ?', whereArgs: [id]);

  // ---- recipes ----

  /// Saves a new recipe, or replaces [id]'s, and keeps its food in step.
  Future<int> saveRecipe(String name, int servings, List<(Food, double)> items, {int? id}) =>
      _db.transaction((tx) async {
        final row = {'name': name, 'servings': servings, 'created_at': DateTime.now().millisecondsSinceEpoch};
        final rid = id ?? await tx.insert('recipes', row);
        if (id != null) {
          await tx.update('recipes', {'name': name, 'servings': servings}, where: 'id = ?', whereArgs: [id]);
          await tx.delete('recipe_items', where: 'recipe_id = ?', whereArgs: [id]);
        }
        for (final (i, (f, g)) in items.indexed) {
          await tx.insert('foods', f.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
          await tx.insert('recipe_items', {'recipe_id': rid, 'position': i, 'food_id': f.id, 'grams': g});
        }
        final r = Recipe(id: rid, name: name, servings: servings, items: items);
        await tx.insert('foods', r.asFood().toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
        return rid;
      });

  Future<List<Recipe>> recipes() async {
    final out = <Recipe>[];
    for (final m in await _db.query('recipes', orderBy: 'created_at DESC')) {
      final rows = await _db.rawQuery(
        'SELECT f.*, i.grams AS item_g FROM recipe_items i JOIN foods f ON f.id = i.food_id '
        'WHERE i.recipe_id = ? ORDER BY i.position',
        [m['id']],
      );
      final r = Recipe(
        id: m['id']! as int,
        name: m['name']! as String,
        servings: m['servings']! as int,
        items: [for (final x in rows) (Food.fromRow(x), (x['item_g']! as num).toDouble())],
      );
      // A restored backup brings the recipe back; this brings back its food.
      await _db.insert('foods', r.asFood().toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
      out.add(r);
    }
    return out;
  }

  Future<void> deleteRecipe(int id) async {
    await _db.delete('recipes', where: 'id = ?', whereArgs: [id]);
    await _db.delete('foods', where: 'id = ?', whereArgs: [Recipe.foodId(id)]);
  }

  /// The generic foods shipped with the app, for a first search with no history.
  Future<List<Food>> staples({int limit = 8}) async {
    final rows = await _db.query('foods', where: "source = 'usda'", orderBy: 'rowid', limit: limit);
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

  /// Days in [from, to] that have anything logged, as yyyy-MM-dd.
  /// Per day between [from] and [to]: kcal, protein, and which meals have food.
  Future<Map<String, ({double kcal, double protein, Set<Meal> meals})>> dayTotals(String from, String to) async {
    final rows = await _db.rawQuery(
      'SELECT day, meal, SUM(kcal) AS k, SUM(protein) AS p FROM log_entries WHERE day BETWEEN ? AND ? GROUP BY day, meal',
      [from, to],
    );
    final out = <String, ({double kcal, double protein, Set<Meal> meals})>{};
    for (final r in rows) {
      final day = r['day']! as String;
      final prev = out[day] ?? (kcal: 0.0, protein: 0.0, meals: <Meal>{});
      out[day] = (
        kcal: prev.kcal + (r['k']! as num).toDouble(),
        protein: prev.protein + (r['p']! as num).toDouble(),
        meals: {...prev.meals, Meal.values.byName(r['meal']! as String)},
      );
    }
    return out;
  }

  Future<Set<String>> loggedDays(String from, String to) async {
    final rows = await _db.rawQuery('SELECT DISTINCT day FROM log_entries WHERE day BETWEEN ? AND ?', [from, to]);
    return {for (final r in rows) r['day']! as String};
  }

  Future<void> updateEntryGrams(LogEntry e, double grams, Meal meal) async {
    final k = grams / e.grams;
    await _db.update(
      'log_entries',
      {
        'grams': grams,
        'meal': meal.name,
        'kcal': e.kcal * k,
        'protein': e.protein * k,
        'carbs': e.carbs * k,
        'fat': e.fat * k,
      },
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<Food?> foodById(String id) async {
    final rows = await _db.query('foods', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Food.fromRow(rows.first);
  }

  /// Copy a whole day into another.
  Future<int> copyDay({required String from, required String to}) async {
    var n = 0;
    for (final m in Meal.values) {
      n += await repeatMeal(from: from, to: to, meal: m);
    }
    return n;
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

  Future<void> deleteWeight(String day) => _db.delete('weigh_ins', where: 'day = ?', whereArgs: [day]);

  // ---- awards ----

  /// Workouts in total, the first one, and how many since [monthStart].
  Future<({int total, DateTime? first, int sinceMonth})> workoutCounts(DateTime monthStart) async {
    final r = (await _db.rawQuery(
      'SELECT COUNT(*) AS n, MIN(started_at) AS first, SUM(started_at >= ?) AS month FROM workouts',
      [monthStart.millisecondsSinceEpoch],
    )).first;
    final first = r['first'] as int?;
    return (
      total: r['n']! as int,
      first: first == null ? null : DateTime.fromMillisecondsSinceEpoch(first),
      sinceMonth: (r['month'] as int?) ?? 0,
    );
  }

  /// Workouts where a lift's best estimated 1RM beat every earlier one.
  Future<int> prCount() async {
    final rows = await _db.rawQuery('''
      SELECT s.workout_id, s.exercise_id, s.weight, s.reps, s.type FROM workout_sets s
      JOIN workouts w ON w.id = s.workout_id ORDER BY w.started_at, s.workout_id''');
    final best = <String, double>{};
    final inWorkout = <String, double>{};
    var n = 0;
    int? current;
    void close() {
      for (final e in inWorkout.entries) {
        final prev = best[e.key];
        if (prev != null && e.value > prev + 0.01) n++;
        if (prev == null || e.value > prev) best[e.key] = e.value;
      }
      inWorkout.clear();
    }

    for (final r in rows) {
      final w = r['workout_id']! as int;
      if (w != current) {
        close();
        current = w;
      }
      if (r['type'] == 'warmup') continue;
      final rm = estimatedOneRepMax((r['weight']! as num).toDouble(), r['reps']! as int);
      if (rm == null) continue;
      final id = r['exercise_id']! as String;
      if (rm > (inWorkout[id] ?? 0)) inWorkout[id] = rm;
    }
    close();
    return n;
  }

  /// Meals logged (each meal of each day once).
  Future<int> mealsLogged() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM (SELECT DISTINCT day, meal FROM log_entries)')) ??
      0;

  // ---- measurements ----

  Future<void> setMeasurement(String day, String kind, double value) => _db.insert('measurements', {
    'day': day,
    'kind': kind,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<(String, double)>> measurements(String kind) async {
    final rows = await _db.query('measurements', where: 'kind = ?', whereArgs: [kind], orderBy: 'day');
    return [for (final r in rows) (r['day']! as String, (r['value']! as num).toDouble())];
  }

  Future<void> deleteMeasurement(String day, String kind) =>
      _db.delete('measurements', where: 'day = ? AND kind = ?', whereArgs: [day, kind]);

  // ---- routines ----

  Future<List<Routine>> routines() async {
    final rs = await _db.query('routines', orderBy: 'created_at');
    final items = await _db.query('routine_items', orderBy: 'routine_id, position');
    return [
      for (final r in rs)
        Routine(
          id: r['id']! as int,
          name: r['name']! as String,
          weekday: r['weekday'] as int?,
          folder: RoutineFolder.values.byName(r['folder']! as String),
          items: [
            for (final i in items.where((i) => i['routine_id'] == r['id']))
              RoutineItem(
                exerciseId: i['exercise_id']! as String,
                sets: i['sets']! as int,
                repLow: i['rep_low']! as int,
                repHigh: i['rep_high']! as int,
                restSeconds: i['rest_s']! as int,
                rir: i['rir']! as int,
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
        final row = {'name': r.name.trim(), 'weekday': r.weekday, 'folder': r.folder.name};
        // One routine per weekday: whoever held the day moves to any day.
        if (r.weekday != null) {
          await tx.update(
            'routines',
            {'weekday': null},
            where: r.id == null ? 'weekday = ?' : 'weekday = ? AND id != ?',
            whereArgs: [r.weekday, ?r.id],
          );
        }
        if (r.id == null) {
          id = await tx.insert('routines', {...row, 'created_at': DateTime.now().millisecondsSinceEpoch});
        } else {
          id = r.id!;
          await tx.update('routines', row, where: 'id = ?', whereArgs: [id]);
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
            'rir': it.rir,
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
          'rir': done[i].rir,
        });
      }
    }
    return id;
  });

  Future<List<WorkoutRecord>> recentWorkouts({int limit = 20}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT w.id, w.name, w.routine_id, w.started_at, w.ended_at, COUNT(s.id) AS sets,
        COALESCE(SUM(CASE WHEN s.type = 'warmup' THEN 0 WHEN s.type = 'drop' THEN 0.5 ELSE 1 END), 0) AS hard,
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
          routineId: r['routine_id'] as int?,
          hardSets: (r['hard']! as num).toDouble(),
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
          rir: r['rir'] as int?,
        ),
    ];
  }

  /// Finished workouts that started between [from] and [to] (exclusive).
  Future<List<WorkoutRecord>> workoutsBetween(DateTime from, DateTime to) async {
    final all = await recentWorkouts(limit: 400);
    return [
      for (final w in all)
        if (!w.startedAt.isBefore(from) && w.startedAt.isBefore(to)) w,
    ];
  }

  /// Every logged set of one workout, in order.
  Future<List<LoggedExerciseSet>> setsOf(int workoutId) async {
    final rows = await _db.query(
      'workout_sets',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'ex_position, set_index',
    );
    return rows.map(LoggedExerciseSet.fromRow).toList();
  }

  /// Every logged set since [from], for this week's hard-set count.
  Future<List<LoggedExerciseSet>> setsSince(DateTime from) async {
    final rows = await _db.rawQuery(
      '''
      SELECT s.* FROM workout_sets s JOIN workouts w ON w.id = s.workout_id
      WHERE w.started_at >= ? ORDER BY w.started_at, s.ex_position, s.set_index''',
      [from.millisecondsSinceEpoch],
    );
    return rows.map(LoggedExerciseSet.fromRow).toList();
  }

  /// One exercise's history: each workout it appeared in, newest first.
  Future<List<(DateTime, List<LoggedExerciseSet>)>> historyOf(String exerciseId, {int limit = 60}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT s.*, w.started_at FROM workout_sets s JOIN workouts w ON w.id = s.workout_id
      WHERE s.exercise_id = ? ORDER BY w.started_at DESC, s.set_index''',
      [exerciseId],
    );
    final out = <(DateTime, List<LoggedExerciseSet>)>[];
    int? last;
    for (final r in rows) {
      final at = r['started_at']! as int;
      if (at != last) {
        if (out.length == limit) break;
        out.add((DateTime.fromMillisecondsSinceEpoch(at), []));
        last = at;
      }
      out.last.$2.add(LoggedExerciseSet.fromRow(r));
    }
    return out;
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
