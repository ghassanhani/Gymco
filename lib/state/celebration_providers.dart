import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/awards.dart';
import 'awards_providers.dart';

/// Off in widget tests that aren't about celebrations, so a sheet never sits
/// over the screen a test goes on to tap.
final celebrationsOnProvider = Provider<bool>((ref) => true);

/// Today's part of the streak: the three main meals and the workout, which a
/// rest day counts as done.
class DayProgress {
  const DayProgress({
    required this.day,
    required this.meals,
    required this.trained,
    required this.rest,
    required this.streak,
    required this.kept,
    this.plannedToday,
  });

  factory DayProgress.of(StreakInfo s, String day) => DayProgress(
    day: day,
    meals: s.mealsToday,
    trained: s.trainedToday,
    rest: s.restToday,
    streak: s.kept,
    kept: s.keptToday,
    plannedToday: s.plannedToday,
  );

  final String day;

  /// Of breakfast, lunch and dinner.
  final int meals;
  final bool trained;
  final bool rest;

  /// Kept days in the run, today included once it is kept.
  final int streak;
  final bool kept;
  final String? plannedToday;

  static const total = 4;
  int get done => meals + (trained || rest ? 1 : 0);
  double get fraction => done / total;

  /// The day number today becomes when it is kept.
  int get dayNumber => kept ? streak : streak + 1;
}

sealed class Celebration {
  const Celebration();
}

/// Today moved forward: the flame sheet.
class DayCelebration extends Celebration {
  const DayCelebration(this.now, {required this.from, required this.justKept});
  final DayProgress now;

  /// Where the flame stood before this log, 0 to 1.
  final double from;

  /// This log is the one that kept the day.
  final bool justKept;
}

/// An award earned: the full-screen moment, with sound.
class AwardCelebration extends Celebration {
  const AwardCelebration(this.award);
  final Award award;
}

/// What to show after the streak changed from [before] to [after].
///
/// [seen] holds the award ids already celebrated (or already earned when
/// celebrations first ran, so nobody gets a flood on updating). Awards come
/// first; a new award already says the day went well, so it replaces the
/// flame sheet rather than stacking on it. Nothing shows on the first read
/// ([before] null), on another day, or when the day only went backwards.
({List<Celebration> show, Set<String> seen}) decideCelebrations({
  required DayProgress? before,
  required DayProgress after,
  required List<Award> awards,
  required Set<String> seen,
}) {
  final earned = {
    for (final a in awards)
      if (a.earned) a.id,
  };
  if (before == null) return (show: const [], seen: {...seen, ...earned});
  final fresh = [
    for (final a in awards)
      if (a.earned && !seen.contains(a.id)) a,
  ];
  final nextSeen = {...seen, ...earned};
  if (fresh.isNotEmpty) return (show: [for (final a in fresh) AwardCelebration(a)], seen: nextSeen);
  if (before.day == after.day && after.done > before.done) {
    return (show: [DayCelebration(after, from: before.fraction, justKept: after.kept && !before.kept)], seen: nextSeen);
  }
  return (show: const [], seen: nextSeen);
}
