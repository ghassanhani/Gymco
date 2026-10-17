import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../domain/awards.dart';
import '../domain/streak.dart';
import 'providers.dart';
import 'training_providers.dart';

/// The days a streak is read from, and what today still needs.
class StreakInfo {
  const StreakInfo({
    required this.state,
    required this.goal,
    required this.mealsToday,
    required this.trainedToday,
    required this.restToday,
    required this.awards,
    required this.restKept,
    this.plannedToday,
  });

  /// Kept days that were rest days, not training days.
  final Set<DateTime> restKept;

  final StreakState state;

  /// The commitment, in days.
  final int goal;

  /// Of breakfast, lunch and dinner.
  final int mealsToday;
  final bool trainedToday;

  /// Today is a rest day on the plan.
  final bool restToday;
  final String? plannedToday;
  final List<Award> awards;

  int get kept => state.current;
  bool get keptToday => mealsToday == 3 && (trainedToday || restToday);
  bool get goalDone => kept >= goal;
}

const _mainMeals = {Meal.breakfast, Meal.lunch, Meal.dinner};

final commitmentGoalProvider = Provider<int>((ref) => ref.watch(prefsProvider).getInt('streakGoal') ?? 90);

final streakProvider = FutureProvider<StreakInfo?>((ref) async {
  final p = ref.watch(profileProvider);
  if (p == null) return null;
  ref.watch(loggedDaysProvider);
  ref.watch(recentWorkoutsProvider);
  final db = ref.watch(dbProvider);
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(p.startedOn.year, p.startedOn.month, p.startedOn.day);
  final routines = await ref.watch(routinesProvider.future);
  final planDays = {for (final r in routines) ?r.weekday};

  final totals = await db.dayTotals(dayKey(start), dayKey(today));
  final workouts = await db.workoutsBetween(start, DateTime(today.year, today.month, today.day + 1));
  final trained = {for (final w in workouts) dayKey(w.startedAt)};

  final history = <StreakDay>[];
  for (var d = start; !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) {
    final k = dayKey(d);
    history.add(
      StreakDay(
        date: d,
        mealsLogged: totals[k]?.meals.containsAll(_mainMeals) ?? false,
        trained: trained.contains(k),
        // With no weekly plan, every day you do not train is a rest day.
        plannedRest: !planDays.contains(d.weekday - 1),
      ),
    );
  }
  final state = computeStreak(history: history, start: start, now: now);

  final fullDays = [
    for (final e in totals.entries)
      if (e.value.meals.containsAll(_mainMeals)) DateTime.parse(e.key),
  ]..sort();
  final proteinDays = [
    for (final e in totals.entries)
      if (e.value.protein >= p.targets.protein) DateTime.parse(e.key),
  ];
  final counts = await db.workoutCounts(DateTime(now.year, now.month));
  final stats = AwardStats(
    streak: state,
    fullDays: fullDays,
    mealsLogged: await db.mealsLogged(),
    bestProteinWeek: bestProteinWeek(proteinDays),
    workouts: counts.total,
    firstWorkout: counts.first,
    prs: await db.prCount(),
    workoutsThisMonth: counts.sinceMonth,
  );

  final todayMeals = totals[dayKey(today)]?.meals ?? const <Meal>{};
  final todayRoutine = routines.where((r) => r.weekday == today.weekday - 1).firstOrNull;
  return StreakInfo(
    state: state,
    goal: ref.watch(commitmentGoalProvider),
    mealsToday: todayMeals.intersection(_mainMeals).length,
    trainedToday: trained.contains(dayKey(today)),
    restToday: !planDays.contains(today.weekday - 1),
    plannedToday: todayRoutine?.name,
    awards: awards(stats),
    restKept: {
      for (final h in history)
        if (h.kept && !h.trained) h.date,
    },
  );
});

Future<void> setCommitment(WidgetRef ref, int days) async {
  await ref.read(prefsProvider).setInt('streakGoal', days);
  ref.invalidate(commitmentGoalProvider);
}
