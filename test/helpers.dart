import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/food_source.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/state/providers.dart';
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
}) async {
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
        clockProvider.overrideWithValue(() => testNow),
      ],
      child: const GymcoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (db, p);
}

/// A finished onboarding, as stored.
const savedProfile =
    '{"goal":"cut","sex":"male","age":30,"height":180.0,"weight":80.0,"activity":"moderate",'
    '"rate":-0.5,"kcal":2319.0,"p":176.0,"c":245.0,"f":64.0,"started":"2026-09-20T09:00:00.000"}';
