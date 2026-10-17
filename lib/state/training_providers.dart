import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/training.dart';
import '../domain/session.dart';
import 'providers.dart';

/// Loaded once from the bundled asset; tests override it.
final exerciseLibraryProvider = FutureProvider<ExerciseLibrary>((_) => ExerciseLibrary.load());

/// Off in tests: photos need the phone's file cache.
final showExercisePhotosProvider = Provider<bool>((_) => true);

final routinesProvider = FutureProvider<List<Routine>>((ref) => ref.watch(dbProvider).routines());

final recentWorkoutsProvider = FutureProvider<List<WorkoutRecord>>((ref) => ref.watch(dbProvider).recentWorkouts());

final lastSetsProvider = FutureProvider.family<List<SessionSet>, String>(
  (ref, exerciseId) => ref.watch(dbProvider).lastSetsFor(exerciseId),
);

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
}

final routineActionsProvider = Provider<RoutineActions>(RoutineActions.new);

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
          sets: [
            for (var i = 0; i < item.sets; i++)
              SessionSet(
                weightKg: i < prev.length ? prev[i].weightKg : (prev.isEmpty ? null : prev.last.weightKg),
                reps: i < prev.length ? prev[i].reps : null,
              ),
          ],
        ),
      );
    }
    _set(WorkoutSession.start(name: r.name, now: _now, routineId: r.id, exercises: exercises));
  }

  void update(WorkoutSession Function(WorkoutSession s, DateTime now) f) {
    final s = state;
    if (s != null) _set(f(s, _now));
  }

  void addExercises(Iterable<Exercise> list) => update((s, _) {
    var next = s;
    for (final e in list) {
      next = next.addExercise(SessionExercise(exerciseId: e.id, name: e.name, sets: const [SessionSet()]));
    }
    return next;
  });

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
