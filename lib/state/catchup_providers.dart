import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'providers.dart';
import 'training_providers.dart';

/// A recent day with nothing logged, and what else happened on it.
class OpenDay {
  const OpenDay({required this.day, required this.date, this.trained, this.planned});
  final String day;
  final DateTime date;

  /// The workout done that day, if any.
  final String? trained;

  /// The plan's routine for that weekday, if any.
  final String? planned;
}

/// The usual day: the average of the last week's logged days.
typedef UsualDay = ({double kcal, double protein});

/// Up to the last seven days before today with no food, since the plan
/// started, leaving out the ones already answered.
final openDaysProvider = FutureProvider<List<OpenDay>>((ref) async {
  final p = ref.watch(profileProvider);
  if (p == null) return const [];
  final logged = await ref.watch(loggedDaysProvider.future);
  final skipped = (ref.watch(prefsProvider).getStringList('catchupSkipped') ?? const []).toSet();
  final workouts = await ref.watch(recentWorkoutsProvider.future);
  final routines = await ref.watch(routinesProvider.future);
  final now = ref.watch(clockProvider)();
  final start = DateTime(p.startedOn.year, p.startedOn.month, p.startedOn.day);
  return [
    for (var i = 1; i <= 7; i++)
      if (DateTime(now.year, now.month, now.day - i) case final d
          when !d.isBefore(start) && !logged.contains(dayKey(d)) && !skipped.contains(dayKey(d)))
        OpenDay(
          day: dayKey(d),
          date: d,
          trained: workouts.where((w) => dayKey(w.startedAt) == dayKey(d)).firstOrNull?.name,
          planned: routines.where((r) => r.weekday == d.weekday - 1).firstOrNull?.name,
        ),
  ].reversed.toList();
});

final usualDayProvider = FutureProvider<UsualDay>((ref) async {
  final p = ref.watch(profileProvider);
  final now = ref.watch(clockProvider)();
  final totals = await ref
      .watch(dbProvider)
      .dayTotals(dayKey(now.subtract(const Duration(days: 7))), dayKey(now.subtract(const Duration(days: 1))));
  final days = totals.values.where((t) => t.kcal > 0).toList();
  if (days.isEmpty) return (kcal: p?.targetKcal ?? 2000, protein: p?.targets.protein ?? 120);
  return (
    kcal: days.fold<double>(0, (s, t) => s + t.kcal) / days.length,
    protein: days.fold<double>(0, (s, t) => s + t.protein) / days.length,
  );
});

/// The rough day as one estimate entry: kcal and protein as given, the
/// rest split the usual way.
Food roughDayFood() => const Food(
  id: 'estimate:day',
  name: 'Rough day total',
  kcal: 100,
  protein: 0,
  carbs: 0,
  fat: 0,
  source: 'estimate',
);

class CatchupActions {
  CatchupActions(this.ref);
  final Ref ref;

  /// Fills [fills] (day → kcal, protein) and marks [leaveOut] as answered.
  Future<void> save(Map<String, UsualDay> fills, Iterable<String> leaveOut) async {
    final db = ref.read(dbProvider);
    for (final MapEntry(key: day, value: v) in fills.entries) {
      final protein = v.protein;
      final fat = (v.kcal * 0.3) / 9;
      final carbs = ((v.kcal - protein * 4 - fat * 9) / 4).clamp(0, double.infinity);
      await db.addEntry(
        LogEntry(
          id: null,
          day: day,
          meal: Meal.snack,
          foodId: 'estimate:day',
          foodName: 'Rough day total',
          grams: 100,
          kcal: v.kcal,
          protein: protein,
          carbs: carbs.toDouble(),
          fat: fat,
          loggedAt: ref.read(clockProvider)(),
        ),
      );
    }
    final prefs = ref.read(prefsProvider);
    await prefs.setStringList('catchupSkipped', {...?prefs.getStringList('catchupSkipped'), ...leaveOut}.toList());
    ref.invalidate(loggedDaysProvider);
    ref.invalidate(openDaysProvider);
    ref.invalidate(usualDayProvider);
    for (final d in fills.keys) {
      ref.invalidate(dayEntriesProvider(d));
    }
  }
}

final catchupActionsProvider = Provider<CatchupActions>(CatchupActions.new);
