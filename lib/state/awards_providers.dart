import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../domain/awards.dart';
import '../domain/streak.dart';
import 'cloud_providers.dart';
import 'pack_providers.dart';
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

/// A pause in the streak, first and last day, when one is set.
final streakPauseProvider = Provider<(DateTime, DateTime)?>((ref) {
  final raw = ref.watch(prefsProvider).getString('streakPause')?.split('|');
  if (raw == null || raw.length != 2) return null;
  final (a, b) = (DateTime.tryParse(raw[0]), DateTime.tryParse(raw[1]));
  return a == null || b == null ? null : (a, b);
});

/// Pause the streak from today for [days] days, or end it with 0.
Future<void> setStreakPause(WidgetRef ref, int days) async {
  final p = ref.read(prefsProvider);
  final now = ref.read(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  if (days == 0) {
    final cur = ref.read(streakPauseProvider);
    // Ending early keeps the days already paused.
    if (cur != null && cur.$1.isBefore(today)) {
      await p.setString('streakPause', '${dayKey(cur.$1)}|${dayKey(today.subtract(const Duration(days: 1)))}');
    } else {
      await p.remove('streakPause');
    }
  } else {
    await p.setString('streakPause', '${dayKey(today)}|${dayKey(today.add(Duration(days: days - 1)))}');
  }
  ref.invalidate(streakPauseProvider);
  ref.invalidate(streakProvider);
}

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
  final planDays = {for (final r in routines) ...r.days};
  final chosenRest = chosenRestDays(ref.watch(prefsProvider));
  final pause = ref.watch(streakPauseProvider);

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
        plannedRest: !planDays.contains(d.weekday - 1) || chosenRest.contains(k),
        paused: pause != null && !d.isBefore(pause.$1) && !d.isAfter(pause.$2),
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

  final packs = ref.watch(packsProvider);
  final challenge = packs.challengeFor(now);
  final all = awards(
    stats,
    extra: packs.awards,
    monthTarget: challenge?.target ?? monthlyChallenge,
    monthTitle: challenge?.title.toMap(),
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
    awards: _isTester(ref) ? previewUnlock(all, today) : all,
    restKept: {
      for (final h in history)
        if (h.kept && !h.trained) h.date,
    },
  );
});

/// Testers who see a set of badges already earned, to check how they look.
const testerEmails = {'ghassanhani0@gmail.com'};

bool _isTester(Ref ref) {
  final email = ref.watch(accountProvider).value ?? ref.watch(cloudProvider).email;
  return email != null && testerEmails.contains(email.toLowerCase());
}

/// The first two badges of each group, earned over the past days.
List<Award> previewUnlock(List<Award> all, DateTime today) {
  final seen = <AwardGroup, int>{};
  return [
    for (final (i, a) in all.indexed)
      if (a.earned || (seen[a.group] = (seen[a.group] ?? 0) + 1) > 2)
        a
      else
        a.copyWith(
          have: a.need,
          earnedOn: today.subtract(Duration(days: i % 9)),
        ),
  ];
}

Future<void> setCommitment(WidgetRef ref, int days) async {
  await ref.read(prefsProvider).setInt('streakGoal', days);
  ref.invalidate(commitmentGoalProvider);
}
