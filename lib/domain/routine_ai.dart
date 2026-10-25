import '../data/training.dart';

/// What the routine builder made of the user's words, ready to save.
class AiPlan {
  const AiPlan({required this.routines, required this.summary, this.missing = const []});
  final List<Routine> routines;
  final String summary;

  /// Exercises the model named that the library doesn't have; left out.
  final List<String> missing;

  bool get isEmpty => routines.isEmpty;
}

/// The names the model may pick from: lifts, not stretches or cardio. The
/// user's own exercises are in [lib] too, so they can come back as well.
List<String> plannableNames(ExerciseLibrary lib) => [
  for (final e in lib.all)
    if (e.category == null ||
        const {'strength', 'powerlifting', 'olympic weightlifting', 'strongman'}.contains(e.category))
      e.name,
];

int _int(Object? v, int fallback, int lo, int hi) => switch (v) {
  final num n => n.round().clamp(lo, hi),
  _ => fallback,
};

/// Reads the routine-ai answer into routines for [lib]. Each exercise is
/// matched by its exact name first, then by search; numbers out of range
/// are pulled back into it, and a routine with nothing left is dropped.
AiPlan planFrom(Map<String, Object?> data, ExerciseLibrary lib) {
  final byName = {for (final e in lib.all) e.name.toLowerCase(): e};
  final missing = <String>[];
  final routines = <Routine>[];
  for (final raw in (data['routines'] as List? ?? const [])) {
    if (raw is! Map) continue;
    final items = <RoutineItem>[];
    for (final it in (raw['items'] as List? ?? const [])) {
      if (it is! Map) continue;
      final name = '${it['exercise'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      final e = byName[name.toLowerCase()] ?? lib.search(name).firstOrNull;
      if (e == null) {
        missing.add(name);
        continue;
      }
      if (items.any((x) => x.exerciseId == e.id)) continue;
      final lo = _int(it['rep_low'], 8, 1, 50);
      items.add(
        RoutineItem(
          exerciseId: e.id,
          sets: _int(it['sets'], 3, 1, 10),
          repLow: lo,
          repHigh: _int(it['rep_high'], 12, lo, 60),
          restSeconds: _int(it['rest_seconds'], 90, 30, 600),
        ),
      );
    }
    if (items.isEmpty) continue;
    final days = {
      for (final d in (raw['days'] as List? ?? const []))
        if (d is num && d >= 0 && d <= 6) d.toInt(),
    };
    final name = '${raw['name'] ?? ''}'.trim();
    routines.add(
      Routine(
        id: null,
        name: name.isEmpty ? 'Routine ${routines.length + 1}' : (name.length > 40 ? name.substring(0, 40) : name),
        items: items,
        days: days,
        folder: days.isEmpty ? RoutineFolder.mine : RoutineFolder.plan,
      ),
    );
  }
  return AiPlan(routines: routines, summary: '${data['summary'] ?? ''}'.trim(), missing: missing);
}
