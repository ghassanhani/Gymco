import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/dictation.dart';
import 'package:gymco/data/food_source.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/data/training.dart';
import 'package:gymco/state/providers.dart';
import 'package:gymco/state/training_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Synchronous SQLite in memory, so database futures complete inside the
/// widget tester's fake clock.
Future<LocalDb> openTestDb() =>
    LocalDb.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath, singleInstance: false);

class FakeFoodSource implements FoodSource {
  FakeFoodSource({this.byCode = const {}, this.online = const [], this.offline = false});
  final Map<String, Food> byCode;
  final List<Food> online;
  final bool offline;

  @override
  Future<Food?> byBarcode(String barcode, {required String languageCode}) async {
    if (offline) throw Exception('offline');
    return byCode[barcode];
  }

  @override
  Future<List<Food>> search(String query, {required String languageCode}) async {
    if (offline) throw Exception('offline');
    return online.where((f) => f.name.toLowerCase().contains(query.toLowerCase())).toList();
  }
}

final testNow = DateTime(2026, 9, 26, 13);

Future<(LocalDb, SharedPreferences)> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  FoodSource? source,
  Locale? locale,
  Future<void> Function(LocalDb db)? seed,
  DateTime Function()? clock,
  ExerciseLibrary? library,
  Dictation? dictation,
}) async {
  // A phone, not the default 800 × 600 window.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  if (locale != null) await p.setString('lang', locale.languageCode);
  final db = await openTestDb();
  await seed?.call(db);
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        prefsProvider.overrideWithValue(p),
        foodSourceProvider.overrideWithValue(source ?? FakeFoodSource()),
        clockProvider.overrideWithValue(clock ?? () => testNow),
        exerciseLibraryProvider.overrideWith((_) => library ?? testLibrary),
        showExercisePhotosProvider.overrideWithValue(false),
        dictationProvider.overrideWithValue(dictation ?? FakeDictation()),
      ],
      child: const GymcoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (db, p);
}

/// Says [words] as soon as it is asked to listen, or refuses.
class FakeDictation implements Dictation {
  FakeDictation({this.words = '', this.available = true});
  final String words;
  final bool available;
  bool listening = false;

  @override
  Future<bool> start({required String languageCode, required void Function(String words) onWords}) async {
    if (!available) return false;
    listening = true;
    onWords(words);
    return true;
  }

  @override
  Future<void> stop() async => listening = false;
}

/// A finished onboarding, as stored.
const savedProfile =
    '{"goal":"cut","sex":"male","age":30,"height":180.0,"weight":80.0,"activity":"moderate",'
    '"rate":-0.5,"kcal":2319.0,"p":176.0,"c":245.0,"f":64.0,"started":"2026-09-20T09:00:00.000"}';

Exercise _ex(String id, String name, String eq, List<String> muscles) => Exercise(
  id: id,
  name: name,
  equipment: eq,
  primary: muscles,
  secondary: const [],
  category: 'strength',
  instructions: const ['Lift it.', 'Lower it.'],
  images: const [],
);

final testLibrary = ExerciseLibrary([
  _ex('bench', 'Barbell Bench Press', 'barbell', ['chest']),
  _ex('ohp', 'Standing Military Press', 'barbell', ['shoulders']),
  _ex('lat', 'Side Lateral Raise', 'dumbbell', ['shoulders']),
  _ex('squat', 'Barbell Squat', 'barbell', ['quadriceps']),
]);

extension Fixtures on LocalDb {
  Future<int> saveRoutineFixture(String name, {int? weekday}) => saveRoutine(
    Routine(
      id: null,
      name: name,
      weekday: weekday,
      folder: weekday == null ? RoutineFolder.mine : RoutineFolder.plan,
      items: const [RoutineItem(exerciseId: 'bench', sets: 3, repLow: 5, repHigh: 8)],
    ),
  );
}

/// The real bundled library, parsed synchronously for widget tests.
ExerciseLibrary realLibrary() => ExerciseLibrary([
  for (final e in jsonDecode(File('assets/exercises/exercises.json').readAsStringSync()) as List)
    Exercise.fromJson(e as Map<String, dynamic>),
]);
