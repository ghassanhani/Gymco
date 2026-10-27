import 'package:flutter/widgets.dart';

import '../domain/coach.dart';
import '../l10n/app_localizations.dart';

/// Today's tips when Iron can't be reached (no connection, the AI paused or
/// out of requests), made on the phone from the same numbers Iron would
/// read. Every number in them is one the app worked out; nothing is guessed.
/// Up to three, each about a different thing, most useful first.
List<IronTip> offlineTips(Map<String, Object?> numbers, {required String languageCode, required String day}) {
  final l = lookupAppLocalizations(Locale(const {'ar', 'es'}.contains(languageCode) ? languageCode : 'en'));
  Map<String, Object?> part(String k) => (numbers[k] as Map?)?.cast<String, Object?>() ?? const {};
  int n(Map<String, Object?> m, String k) => (m[k] as num?)?.round() ?? 0;

  final now = part('now'), targets = part('targets'), today = part('today');
  final hour = n(now, 'hour');
  final meals = (today['meals_logged'] as List?) ?? const [];
  final tips = <IronTip>[];
  void add(String title, String tip, IronAction action) =>
      tips.add(IronTip(day: day, title: title, tip: tip, action: action, offline: true));

  // Eating: over the target, nothing logged yet, or protein still to go.
  final kcalOver = n(today, 'kcal') - n(targets, 'kcal');
  final proteinLeft = n(targets, 'protein') - n(today, 'protein');
  if (kcalOver > 150) {
    add(l.offOverTitle(kcalOver), l.offOverBody, IronAction.walk);
  } else if (meals.isEmpty && hour >= 10) {
    add(l.offFirstMealTitle, l.offFirstMealBody, IronAction.logFood);
  } else if (proteinLeft >= 25 && hour < 22) {
    // Split what's left over the meals the day still has.
    final mealsLeft = hour < 12 ? 3 : (hour < 17 ? 2 : 1);
    final per = ((proteinLeft / mealsLeft) / 5).round() * 5;
    add(l.offProteinTitle(proteinLeft), l.offProteinBody(per.clamp(20, 60)), IronAction.logFood);
  }

  // Training: today's session, or an easy day when recovery is low.
  final recovery = part('recovery');
  final score = recovery['score'] as num?;
  final planned = today['planned_workout'] as String?;
  if (score != null && score < 45) {
    add(l.offRecoveryTitle, l.offRecoveryBody(score.round()), IronAction.rest);
  } else if (planned != null && today['trained'] != true) {
    add(l.offWorkoutTitle(planned), l.offWorkoutBody, IronAction.startWorkout);
  }

  // Water still to drink.
  final waterLeft = n(today, 'water_goal_ml') - n(today, 'water_ml');
  if (waterLeft >= 500 && hour < 22) add(l.offWaterTitle(waterLeft), l.offWaterBody, IronAction.drinkWater);

  // Sleep, then the streak.
  final sleep = recovery['sleep_min'] as num?;
  if (tips.length < 3 && sleep != null && sleep < 390) {
    add(l.offSleepTitle, l.offSleepBody(sleep ~/ 60, (sleep % 60).round()), IronAction.none);
  }
  final streak = n(part('streak'), 'current');
  if (tips.length < 3 && streak >= 2) add(l.offStreakTitle(streak), l.offStreakBody, IronAction.logFood);

  if (tips.isEmpty) add(l.offGeneralTitle, l.offGeneralBody, IronAction.none);
  return tips.take(3).toList();
}
