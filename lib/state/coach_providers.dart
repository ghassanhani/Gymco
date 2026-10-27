import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/training.dart';
import '../domain/coach.dart';
import 'offline_tips.dart';
import '../domain/energy.dart';
import '../domain/hydration.dart';
import '../domain/iron_rules.dart';
import '../domain/recovery.dart';
import '../domain/remote_config.dart';
import '../domain/routine_ai.dart';
import '../domain/volume.dart';
import '../domain/session.dart';
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

/// A yes/no the user sets once, kept in preferences.
class PrefFlag extends Notifier<bool> {
  PrefFlag(this.key);
  final String key;

  @override
  bool build() => ref.watch(prefsProvider).getBool(key) ?? false;

  Future<void> set(bool on) async {
    await ref.read(prefsProvider).setBool(key, on);
    state = on;
  }
}

/// Iron may read what was eaten and when, not only the totals.
final ironShareFoodProvider = NotifierProvider<PrefFlag, bool>(() => PrefFlag('ironShareFood'));

/// Iron may read the health profile.
final ironShareHealthProvider = NotifierProvider<PrefFlag, bool>(() => PrefFlag('ironShareHealth'));

/// What the user told Iron about their health; null until they fill it in.
final healthProfileProvider = NotifierProvider<HealthProfileNotifier, HealthProfile?>(HealthProfileNotifier.new);

class HealthProfileNotifier extends Notifier<HealthProfile?> {
  static const _k = 'ironHealth';

  @override
  HealthProfile? build() {
    final raw = ref.watch(prefsProvider).getString(_k);
    return raw == null ? null : HealthProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> save(HealthProfile h) async {
    await ref.read(prefsProvider).setString(_k, jsonEncode(h.toJson()));
    state = h;
  }
}

/// What the rules read, from the app's own data. The health profile is read
/// on the phone whether or not it is shared with the AI: warning signs never
/// need the AI.
final ironFactsProvider = FutureProvider<IronFacts?>((ref) async {
  final p = ref.watch(profileProvider);
  if (p == null) return null;
  final db = ref.watch(dbProvider);
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  ref.watch(loggedDaysProvider);
  final totals = await db.dayTotals(dayKey(today.subtract(const Duration(days: 6))), dayKey(today));
  final weighIns = await ref.watch(weighInsProvider.future);
  final trend = trendWeights([for (final w in weighIns) w.$2]);

  var resting = <String, double>{}, sleep = <String, double>{};
  if (ref.watch(healthOnProvider)) {
    final h = ref.read(healthSyncProvider);
    resting = perDay(await h.samples(Metric.restingHr, today.subtract(const Duration(days: 18)), now), sum: false);
    sleep = perDay(await h.samples(Metric.sleep, today.subtract(const Duration(days: 4)), now), sum: true);
  }
  ref.watch(recentWorkoutsProvider);
  final pain = <String, ({PainArea area, bool sharp, String day})>{};
  for (final MapEntry(:key, :value) in painMemory(ref.read(prefsProvider)).entries) {
    if (value is! Map) continue;
    final area = PainArea.values.where((a) => a.name == value['a']).firstOrNull;
    if (area != null && value['day'] is String) {
      pain[key] = (area: area, sharp: value['s'] == true, day: value['day']! as String);
    }
  }
  final routines = await ref.watch(routinesProvider.future);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final workouts = await db.workoutsBetween(monday, today.add(const Duration(days: 1)));
  final water = ref.watch(waterProvider(dayKey(today))).ml;
  return IronFacts(
    now: now,
    profile: p,
    calorieFloor: ref.watch(remoteConfigProvider).calorieFloor,
    restingByDay: resting,
    sleepByDay: sleep,
    dayKcal: {for (final e in totals.entries) e.key: (kcal: e.value.kcal, meals: e.value.meals.length)},
    trend: trend,
    pain: pain,
    health: ref.watch(healthProfileProvider),
    proteinToday: totals[dayKey(today)]?.protein ?? 0,
    waterToday: water,
    waterGoal: ref.watch(waterGoalProvider) ?? waterGoalMl(weightKg: p.weightKg, trained: false),
    planDaysThisWeek: {for (final r in routines) ...r.days},
    trainedDaysThisWeek: {for (final w in workouts) w.startedAt.weekday - 1},
    mealsToday: totals[dayKey(today)]?.meals.length ?? 0,
  );
});

/// What the rules see today.
final ironSignalsProvider = FutureProvider<List<IronSignal>>((ref) async {
  final f = await ref.watch(ironFactsProvider.future);
  return f == null ? const [] : ironSignals(f);
});

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
    'signals': [for (final x in await ref.watch(ironSignalsProvider.future)) x.toJson()],
    if (ref.watch(ironShareFoodProvider)) 'meals_3d': await _recentMeals(ref, today),
    if (ref.watch(ironShareHealthProvider) && ref.watch(healthProfileProvider) != null)
      'health': ref.watch(healthProfileProvider)!.toJson(),
  };
});

/// The last three days of eating, meal by meal: when, what, how much. Only
/// when the user lets Iron read food details.
Future<List<Map<String, Object?>>> _recentMeals(Ref ref, DateTime today) async {
  final db = ref.read(dbProvider);
  final out = <Map<String, Object?>>[];
  for (var d = 0; d < 3; d++) {
    final day = dayKey(today.subtract(Duration(days: d)));
    final byMeal = <Meal, List<LogEntry>>{};
    for (final e in await db.entriesFor(day)) {
      (byMeal[e.meal] ??= []).add(e);
    }
    for (final MapEntry(key: meal, value: items) in byMeal.entries) {
      final at = items
          .map((e) => e.loggedAt)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
      out.add({
        'days_ago': d,
        'meal': meal.name,
        if (at != null) 'time': '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
        'foods': [for (final e in items.take(8)) e.foodName],
        'kcal': items.fold<double>(0, (s, e) => s + e.kcal).round(),
        'protein': items.fold<double>(0, (s, e) => s + e.protein).round(),
      });
    }
  }
  return out;
}

/// The numbers, held open while Iron waits for them: an unwatched provider
/// pauses, so one that rebuilds mid-way (a new warning sign, a logged meal)
/// would otherwise never finish.
Future<Map<String, Object?>?> _numbers(Ref ref) async {
  final sub = ref.listen(coachNumbersProvider, (_, _) {});
  try {
    return await ref.read(coachNumbersProvider.future);
  } finally {
    sub.close();
  }
}

bool _ready(Ref ref) =>
    ref.read(ironOnProvider) &&
    ref.read(remoteConfigProvider).coachAi &&
    (ref.read(accountProvider).value ?? ref.read(cloudProvider).email) != null;

/// Today's tips from Iron, a few to swipe through: asked once a day and
/// kept, so they cost one AI call a day. Empty while Iron is off or signed
/// out. When Iron can't be reached (no connection, switched off, out of
/// requests) the phone makes its own from the numbers, kept for no time.
final ironTipProvider = FutureProvider<List<IronTip>>((ref) async {
  ref.watch(ironOnProvider);
  ref.watch(accountProvider);
  final day = ref.watch(todayKeyProvider);
  final prefs = ref.read(prefsProvider);
  final kept = prefs.getString('ironTips') ?? prefs.getString('ironTip');
  if (kept != null) {
    final j = jsonDecode(kept) as Map<String, Object?>;
    if (j['day'] == day) {
      final tips = IronTip.allFromJson(j, day);
      if (tips.isNotEmpty) return tips;
    }
  }
  final signedIn = (ref.read(accountProvider).value ?? ref.read(cloudProvider).email) != null;
  if (!ref.read(ironOnProvider) || !signedIn) return const [];
  final numbers = await _numbers(ref);
  if (numbers == null) return const [];
  final lang = prefs.getString('lang') ?? 'en';
  List<IronTip> offline() => offlineTips(numbers, languageCode: lang, day: day);
  if (!_ready(ref)) return offline();
  try {
    final (data, _) = await ref
        .read(cloudProvider)
        .askIron(
          mode: 'tip',
          numbers: numbers,
          languageCode: lang,
          bucket: ref.read(installBucketProvider),
        );
    final tips = IronTip.allFromJson(data, day);
    if (tips.isEmpty) return offline();
    if (tips.isNotEmpty) {
      await prefs.setString(
        'ironTips',
        jsonEncode({
          'day': day,
          'tips': [for (final t in tips) t.toJson()],
        }),
      );
    }
    return tips;
  } catch (_) {
    return offline();
  }
});

class IronActions {
  IronActions(this.ref);
  final Ref ref;

  /// Asks Iron for a program; [ask] is anything the user wants it to know.
  Future<IronProgram> program({required String languageCode, String ask = ''}) async {
    final lib = await ref.read(exerciseLibraryProvider.future);
    final numbers = await _numbers(ref);
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
    final p = programFrom(data, lib);
    if (!p.isEmpty) {
      await ref
          .read(ironHistoryProvider.notifier)
          .add(
            IronHistoryEntry(
              kind: IronHistoryEntry.program,
              day: dayKey(ref.read(clockProvider)()),
              title: p.summary,
              data: data,
              ask: ask,
            ),
          );
    }
    return p;
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

/// This week's review from Iron: asked when first opened, then kept for the
/// week. Errors come through so the screen can say what went wrong.
final ironReviewProvider = FutureProvider<IronReview?>((ref) async {
  final now = ref.watch(clockProvider)();
  final week = weekKey(now);
  final prefs = ref.read(prefsProvider);
  final kept = prefs.getString('ironReview');
  if (kept != null) {
    final j = jsonDecode(kept) as Map<String, Object?>;
    if (j['week'] == week) return IronReview.fromJson(j, week);
  }
  final numbers = await _numbers(ref);
  if (numbers == null) return null;
  final (data, _) = await ref
      .read(cloudProvider)
      .askIron(
        mode: 'review',
        numbers: numbers,
        languageCode: prefs.getString('lang') ?? 'en',
        bucket: ref.read(installBucketProvider),
      );
  final review = IronReview.fromJson(data, week);
  if (review != null) {
    await prefs.setString('ironReview', jsonEncode(review.toJson()));
    await ref
        .read(ironHistoryProvider.notifier)
        .add(IronHistoryEntry(kind: IronHistoryEntry.review, day: week, title: review.headline, data: review.toJson()));
  }
  return review;
});

/// Warning signs the user has read and put away, by id, with the day: they
/// come back after three days if the rule still holds.
final ironDismissedProvider = NotifierProvider<IronDismissed, Map<String, String>>(IronDismissed.new);

class IronDismissed extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    try {
      return (jsonDecode(ref.watch(prefsProvider).getString('ironDismissed') ?? '{}') as Map).cast<String, String>();
    } on Object {
      return {};
    }
  }

  Future<void> dismiss(String id) async {
    final next = {...state, id: dayKey(ref.read(clockProvider)())};
    await ref.read(prefsProvider).setString('ironDismissed', jsonEncode(next));
    state = next;
  }

  bool hides(String id, DateTime now) {
    final d = state[id];
    return d != null && now.difference(DateTime.parse(d)).inDays < 3;
  }
}

/// Which of today's tips are done, by their place in the list. Kept for the
/// day only.
final ironTipsDoneProvider = NotifierProvider<IronTipsDone, Set<int>>(IronTipsDone.new);

class IronTipsDone extends Notifier<Set<int>> {
  static const _k = 'ironTipsDone';

  @override
  Set<int> build() {
    final day = ref.watch(todayKeyProvider);
    try {
      final j = jsonDecode(ref.watch(prefsProvider).getString(_k) ?? '{}') as Map<String, Object?>;
      if (j['day'] != day) return {};
      return {for (final i in j['done']! as List) i as int};
    } on Object {
      return {};
    }
  }

  Future<void> set(int i, bool done) async {
    final next = {...state};
    done ? next.add(i) : next.remove(i);
    if (next.length == state.length) return;
    state = next;
    await ref
        .read(prefsProvider)
        .setString(_k, jsonEncode({'day': ref.read(todayKeyProvider), 'done': next.toList()..sort()}));
  }
}

/// The warning signs to show now: red, and not put away in the last three days.
final ironWarningsProvider = Provider<List<IronSignal>>((ref) {
  final now = ref.watch(clockProvider)();
  ref.watch(ironDismissedProvider);
  final dismissed = ref.read(ironDismissedProvider.notifier);
  return [
    for (final s in ref.watch(ironSignalsProvider).value ?? const <IronSignal>[])
      if (s.level == SignalLevel.red && !dismissed.hides(s.id, now)) s,
  ];
});

/// What Iron made, newest first, the last 20.
final ironHistoryProvider = NotifierProvider<IronHistory, List<IronHistoryEntry>>(IronHistory.new);

class IronHistory extends Notifier<List<IronHistoryEntry>> {
  static const _k = 'ironHistory';
  static const _max = 20;

  @override
  List<IronHistoryEntry> build() {
    try {
      return [
        for (final j in (jsonDecode(ref.watch(prefsProvider).getString(_k) ?? '[]') as List))
          ?IronHistoryEntry.fromJson(j),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> add(IronHistoryEntry e) async {
    final next = [e, ...state].take(_max).toList();
    await ref.read(prefsProvider).setString(_k, jsonEncode([for (final x in next) x.toJson()]));
    state = next;
  }
}
