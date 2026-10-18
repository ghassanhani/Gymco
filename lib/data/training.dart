import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/workout.dart';

/// One exercise from the bundled library (free-exercise-db, public domain).
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.instructions,
    required this.images,
    this.equipment,
    this.category,
    this.level,
  });

  final String id;
  final String name;
  final String? equipment;
  final List<String> primary;
  final List<String> secondary;
  final String? category;
  final String? level;
  final List<String> instructions;

  /// Paths inside the dataset; see [imageUrl].
  final List<String> images;

  static const imageBase = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';
  String imageUrl(int i) => '$imageBase${images[i]}';

  /// Made by the user, not from the bundled library.
  bool get custom => id.startsWith('custom:');

  /// The terser name summaries use: "Barbell Bench Press - Medium Grip" → "Barbell Bench Press".
  String get shortName => name.split(' - ').first.split(' (').first.trim();

  /// Two-letter badge for the equipment, as on the design's Train screen.
  String get badge => switch (equipment) {
    'barbell' => 'BB',
    'dumbbell' => 'DB',
    'cable' => 'CB',
    'machine' => 'MC',
    'kettlebells' => 'KB',
    'body only' => 'BW',
    'bands' => 'BD',
    'e-z curl bar' => 'EZ',
    'medicine ball' => 'MB',
    'exercise ball' => 'SB',
    'foam roll' => 'FR',
    _ => '•',
  };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'] as String,
    name: j['n'] as String,
    equipment: j['eq'] as String?,
    primary: (j['pm'] as List).cast<String>(),
    secondary: (j['sm'] as List).cast<String>(),
    category: j['cat'] as String?,
    level: j['lv'] as String?,
    instructions: (j['ins'] as List).cast<String>(),
    images: (j['img'] as List).cast<String>(),
  );
}

class ExerciseLibrary {
  ExerciseLibrary(List<Exercise> all) : all = List.unmodifiable(all), _byId = {for (final e in all) e.id: e};

  final List<Exercise> all;
  final Map<String, Exercise> _byId;

  Exercise? operator [](String id) => _byId[id];

  static const muscles = [
    'chest',
    'shoulders',
    'triceps',
    'biceps',
    'forearms',
    'lats',
    'middle back',
    'lower back',
    'traps',
    'abdominals',
    'quadriceps',
    'hamstrings',
    'glutes',
    'calves',
    'adductors',
    'abductors',
    'neck',
  ];

  /// Strength work first: the library also holds stretches and cardio.
  List<Exercise> search(String query, {String? muscle}) {
    final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final hits = all.where((e) {
      if (muscle != null && !e.primary.contains(muscle)) return false;
      final n = e.name.toLowerCase();
      return words.every(n.contains);
    }).toList();
    int rank(Exercise e) => e.category == 'strength' ? 0 : 1;
    hits.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.name.compareTo(b.name);
    });
    return hits;
  }

  /// The same library with the user's own exercises in it.
  ExerciseLibrary withCustom(List<Exercise> mine) => mine.isEmpty ? this : ExerciseLibrary([...mine, ...all]);

  static Future<ExerciseLibrary> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString('assets/exercises/exercises.json');
    return ExerciseLibrary(await compute(_parse, raw));
  }

  static List<Exercise> _parse(String raw) => [
    for (final e in jsonDecode(raw) as List) Exercise.fromJson(e as Map<String, dynamic>),
  ];
}

/// One line of a routine: an exercise with its planned sets.
class RoutineItem {
  const RoutineItem({
    required this.exerciseId,
    this.sets = 3,
    this.repLow = 8,
    this.repHigh = 12,
    this.restSeconds = 90,
    this.rir = 2,
  });

  final String exerciseId;
  final int sets;
  final int repLow;
  final int repHigh;
  final int restSeconds;

  /// Reps in reserve the plan aims for.
  final int rir;

  String get reps => '$repLow–$repHigh';

  RoutineItem copyWith({int? sets, int? repLow, int? repHigh, int? restSeconds, int? rir}) => RoutineItem(
    exerciseId: exerciseId,
    sets: sets ?? this.sets,
    repLow: repLow ?? this.repLow,
    repHigh: repHigh ?? this.repHigh,
    restSeconds: restSeconds ?? this.restSeconds,
    rir: rir ?? this.rir,
  );
}

/// The two folders the builder offers: the weekly plan, and everything else.
enum RoutineFolder { plan, mine }

class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.items,
    int? weekday,
    Set<int>? days,
    this.folder = RoutineFolder.mine,
    this.planSince,
    // Kept as two inputs so older callers can still pass one weekday.
  }) : _weekday = weekday, // ignore: prefer_initializing_formals
       _days = days; // ignore: prefer_initializing_formals
  final int? id;
  final String name;
  final List<RoutineItem> items;
  final int? _weekday;
  final Set<int>? _days;
  final RoutineFolder folder;

  /// When its days were last set: days before this were never missed.
  final DateTime? planSince;

  /// The weekdays it is planned on, 0 = Monday … 6 = Sunday; empty is
  /// "any day".
  Set<int> get days => _days ?? {?_weekday};

  /// The first of its days, or null for "any day".
  int? get weekday => days.isEmpty ? null : days.reduce((a, b) => a < b ? a : b);

  int get totalSets => items.fold(0, (n, i) => n + i.sets);

  Routine copyWith({
    int? Function()? id,
    String? name,
    List<RoutineItem>? items,
    Set<int>? days,
    RoutineFolder? folder,
  }) => Routine(
    id: id == null ? this.id : id(),
    name: name ?? this.name,
    items: items ?? this.items,
    days: days ?? this.days,
    folder: folder ?? this.folder,
    planSince: planSince,
  );
}

/// A finished workout as the history list shows it.
class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.name,
    this.routineId,
    this.hardSets = 0,
    required this.startedAt,
    required this.endedAt,
    required this.volume,
    required this.sets,
  });

  final int id;
  final String name;
  final int? routineId;
  final double hardSets;
  final DateTime startedAt;
  final DateTime endedAt;
  final double volume;
  final int sets;

  Duration get duration => endedAt.difference(startedAt);
}

/// One stored set with the exercise it belongs to.
class LoggedExerciseSet {
  const LoggedExerciseSet({
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.type,
    this.rir,
  });

  final String exerciseId;
  final String exerciseName;
  final double weightKg;
  final int reps;
  final SetType type;
  final int? rir;

  factory LoggedExerciseSet.fromRow(Map<String, Object?> r) => LoggedExerciseSet(
    exerciseId: r['exercise_id']! as String,
    exerciseName: r['exercise_name']! as String,
    weightKg: (r['weight']! as num).toDouble(),
    reps: r['reps']! as int,
    type: SetType.values.byName(r['type']! as String),
    rir: r['rir'] as int?,
  );
}
