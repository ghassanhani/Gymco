/// Training maths: set types, volume and estimated strength.
library;

enum SetType { warmup, normal, failure, drop }

extension SetTypeX on SetType {
  /// How much one set of this type counts toward weekly hard sets.
  /// Warm-ups prime, they do not count; a drop set is half a working set.
  double get hardSetWeight => switch (this) {
    SetType.warmup => 0,
    SetType.normal => 1,
    SetType.failure => 1,
    SetType.drop => 0.5,
  };
}

class LoggedSet {
  const LoggedSet({required this.weightKg, required this.reps, this.type = SetType.normal, this.done = true});

  final double weightKg;
  final int reps;
  final SetType type;
  final bool done;

  double get volume => done && type != SetType.warmup ? weightKg * reps : 0;
}

/// Epley estimated one-rep max; null for empty or very high-rep sets.
double? estimatedOneRepMax(double weightKg, int reps) {
  if (reps <= 0 || weightKg <= 0 || reps > 12) return null;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}

double totalVolume(Iterable<LoggedSet> sets) => sets.fold(0, (sum, s) => sum + s.volume);

double hardSets(Iterable<LoggedSet> sets) => sets.where((s) => s.done).fold(0, (sum, s) => sum + s.type.hardSetWeight);

/// A deload week runs at roughly 60% of the usual working load, rounded to
/// the nearest plate step.
double deloadWeight(double weightKg, {double factor = 0.6, double step = 2.5}) =>
    (weightKg * factor / step).round() * step;
