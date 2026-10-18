import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/cloud.dart';
import 'package:gymco/data/dictation.dart';
import 'package:gymco/data/food_source.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/data/photo_picker.dart';
import 'package:gymco/data/reminder_scheduler.dart';
import 'package:gymco/data/training.dart';
import 'package:gymco/state/cloud_providers.dart';
import 'package:gymco/state/providers.dart';
import 'package:gymco/state/reminder_providers.dart';
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
  Cloud? cloud,
  PhotoPicker? picker,
  ImageProvider Function(String url)? exerciseImages,
  FakeReminders? reminders,
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
        showExercisePhotosProvider.overrideWithValue(exerciseImages != null),
        if (exerciseImages != null) exerciseImageProvider.overrideWithValue(exerciseImages),
        dictationProvider.overrideWithValue(dictation ?? FakeDictation()),
        cloudProvider.overrideWithValue(cloud ?? const NoCloud()),
        photoPickerProvider.overrideWithValue(picker ?? FakePicker()),
        reminderSchedulerProvider.overrideWithValue(reminders ?? FakeReminders()),
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

/// An account in memory: code 123456 signs in, one backup slot, a photo
/// that always shows [photoFoods].
class FakeCloud implements Cloud {
  FakeCloud({this.signedIn, this.backup, this.photoFoods = const [], this.scansLeft = 9});
  String? signedIn;
  CloudBackup? backup;
  List<PhotoFood> photoFoods;
  int scansLeft;
  String? lastNote;
  bool? lastHadImage;
  final _changes = StreamController<String?>.broadcast();
  int uploads = 0;

  @override
  bool get available => true;
  @override
  String? get email => signedIn;
  @override
  Stream<String?> get emailChanges => _changes.stream;
  @override
  Future<void> sendCode(String email) async {}
  @override
  Future<void> verifyCode(String email, String code) async {
    if (code != '123456') throw const CloudException(CloudFailure.badCode);
    signedIn = email;
    _changes.add(email);
  }

  /// The user tapped the link in the email.
  void openLink(String email) {
    signedIn = email;
    _changes.add(email);
  }

  @override
  Future<void> signOut() async {
    signedIn = null;
    _changes.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    backup = null;
    await signOut();
  }

  @override
  Future<void> upload(Map<String, Object?> payload, {required int schemaVersion}) async {
    uploads++;
    // Through JSON, as the server stores it.
    backup = CloudBackup(payload: jsonDecode(jsonEncode(payload)) as Map<String, Object?>, at: testNow);
  }

  @override
  Future<CloudBackup?> download() async => backup;

  @override
  Future<(List<PhotoFood>, int)> scanPhoto(Uint8List? jpeg, {required String languageCode, String note = ''}) async {
    lastNote = note;
    lastHadImage = jpeg != null;
    if (scansLeft <= 0) throw const CloudException(CloudFailure.dailyCap);
    return (photoFoods, --scansLeft);
  }
}

/// Hands back a one-pixel JPEG, or nothing when cancelled.
class FakePicker implements PhotoPicker {
  FakePicker({this.cancel = false});
  final bool cancel;
  @override
  Future<Uint8List?> pick({required bool camera}) async => cancel
      ? null
      : base64Decode(
          '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=',
        );
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
  images: ['$id/0.jpg', '$id/1.jpg'],
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

/// Keeps what would be scheduled, and can refuse permission.
class FakeReminders implements ReminderScheduler {
  FakeReminders({this.allow = true});
  final bool allow;
  List<ReminderNote> scheduled = const [];

  @override
  Future<bool> requestPermission() async => allow;

  @override
  Future<void> replaceAll(List<ReminderNote> notes) async => scheduled = notes;
}
