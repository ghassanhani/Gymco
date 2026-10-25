import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/training.dart';
import '../domain/coach.dart';
import '../domain/energy.dart';
import '../domain/hydration.dart';
import '../domain/remote_config.dart';
import '../domain/routine_ai.dart';
import '../domain/volume.dart';
import '../domain/workout.dart';
import 'awards_providers.dart';
import 'cloud_providers.dart';
import 'config_providers.dart';
import 'health_providers.dart';
import 'providers.dart';
import 'training_providers.dart';

/// Whether the user has turned Iron on: it reads their numbers, so it asks first.
final ironOnProvider = NotifierProvider<IronOn, bool>(IronOn.new);

class IronOn extends Notifier<bool> {
  @override
  bool build() => ref.watch(prefsProvider).getBool('ironOn') ?? false;

  Future<void> set(bool on) async {
    await ref.read(prefsProvider).setBool('ironOn', on);
    state = on;
  }
}

/// A summary of the user's numbers for Iron: targets, the last two weeks of
/// eating and training, today so far, streak, weight trend and, when a watch
/// is connected, recovery and steps. No food names, notes or photos.
final coachNumbersProvider = FutureProvider<Map<String, Object?>?>((ref) async {
  final p = ref.watch(profileProvider);
  if (p == null) return null;
  final db = ref.watch(dbProvider);
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final from = today.subtract(const Duration(days: 13));
  ref.watch(loggedDaysProvider);

  final totals = await db.dayTotals(dayKey(from), dayKey(today));
  final past = {
    for (final e in totals.entries)
      if (e.key != dayKey(today)) e.key: e.value,
  };
  final todayTotals = totals[dayKey(today)];
  double avg(Iterable<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

  final weighIns = await ref.watch(weighInsProvider.future);
  final trend = trendWeights([for (final w in weighIns) w.$2]);
  final workouts = await db.workoutsBetween(from, today.add(const Duration(days: 1)));
  final routines = await ref.watch(routinesProvider.future);
  final lib = await ref.watch(exerciseLibraryProvider.future);
  final week = await ref.watch(setsThisWeekProvider.future);
  final hard = <String, double>{};
  for (final s in week) {
    final g = groupOf(lib[s.exerciseId]?.primary.firstOrNull ?? '');
    if (g != null) hard[g.name] = (hard[g.name] ?? 0) + s.type.hardSetWeight;
  }
  final streak = await ref.watch(streakProvider.future);
  final recovery = ref.watch(recoveryProvider).value;
  final steps = ref.watch(stepsWeekProvider).value;
  final water = ref.watch(waterProvider(dayKey(today))).ml;
  final rc = ref.watch(remoteConfigProvider);
  final trained = workouts.any((w) => dayKey(w.startedAt) == dayKey(today));
  final planned = routines.where((r) => r.days.contains(today.weekday - 1)).firstOrNull;

  return {
    'now': {'weekday': today.weekday - 1, 'hour': now.hour, 'days_in_app': today.difference(p.startedOn).inDays + 1},
    'profile': {
      'goal': p.goal.name,
      'sex': p.sex.name,
      'age': p.ageYears,
      'height_cm': p.heightCm.round(),
      'weight_kg': double.parse(p.weightKg.toStringAsFixed(1)),
      'activity': p.activity.name,
      'target_rate_pct_week': p.ratePctPerWeek,
    },
    'targets': {
      'kcal': p.targetKcal.round(),
      'protein': p.targets.protein.round(),
      'carbs': p.targets.carbs.round(),
      'fat': p.targets.fat.round(),
      'calorie_floor': rc.calorieFloor.round(),
    },
    if (trend.length >= 7)
      'weight': {
        'trend_kg': double.parse(trend.last.toStringAsFixed(1)),
        'rate_pct_week': double.parse(
          observedRatePctPerWeek(fromKg: trend[trend.length - 7], toKg: trend.last, days: 7).toStringAsFixed(2),
        ),
        'weigh_ins_14d': weighIns.where((w) => !DateTime.parse(w.$1).isBefore(from)).length,
      },
    'eating_14d': {
      'days_logged': past.length,
      'avg_kcal': avg(past.values.map((t) => t.kcal)).round(),
      'avg_protein': avg(past.values.map((t) => t.protein)).round(),
      'full_days': past.values.where((t) => t.meals.length >= 3).length,
    },
    'today': {
      'kcal': (todayTotals?.kcal ?? 0).round(),
      'protein': (todayTotals?.protein ?? 0).round(),
      'meals_logged': [for (final m in todayTotals?.meals ?? const <Meal>{}) m.name],
      'water_ml': water,
      'water_goal_ml':
          ref.watch(waterGoalProvider) ?? waterGoalMl(weightKg: p.weightKg, trained: trained || planned != null),
      'trained': trained,
      'planned_workout': ?planned?.name,
    },
    'training': {
      'workouts_14d': workouts.length,
      'avg_minutes': workouts.isEmpty
          ? 0
          : avg([for (final w in workouts) w.endedAt.difference(w.startedAt).inMinutes.toDouble()]).round(),
      'plan': [
        for (final r in routines)
          if (r.days.isNotEmpty) {'name': r.name, 'days': (r.days.toList()..sort()), 'sets': r.totalSets},
      ],
      'hard_sets_this_week': {for (final e in hard.entries) e.key: e.value.round()},
      'target_hard_sets_per_muscle': '$volumeLow-$volumeHigh',
    },
    if (streak != null) 'streak': {'current': streak.state.current, 'best': streak.state.best},
    if (recovery != null && recovery.hasBody)
      'recovery': {
        'score': ?recovery.score,
        'sleep_min': ?recovery.sleepMin,
        'resting_hr': ?recovery.restingHr?.round(),
        'hrv_ms': ?recovery.hrv?.round(),
      },
    if (steps != null && steps.last != null) 'steps': {'today': steps.last!.round()},
  };
});

bool _ready(Ref ref) =>
    ref.read(ironOnProvider) &&
    ref.read(remoteConfigProvider).coachAi &&
    (ref.read(accountProvider).value ?? ref.read(cloudProvider).email) != null;

/// Today's tip from Iron: asked once a day and kept, so it costs one AI call
/// a day. Null while Iron is off, signed out or switched off, or on failure.
final ironTipProvider = FutureProvider<IronTip?>((ref) async {
  ref.watch(ironOnProvider);
  ref.watch(accountProvider);
  final day = ref.watch(todayKeyProvider);
  final prefs = ref.read(prefsProvider);
  final kept = prefs.getString('ironTip');
  if (kept != null) {
    final t = IronTip.stored(jsonDecode(kept) as Map<String, Object?>);
    if (t != null && t.day == day) return t;
  }
  if (!_ready(ref)) return null;
  final numbers = await ref.read(coachNumbersProvider.future);
  if (numbers == null) return null;
  try {
    final (data, _) = await ref
        .read(cloudProvider)
        .askIron(
          mode: 'tip',
          numbers: numbers,
          languageCode: prefs.getString('lang') ?? 'en',
          bucket: ref.read(installBucketProvider),
        );
    final tip = IronTip.fromJson(data, day);
    if (tip != null) await prefs.setString('ironTip', jsonEncode(tip.toJson()));
    return tip;
  } catch (_) {
    return null;
  }
});

class IronActions {
  IronActions(this.ref);
  final Ref ref;

  /// Asks Iron for a program; [ask] is anything the user wants it to know.
  Future<IronProgram> program({required String languageCode, String ask = ''}) async {
    final lib = await ref.read(exerciseLibraryProvider.future);
    final numbers = await ref.read(coachNumbersProvider.future);
    final (data, _) = await ref
        .read(cloudProvider)
        .askIron(
          mode: 'program',
          numbers: numbers ?? const {},
          languageCode: languageCode,
          exercises: plannableNames(lib),
          ask: ask,
          bucket: ref.read(installBucketProvider),
        );
    return programFrom(data, lib);
  }

  /// Puts the program in place: the new targets, held to the check-in's
  /// safety rules, and its routines as the weekly plan. The old plan's
  /// routines move to My routines rather than being deleted. Returns whether
  /// the targets were held back from Iron's numbers.
  Future<bool> apply(IronProgram p) async {
    var held = false;
    final profile = ref.read(profileProvider);
    if (profile != null && p.kcal > 0) {
      final rc = RemoteConfig.current;
      final (kcal, macros, clamped) = safeTargets(
        current: profile.targetKcal,
        p: p,
        floor: rc.calorieFloor,
        maxChange: rc.maxWeeklyChange,
        weightKg: profile.weightKg,
      );
      held = clamped;
      await ref.read(profileProvider.notifier).save(profile.withTargets(kcal, macros));
    }
    final actions = ref.read(routineActionsProvider);
    if (p.plan.routines.any((r) => r.days.isNotEmpty)) {
      for (final r in await ref.read(routinesProvider.future)) {
        if (r.folder == RoutineFolder.plan) {
          await actions.save(r.copyWith(days: const {}, folder: RoutineFolder.mine));
        }
      }
    }
    for (final r in p.plan.routines) {
      await actions.save(r.copyWith(name: await actions.freeName(r.name)));
    }
    return held;
  }
}

final ironActionsProvider = Provider<IronActions>(IronActions.new);

/// The user closed Iron's invitation on Today: it stays away until they
/// turn Iron on from its own screen.
final ironHiddenProvider = NotifierProvider<IronHidden, bool>(IronHidden.new);

class IronHidden extends Notifier<bool> {
  @override
  bool build() => ref.watch(prefsProvider).getBool('ironHidden') ?? false;

  Future<void> hide() async {
    await ref.read(prefsProvider).setBool('ironHidden', true);
    state = true;
  }
}
