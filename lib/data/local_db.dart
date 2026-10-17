import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';
import 'seed_foods.dart';

/// The on-phone database. Everything the app shows is read from here; the
/// network only ever adds foods to it.
class LocalDb {
  LocalDb(this._db);

  final Database _db;

  static const _version = 1;

  /// [singleInstance] false gives every open its own database (tests).
  static Future<LocalDb> open({DatabaseFactory? factory, String? path, bool singleInstance = true}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'gymco.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        singleInstance: singleInstance,
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
}
