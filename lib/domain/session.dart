/// A live workout, as plain data. The screen renders it; every change goes
/// through these methods so the rules live in one tested place.
library;

import 'workout.dart';

class SessionSet {
  const SessionSet({this.weightKg, this.reps, this.type = SetType.normal, this.done = false, this.rir});

  final double? weightKg;
  final int? reps;
  final SetType type;
  final bool done;

  /// Reps in reserve, as the lifter judged it.
  final int? rir;

  bool get complete => weightKg != null && reps != null && reps! > 0;

  LoggedSet toLogged() => LoggedSet(weightKg: weightKg ?? 0, reps: reps ?? 0, type: type, done: done);

  SessionSet copyWith({
    double? Function()? weightKg,
    int? Function()? reps,
    SetType? type,
    bool? done,
    int? Function()? rir,
  }) => SessionSet(
    weightKg: weightKg == null ? this.weightKg : weightKg(),
    reps: reps == null ? this.reps : reps(),
    type: type ?? this.type,
    done: done ?? this.done,
    rir: rir == null ? this.rir : rir(),
  );

  Map<String, Object?> toJson() => {'w': weightKg, 'r': reps, 't': type.name, 'd': done, 'rir': rir};

  factory SessionSet.fromJson(Map<String, Object?> j) => SessionSet(
    weightKg: (j['w'] as num?)?.toDouble(),
    reps: j['r'] as int?,
    type: SetType.values.byName(j['t']! as String),
    done: j['d']! as bool,
    rir: j['rir'] as int?,
  );
}

class SessionExercise {
  const SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.repLow,
    this.repHigh,
    this.restSeconds = defaultRestSeconds,
    this.rir,
    this.note = '',
  });

  final String exerciseId;
  final String name;
  final List<SessionSet> sets;
  final int? repLow;
  final int? repHigh;

  /// Rest after each set; 0 turns the timer off for this exercise.
  final int restSeconds;

  /// The plan's reps in reserve, when it came from a routine.
  final int? rir;

  /// A cue, a machine setting, how it felt.
  final String note;

  SessionExercise copyWith({List<SessionSet>? sets, int? restSeconds, String? note}) => SessionExercise(
    exerciseId: exerciseId,
    name: name,
    sets: sets ?? this.sets,
    repLow: repLow,
    repHigh: repHigh,
    restSeconds: restSeconds ?? this.restSeconds,
    rir: rir,
    note: note ?? this.note,
  );

  SessionExercise withSets(List<SessionSet> s) => copyWith(sets: s);

  Map<String, Object?> toJson() => {
    'id': exerciseId,
    'n': name,
    'lo': repLow,
    'hi': repHigh,
    'rest': restSeconds,
    'rir': rir,
    'note': note,
    's': [for (final s in sets) s.toJson()],
  };

  factory SessionExercise.fromJson(Map<String, Object?> j) => SessionExercise(
    exerciseId: j['id']! as String,
    name: j['n']! as String,
    repLow: j['lo'] as int?,
    repHigh: j['hi'] as int?,
    restSeconds: j['rest']! as int,
    rir: j['rir'] as int?,
    note: (j['note'] as String?) ?? '',
    sets: [for (final s in j['s']! as List) SessionSet.fromJson((s as Map).cast<String, Object?>())],
  );
}

const int defaultRestSeconds = 90;

class WorkoutSession {
  const WorkoutSession({
    required this.name,
    required this.startedAt,
    required this.exercises,
    this.routineId,
    this.restStartedAt,
    this.restSeconds,
  });

  final String name;
  final int? routineId;
  final DateTime startedAt;
  final List<SessionExercise> exercises;

  /// The rest timer runs from the last ticked set; null when none is running.
  final DateTime? restStartedAt;
  final int? restSeconds;

  factory WorkoutSession.start({
    required String name,
    required DateTime now,
    int? routineId,
    List<SessionExercise> exercises = const [],
  }) => WorkoutSession(name: name, startedAt: now, exercises: exercises, routineId: routineId);

  WorkoutSession _with({
    List<SessionExercise>? exercises,
    DateTime? Function()? restStartedAt,
    int? Function()? restSeconds,
  }) => WorkoutSession(
    name: name,
    routineId: routineId,
    startedAt: startedAt,
    exercises: exercises ?? this.exercises,
    restStartedAt: restStartedAt == null ? this.restStartedAt : restStartedAt(),
    restSeconds: restSeconds == null ? this.restSeconds : restSeconds(),
  );

  WorkoutSession _editSets(int ex, List<SessionSet> Function(List<SessionSet>) f) {
    final list = [...exercises];
    list[ex] = list[ex].withSets(f([...list[ex].sets]));
    return _with(exercises: list);
  }

  WorkoutSession addExercise(SessionExercise e) => _with(exercises: [...exercises, e]);

  WorkoutSession removeExercise(int ex) => _with(exercises: [...exercises]..removeAt(ex));

  /// A new set copies the last one's numbers, so the common case is one tick.
  WorkoutSession addSet(int ex) => _editSets(ex, (s) {
    final last = s.isEmpty ? null : s.last;
    return s..add(
      SessionSet(
        weightKg: last?.weightKg,
        reps: last?.reps,
        type: last?.type == SetType.warmup ? SetType.normal : (last?.type ?? SetType.normal),
      ),
    );
  });

  WorkoutSession removeSet(int ex, int i) => _editSets(ex, (s) => s..removeAt(i));

  WorkoutSession updateSet(int ex, int i, SessionSet Function(SessionSet) f) => _editSets(ex, (s) => s..[i] = f(s[i]));

  /// Ticking a complete set starts its exercise's rest timer; unticking stops it.
  WorkoutSession toggleDone(int ex, int i, DateTime now) {
    final s = exercises[ex].sets[i];
    if (!s.done && !s.complete) return this;
    final next = updateSet(ex, i, (x) => x.copyWith(done: !x.done));
    if (s.done) return next._with(restStartedAt: () => null, restSeconds: () => null);
    final planned = exercises[ex].restSeconds;
    if (planned == 0) return next._with(restStartedAt: () => null, restSeconds: () => null);
    final rest = s.type == SetType.warmup ? 45 : planned;
    return next._with(restStartedAt: () => now, restSeconds: () => rest);
  }

  WorkoutSession setRest(int ex, int seconds) {
    final list = [...exercises];
    list[ex] = list[ex].copyWith(restSeconds: seconds);
    return _with(exercises: list);
  }

  WorkoutSession setNote(int ex, String note) {
    final list = [...exercises];
    list[ex] = list[ex].copyWith(note: note);
    return _with(exercises: list);
  }

  /// Where the next unticked set is, for the rest bar's "next up" line.
  (int, int)? get nextSet {
    for (var e = 0; e < exercises.length; e++) {
      for (var i = 0; i < exercises[e].sets.length; i++) {
        if (!exercises[e].sets[i].done) return (e, i);
      }
    }
    return null;
  }

  /// Hard sets done, by set type weight (warm-ups 0, drop ½).
  double get hardSetsDone => hardSets(_logged);

  WorkoutSession adjustRest(int deltaSeconds) =>
      restSeconds == null ? this : _with(restSeconds: () => (restSeconds! + deltaSeconds).clamp(0, 600));

  WorkoutSession skipRest() => _with(restStartedAt: () => null, restSeconds: () => null);

  /// Seconds of rest left, or null when no timer is running or it has ended.
  int? restLeft(DateTime now) {
    if (restStartedAt == null || restSeconds == null) return null;
    final left = restSeconds! - now.difference(restStartedAt!).inSeconds;
    return left > 0 ? left : null;
  }

  Duration elapsed(DateTime now) => now.difference(startedAt);

  Iterable<LoggedSet> get _logged => exercises.expand((e) => e.sets.map((s) => s.toLogged()));

  double get volume => totalVolume(_logged);
  int get setsDone => exercises.fold(0, (n, e) => n + e.sets.where((s) => s.done).length);
  int get setsPlanned => exercises.fold(0, (n, e) => n + e.sets.length);
  bool get hasUnfinishedSets => setsDone < setsPlanned;
  bool get isEmpty => setsDone == 0;

  Map<String, Object?> toJson() => {
    'name': name,
    'routine': routineId,
    'start': startedAt.toIso8601String(),
    'restAt': restStartedAt?.toIso8601String(),
    'rest': restSeconds,
    'ex': [for (final e in exercises) e.toJson()],
  };

  factory WorkoutSession.fromJson(Map<String, Object?> j) => WorkoutSession(
    name: j['name']! as String,
    routineId: j['routine'] as int?,
    startedAt: DateTime.parse(j['start']! as String),
    restStartedAt: j['restAt'] == null ? null : DateTime.parse(j['restAt']! as String),
    restSeconds: j['rest'] as int?,
    exercises: [for (final e in j['ex']! as List) SessionExercise.fromJson((e as Map).cast<String, Object?>())],
  );
}

/// New bests: exercises whose best estimated 1RM today beats every earlier one.
Map<String, double> newBests(WorkoutSession s, Map<String, double> previousBest) {
  final out = <String, double>{};
  for (final e in s.exercises) {
    double? best;
    for (final set in e.sets.where((x) => x.done && x.type != SetType.warmup)) {
      final rm = estimatedOneRepMax(set.weightKg ?? 0, set.reps ?? 0);
      if (rm != null && (best == null || rm > best)) best = rm;
    }
    if (best == null) continue;
    final prev = previousBest[e.exerciseId];
    if (prev != null && best > prev + 0.01) out[e.exerciseId] = best;
  }
  return out;
}
