import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/templates.dart';
import '../data/training.dart';
import '../domain/schedule.dart';
import '../domain/session.dart';
import 'providers.dart';

/// Loaded once from the bundled asset; tests override it.
final exerciseLibraryProvider = FutureProvider<ExerciseLibrary>((_) => ExerciseLibrary.load());

/// Off in tests: photos need the phone's file cache.
final showExercisePhotosProvider = Provider<bool>((_) => true);

/// Where exercise photos come from: the network, kept in the phone's cache.
final exerciseImageProvider = Provider<ImageProvider Function(String url)>((_) => CachedNetworkImageProvider.new);

final routinesProvider = FutureProvider<List<Routine>>((ref) => ref.watch(dbProvider).routines());

final recentWorkoutsProvider = FutureProvider<List<WorkoutRecord>>((ref) => ref.watch(dbProvider).recentWorkouts());

final lastSetsProvider = FutureProvider.family<List<SessionSet>, String>(
  (ref, exerciseId) => ref.watch(dbProvider).lastSetsFor(exerciseId),
);

/// The strip's seven days with what each holds, slid as the prototype slides them.
final weekScheduleProvider = FutureProvider<List<ScheduledDay>>((ref) async {
  final now = ref.watch(clockProvider)();
  final routines = await ref.watch(routinesProvider.future);
  ref.watch(recentWorkoutsProvider);
  final days = stripDays(now);
  final done = await ref
      .watch(dbProvider)
      .workoutsBetween(days.first, DateTime(days.last.year, days.last.month, days.last.day + 1));
  return schedule(
    days: days,
    today: now,
    routines: [for (final r in routines) PlannedRoutine(id: r.id!, name: r.name, weekday: r.weekday)],
    workouts: [for (final w in done) DoneWorkout(day: w.startedAt, name: w.name, routineId: w.routineId)],
  );
});

class RoutineActions {
  RoutineActions(this.ref);
  final Ref ref;

  Future<int> save(Routine r) async {
    final id = await ref.read(dbProvider).saveRoutine(r);
    ref.invalidate(routinesProvider);
    return id;
  }

  Future<void> delete(int id) async {
    await ref.read(dbProvider).deleteRoutine(id);
    ref.invalidate(routinesProvider);
  }

  /// A name no routine has yet: [base], then "base 2", "base 3"…
  Future<String> freeName(String base) async {
    final taken = {for (final r in await ref.read(routinesProvider.future)) r.name.toLowerCase()};
    if (!taken.contains(base.toLowerCase())) return base;
    for (var n = 2; ; n++) {
      final c = '$base $n';
      if (!taken.contains(c.toLowerCase())) return c;
    }
  }

  /// A copy off the weekly rotation, so it never moves the original.
  Future<String> duplicate(Routine r, String copyName) async {
    final name = await freeName(copyName);
    await save(r.copyWith(id: () => null, name: name, weekday: () => null, folder: RoutineFolder.mine));
    return name;
  }

  /// Add a starter block to the weekly plan. [name] gives each role its
  /// name in the user's language.
  Future<void> applyTemplate(TemplateKind k, String Function(String role) name) async {
    for (final t in templateRoutines(k)) {
      await save(
        Routine(
          id: null,
          name: await freeName(name(t.role)),
          items: t.items,
          weekday: t.weekday,
          folder: RoutineFolder.plan,
        ),
      );
    }
  }
}

final routineActionsProvider = Provider<RoutineActions>(RoutineActions.new);

/// When each routine was last run, by routine id.
final lastRunProvider = Provider<Map<int, DateTime>>((ref) {
  final out = <int, DateTime>{};
  for (final w in ref.watch(recentWorkoutsProvider).value ?? const <WorkoutRecord>[]) {
    final id = w.routineId;
    if (id != null && (out[id] == null || w.startedAt.isAfter(out[id]!))) out[id] = w.startedAt;
  }
  return out;
});

/// Exercises with a set logged today, so a routine run one exercise at a
/// time shows which are done.
final loggedTodayProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(recentWorkoutsProvider);
  final t = ref.watch(clockProvider)();
  final sets = await ref.watch(dbProvider).setsSince(DateTime(t.year, t.month, t.day));
  return {for (final s in sets) s.exerciseId};
});

/// Hard sets logged per exercise since Monday.
final setsThisWeekProvider = FutureProvider<List<LoggedExerciseSet>>((ref) async {
  ref.watch(recentWorkoutsProvider);
  final t = ref.watch(clockProvider)();
  return ref.watch(dbProvider).setsSince(DateTime(t.year, t.month, t.day - (t.weekday - 1)));
});

/// The result of finishing: what was saved and which lifts set a new best.
class FinishedWorkout {
  const FinishedWorkout({required this.session, required this.endedAt, required this.bests});
  final WorkoutSession session;
  final DateTime endedAt;
  final Map<String, double> bests;
}

/// The live workout. Saved to the phone on every change, so a closed app or
/// a dead battery never loses a set.
class ActiveWorkoutNotifier extends Notifier<WorkoutSession?> {
  static const _k = 'activeWorkout';

  @override
  WorkoutSession? build() {
    final raw = ref.watch(prefsProvider).getString(_k);
    if (raw == null) return null;
    try {
      return WorkoutSession.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  DateTime get _now => ref.read(clockProvider)();

  void _set(WorkoutSession? s) {
    state = s;
    final p = ref.read(prefsProvider);
    s == null ? p.remove(_k) : p.setString(_k, jsonEncode(s.toJson()));
  }

  void startEmpty(String name) => _set(WorkoutSession.start(name: name, now: _now));

  /// Start a routine, pre-filling each exercise with last time's numbers.
  Future<void> startRoutine(Routine r, ExerciseLibrary lib) async {
    final db = ref.read(dbProvider);
    final exercises = <SessionExercise>[];
    for (final item in r.items) {
      final prev = await db.lastSetsFor(item.exerciseId);
      exercises.add(
        SessionExercise(
          exerciseId: item.exerciseId,
          name: lib[item.exerciseId]?.name ?? item.exerciseId,
          repLow: item.repLow,
          repHigh: item.repHigh,
          restSeconds: item.restSeconds,
          rir: item.rir,
          previous: prev,
          sets: [
            for (var i = 0; i < item.sets; i++)
              SessionSet(weightKg: i < prev.length ? prev[i].weightKg : (prev.isEmpty ? null : prev.last.weightKg)),
          ],
        ),
      );
    }
    _set(WorkoutSession.start(name: r.name, now: _now, routineId: r.id, exercises: exercises));
  }

  /// One exercise of a routine, on its own. Same screen, same logging; the
  /// day shows it done and keeps the rest of the routine there.
  Future<void> startOne(Routine r, int index, ExerciseLibrary lib) async {
    await startRoutine(
      Routine(id: null, name: lib[r.items[index].exerciseId]?.shortName ?? r.name, items: [r.items[index]]),
      lib,
    );
  }

  void update(WorkoutSession Function(WorkoutSession s, DateTime now) f) {
    final s = state;
    if (s != null) _set(f(s, _now));
  }

  Future<void> addExercises(Iterable<Exercise> list) async {
    final db = ref.read(dbProvider);
    final adds = <SessionExercise>[];
    for (final e in list) {
      final prev = await db.lastSetsFor(e.id);
      final kg = prev.isEmpty ? null : prev.first.weightKg;
      adds.add(
        SessionExercise(
          exerciseId: e.id,
          name: e.name,
          previous: prev,
          sets: [for (var i = 0; i < 3; i++) SessionSet(weightKg: i < prev.length ? prev[i].weightKg : kg)],
        ),
      );
    }
    update((s, _) => adds.fold(s, (n, e) => n.addExercise(e)));
  }

  void discard() => _set(null);

  Future<FinishedWorkout?> finish() async {
    final s = state;
    if (s == null) return null;
    final db = ref.read(dbProvider);
    final endedAt = _now;
    final before = await db.bestOneRepMaxes(s.exercises.map((e) => e.exerciseId));
    if (!s.isEmpty) await db.saveWorkout(s, endedAt);
    _set(null);
    ref.invalidate(recentWorkoutsProvider);
    for (final e in s.exercises) {
      ref.invalidate(lastSetsProvider(e.exerciseId));
    }
    return FinishedWorkout(session: s, endedAt: endedAt, bests: newBests(s, before));
  }
}

final activeWorkoutProvider = NotifierProvider<ActiveWorkoutNotifier, WorkoutSession?>(ActiveWorkoutNotifier.new);

final setsOfWorkoutProvider = FutureProvider.family<List<LoggedExerciseSet>, int>(
  (ref, id) => ref.watch(dbProvider).setsOf(id),
);

/// One exercise's history, newest workout first.
final exerciseHistoryProvider = FutureProvider.family<List<(DateTime, List<LoggedExerciseSet>)>, String>((ref, id) {
  ref.watch(recentWorkoutsProvider);
  return ref.watch(dbProvider).historyOf(id);
});
