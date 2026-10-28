import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/reminder_scheduler.dart';
import '../domain/checkin.dart';
import '../domain/energy.dart';
import '../domain/hydration.dart';
import '../domain/notifications.dart';
import '../domain/reminders.dart';
import '../domain/streak.dart';
import '../domain/volume.dart';
import '../l10n/app_localizations.dart';
import 'awards_providers.dart';
import 'cloud_providers.dart';
import 'pack_providers.dart';
import 'progress_providers.dart';
import 'providers.dart';
import 'training_providers.dart';

/// Puts reminders on the phone; tests swap in [NoReminders].
final reminderSchedulerProvider = Provider<ReminderScheduler>((_) => DeviceReminders());

/// The pref behind each switch, and whether it starts on once
/// notifications are allowed.
const _switchKeys = <NoteGroup, (String, bool)>{
  NoteGroup.meals: ('remindMeals', false),
  NoteGroup.protein: ('remindProtein', false),
  NoteGroup.water: ('remindWater', false),
  NoteGroup.workout: ('remindWorkout', false),
  NoteGroup.weighIn: ('remindWeighIn', false),
  NoteGroup.streak: ('remindStreak', true),
  NoteGroup.checkIn: ('remindCheckIn', true),
  NoteGroup.iron: ('remindIron', false),
  NoteGroup.timer: ('remindTimer', true),
  NoteGroup.account: ('remindAccount', true),
};

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _kAllowed = 'notifyAllowed';
  static const _kMealAt = 'remindMealAt', _kWaterAt = 'remindWaterAt', _kWorkoutAt = 'remindWorkoutAt';
  static const _kWeighAt = 'remindWeighAt', _kWeighDays = 'remindWeighDays';
  static const _kQuietFrom = 'quietFrom', _kQuietTo = 'quietTo';
  static const _meals = [ReminderKind.breakfast, ReminderKind.lunch, ReminderKind.dinner];

  @override
  ReminderSettings build() {
    final p = ref.watch(prefsProvider);
    List<ClockTime>? times(String key, int n) {
      final list = [for (final x in p.getStringList(key) ?? const <String>[]) decodeClock(x)];
      return list.length == n && list.every((t) => t != null) ? list.cast<ClockTime>() : null;
    }

    final on = {
      for (final MapEntry(key: g, value: (key, byDefault)) in _switchKeys.entries)
        if (p.getBool(key) ?? byDefault) g,
    };
    final meals = times(_kMealAt, 3);
    return ReminderSettings(
      on: on,
      // Phones that turned a reminder on before this flag existed.
      allowed:
          p.getBool(_kAllowed) ??
          [NoteGroup.meals, NoteGroup.water, NoteGroup.workout].any((g) => p.getBool(_switchKeys[g]!.$1) ?? false),
      mealAt: meals == null ? null : {for (final (i, k) in _meals.indexed) k: meals[i]},
      waterAt: times(_kWaterAt, 3) ?? waterTimes,
      workoutAt: decodeClock(p.getString(_kWorkoutAt)),
      weighAt: decodeClock(p.getString(_kWeighAt)) ?? (7, 30),
      weighDays: {
        for (final d in p.getStringList(_kWeighDays) ?? const ['0', '3']) ?int.tryParse(d),
      },
      quietFrom: decodeClock(p.getString(_kQuietFrom)) ?? (23, 0),
      quietTo: decodeClock(p.getString(_kQuietTo)) ?? (7, 0),
    );
  }

  /// Turns one on (asking for permission the first time) or off. False
  /// when the phone said no.
  Future<bool> set(NoteGroup g, bool on) async {
    final p = ref.read(prefsProvider);
    if (on && !state.allowed) {
      if (!await ref.read(reminderSchedulerProvider).requestPermission()) return false;
      await p.setBool(_kAllowed, true);
    }
    await p.setBool(_switchKeys[g]!.$1, on);
    if (on) await p.setString('remindSince.${g.name}', dayKey(ref.read(clockProvider)()));
    state = state.copyWith(on: on ? {...state.on, g} : ({...state.on}..remove(g)), allowed: state.allowed || on);
    return true;
  }

  /// Moves one time: a meal by kind, a water nudge by [index].
  Future<void> setTime(
    ReminderKind kind,
    ClockTime t, {
    int index = 0,
    required Map<ReminderKind, ClockTime> meals,
  }) async {
    final p = ref.read(prefsProvider);
    switch (kind) {
      case ReminderKind.water:
        final list = [...state.waterAt]..[index] = t;
        await p.setStringList(_kWaterAt, [for (final x in list) encodeClock(x)]);
        state = state.copyWith(waterAt: list);
      case ReminderKind.workout:
        await p.setString(_kWorkoutAt, encodeClock(t));
        state = state.copyWith(workoutAt: t);
      case _:
        final map = {...meals, kind: t};
        await p.setStringList(_kMealAt, [for (final k in _meals) encodeClock(map[k]!)]);
        state = state.copyWith(mealAt: map);
    }
  }

  Future<void> setWeighAt(ClockTime t) async {
    await ref.read(prefsProvider).setString(_kWeighAt, encodeClock(t));
    state = state.copyWith(weighAt: t);
  }

  Future<void> toggleWeighDay(int weekday) async {
    final days = {...state.weighDays};
    if (!days.remove(weekday)) days.add(weekday);
    if (days.isEmpty) return;
    await ref.read(prefsProvider).setStringList(_kWeighDays, [for (final d in days.toList()..sort()) '$d']);
    state = state.copyWith(weighDays: days);
  }

  Future<void> setQuiet({ClockTime? from, ClockTime? to}) async {
    final p = ref.read(prefsProvider);
    if (from != null) await p.setString(_kQuietFrom, encodeClock(from));
    if (to != null) await p.setString(_kQuietTo, encodeClock(to));
    state = state.copyWith(quietFrom: from, quietTo: to);
  }
}

final reminderSettingsProvider = NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  ReminderSettingsNotifier.new,
);

/// The phone's region: meal hours, the weekend and the check-in day follow it.
final regionProvider = Provider<Region>((ref) {
  final locale = PlatformDispatcher.instance.locale;
  return regionOf(locale.countryCode, ref.watch(settingsProvider).languageCode ?? locale.languageCode);
});

/// The meal times reminders go 45 minutes after: as set, or the region's.
final mealTimesProvider = Provider<Map<ReminderKind, ClockTime>>(
  (ref) => ref.watch(reminderSettingsProvider).mealAt ?? regionMealTimes(ref.watch(regionProvider)),
);

/// When workouts usually start: as set, or the middle of the last ten.
final usualTrainingProvider = Provider<ClockTime>((ref) {
  final set = ref.watch(reminderSettingsProvider).workoutAt;
  if (set != null) return set;
  final recent = ref.watch(recentWorkoutsProvider).value ?? const [];
  final mins = [for (final w in recent.take(10)) w.startedAt.hour * 60 + w.startedAt.minute]..sort();
  if (mins.length < 3) return workoutTime;
  final m = mins[mins.length ~/ 2];
  // To the quarter hour.
  final q = (m / 15).round() * 15;
  return ((q ~/ 60) % 24, q % 60);
});

AppLocalizations _l(Ref ref) {
  final code = ref.watch(settingsProvider).languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(
    Locale(AppLocalizations.supportedLocales.any((x) => x.languageCode == code) ? code : 'en'),
  );
}

/// Each switch as the planner reads it.
NoteSwitches _switches(ReminderSettings s, Map<ReminderKind, ClockTime> meals) => NoteSwitches(
  meals: s.isOn(NoteGroup.meals),
  protein: s.isOn(NoteGroup.protein),
  water: s.isOn(NoteGroup.water),
  workout: s.isOn(NoteGroup.workout),
  weighIn: s.isOn(NoteGroup.weighIn),
  streak: s.isOn(NoteGroup.streak),
  checkIn: s.isOn(NoteGroup.checkIn),
  iron: s.isOn(NoteGroup.iron),
  account: s.isOn(NoteGroup.account),
  mealAt: meals,
  waterAt: s.waterAt,
  weighAt: s.weighAt,
  weighDays: s.weighDays,
  quietFrom: s.quietFrom,
  quietTo: s.quietTo,
);

/// Keeps what is scheduled in step with the day: rebuilt whenever food,
/// water, workouts or the settings change, and when the app comes back.
final reminderSyncProvider = FutureProvider<void>((ref) async {
  final settings = ref.watch(reminderSettingsProvider);
  final scheduler = ref.watch(reminderSchedulerProvider);
  final profile = ref.watch(profileProvider);
  if (!settings.any || profile == null) return scheduler.replaceAll(const []);

  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final day = ref.watch(todayKeyProvider);
  final db = ref.watch(dbProvider);
  final prefs = ref.watch(prefsProvider);
  final region = ref.watch(regionProvider);
  final meals = ref.watch(mealTimesProvider);
  final entries = await ref.watch(dayEntriesProvider(day).future);
  final water = ref.watch(waterProvider(day)).ml;
  final routines = await ref.watch(routinesProvider.future);
  final workouts = await ref.watch(recentWorkoutsProvider.future);
  final trained = workouts.any((w) => dayKey(w.startedAt) == day);
  final goal = ref.watch(waterGoalProvider) ?? waterGoalMl(weightKg: profile.weightKg, trained: trained);
  final weighIns = await ref.watch(weighInsProvider.future);
  final streak = await ref.watch(streakProvider.future);
  final week = await ref.watch(weekScheduleProvider.future);
  final logged = await ref.watch(loggedDaysProvider.future);
  CheckIn? checkIn;
  try {
    checkIn = await ref.watch(checkInProvider.future);
  } catch (_) {}

  // The routine each day ahead holds, and where it slides if skipped.
  final byId = {for (final r in routines) r.id: r};
  final ahead = [
    for (final d in week)
      if (!d.date.isBefore(today)) d,
  ];
  final plan = <int, PlanDay>{};
  final movesTo = <int, int>{};
  for (final (i, d) in ahead.indexed) {
    final r = d.routine;
    if (r == null) continue;
    final offset = d.date.difference(today).inDays;
    final items = byId[r.id]?.items ?? const [];
    plan[offset] = PlanDay(
      name: r.name,
      exercises: items.length,
      minutes: planMinutes([for (final it in items) (it.sets, it.restSeconds)]),
    );
    final free = ahead.skip(i + 1).where((x) => x.routine == null).firstOrNull;
    movesTo[offset] = (free?.date ?? d.date.add(const Duration(days: 1))).weekday - 1;
  }

  // Rest days already behind us this week, for Iron's two tips a week.
  final planDays = {for (final r in routines) ...r.days};
  final restBefore = [
    for (var wd = 0; wd < today.weekday - 1; wd++)
      if (!planDays.contains(wd)) wd,
  ].length;

  String? tip;
  if (prefs.getString('ironTips') case final kept?) {
    final j = jsonDecode(kept) as Map<String, Object?>;
    final tips = j['tips'];
    if (j['day'] == day && tips is List && tips.isNotEmpty && tips.first is Map) {
      tip = '${(tips.first as Map)['tip'] ?? ''}'.trim();
      if (tip.isEmpty) tip = null;
    }
  }

  final packs = ref.watch(packsProvider);
  final challenge = packs.challengeFor(now);
  final monthCount = (await db.workoutCounts(DateTime(now.year, now.month))).sinceMonth;
  final marks = streak?.state.marks ?? const <DateTime, DayMark>{};
  final yesterday = today.subtract(const Duration(days: 1));
  final lastLogged = logged.isEmpty ? null : DateTime.parse((logged.toList()..sort()).last);
  final totalsToday = (await db.dayTotals(day, day))[day];

  final facts = NoteFacts(
    now: now,
    region: region,
    mealsLoggedToday: {
      for (final e in entries)
        ?switch (e.meal) {
          Meal.breakfast => ReminderKind.breakfast,
          Meal.lunch => ReminderKind.lunch,
          Meal.dinner => ReminderKind.dinner,
          Meal.snack => null,
        },
    },
    proteinToday: totalsToday?.protein ?? 0,
    proteinTarget: profile.targets.protein,
    waterToday: water,
    waterGoal: goal,
    trainedToday: trained,
    weighedToday: weighIns.isNotEmpty && weighIns.last.$1 == day,
    keptToday: streak?.keptToday ?? false,
    streak: streak?.state.current ?? 0,
    yesterdayFrozen: marks[yesterday] == DayMark.frozen,
    freezesLeft: streak?.state.freezes ?? 0,
    canRepair: streak?.state.canRepair ?? false,
    plan: plan,
    movesTo: movesTo,
    usualTraining: ref.watch(usualTrainingProvider),
    checkInTarget: checkIn?.nextKcal.round(),
    checkInStall: checkIn?.kind == CheckInKind.stall,
    checkInFast: checkIn?.kind == CheckInKind.fast,
    ironTipToday: tip,
    restDaysBeforeToday: restBefore,
    challengeTarget: challenge?.target ?? 12,
    workoutsThisMonth: monthCount,
    lastLogged: lastLogged,
    lastBackup: ref.watch(lastBackupProvider),
    signedIn: (ref.watch(accountProvider).value ?? ref.watch(cloudProvider).email) != null,
    backedOff: await _backedOff(ref, settings, meals, today, routines.isNotEmpty),
  );

  final notes = planNotes(facts, _switches(settings, meals));
  final l = _l(ref);
  await scheduler.replaceAll([
    for (final n in notes)
      _words(n, l, sex: profile.sex, month: now, challengeTitle: challenge?.title.of(l.localeName)),
  ]);
});

/// The workout timer's two notes, kept apart from the day's plan so a
/// ticked set does not reschedule the week.
final workoutTimerSyncProvider = FutureProvider<void>((ref) async {
  final settings = ref.watch(reminderSettingsProvider);
  final scheduler = ref.watch(reminderSchedulerProvider);
  final session = ref.watch(activeWorkoutProvider);
  final profile = ref.watch(profileProvider);
  if (!settings.allowed || !settings.isOn(NoteGroup.timer) || session == null || profile == null) {
    return scheduler.replaceTimer(const []);
  }
  final now = ref.watch(clockProvider)();
  DateTime? restEnds;
  String? exercise;
  int? set;
  if (session.restStartedAt case final start? when (session.restSeconds ?? 0) > 0) {
    restEnds = start.add(Duration(seconds: session.restSeconds!));
    for (final e in session.exercises) {
      final i = e.sets.indexWhere((s) => !s.done);
      if (i >= 0) {
        exercise = e.name;
        set = i + 1;
        break;
      }
    }
  }
  final notes = planNotes(
    NoteFacts(
      now: now,
      region: ref.watch(regionProvider),
      restEndsAt: restEnds,
      restExercise: exercise,
      restSet: set,
      workoutActiveAt: session.lastActive,
    ),
    NoteSwitches(timer: true, quietFrom: settings.quietFrom, quietTo: settings.quietTo),
  );
  final l = _l(ref);
  await scheduler.replaceTimer([for (final n in notes) _words(n, l, sex: profile.sex, month: now)]);
});

/// Reminders left unanswered on each of the last 5 days they were due.
Future<Set<NoteKind>> _backedOff(
  Ref ref,
  ReminderSettings s,
  Map<ReminderKind, ClockTime> meals,
  DateTime today,
  bool hasPlan,
) async {
  final prefs = ref.read(prefsProvider);
  final db = ref.read(dbProvider);
  final from = today.subtract(const Duration(days: 5));
  final totals = await db.dayTotals(dayKey(from), dayKey(today.subtract(const Duration(days: 1))));
  final workouts = await db.workoutsBetween(from, today);
  final trainedDays = {for (final w in workouts) dayKey(w.startedAt)};
  final weighDays = {for (final w in await db.weighIns()) w.$1};
  final ignored = <NoteKind, List<bool>>{};
  for (var i = 1; i <= 5; i++) {
    final d = today.subtract(Duration(days: i));
    final k = dayKey(d);
    bool since(NoteGroup g) {
      final on = prefs.getString('remindSince.${g.name}');
      return on != null && on.compareTo(k) <= 0;
    }

    void mark(NoteKind kind, bool done) => (ignored[kind] ??= []).add(!done);
    if (s.meals && since(NoteGroup.meals)) {
      final logged = totals[k]?.meals ?? const <Meal>{};
      mark(NoteKind.breakfast, logged.contains(Meal.breakfast));
      mark(NoteKind.lunch, logged.contains(Meal.lunch));
      mark(NoteKind.dinner, logged.contains(Meal.dinner));
    }
    if (s.water && since(NoteGroup.water)) {
      final goal = ref.read(waterGoalProvider) ?? 2000;
      mark(NoteKind.water, ref.read(waterProvider(k)).ml >= goal * 0.8);
    }
    if (s.workout && hasPlan && since(NoteGroup.workout)) mark(NoteKind.workout, trainedDays.contains(k));
    if (s.isOn(NoteGroup.weighIn) && s.weighDays.contains(d.weekday - 1) && since(NoteGroup.weighIn)) {
      mark(NoteKind.weighIn, weighDays.contains(k));
    }
  }
  return backedOffKinds(ignored);
}

/// What a note says, in the app's language.
ReminderNote _words(Note n, AppLocalizations l, {required Sex sex, required DateTime month, String? challengeTitle}) {
  final x = sex.name;
  final lang = l.localeName;
  final count = NumberFormat.decimalPattern(lang == 'ar' ? 'en' : lang);
  String weekday(int wd) => DateFormat.EEEE(lang).format(DateTime(2024, 1, 1 + wd));
  final d = n.data;
  final (title, body) = switch (n.kind) {
    NoteKind.breakfast => (l.nBreakfastT, l.nBreakfastB(x)),
    NoteKind.lunch => (l.nLunchT, l.nLunchB(x)),
    NoteKind.dinner => (l.nDinnerT, l.nDinnerB(x)),
    NoteKind.protein => (l.nProteinT, l.nProteinB('${d['grams']}')),
    NoteKind.water => (
      l.nWaterT,
      l.nWaterB(NumberFormat('0.0', lang == 'ar' ? 'en' : lang).format((d['ml'] as int) / 1000)),
    ),
    NoteKind.workout => (l.nWorkoutT('${d['routine']}'), l.nWorkoutB('${d['exercises']}', '${d['minutes']}')),
    NoteKind.sessionMoved => (l.nMovedT('${d['routine']}'), l.nMovedB(x, '${d['routine']}', weekday(d['to'] as int))),
    NoteKind.weighIn => (l.nWeighT, l.nWeighB),
    NoteKind.restOver => (
      l.nRestT,
      d['exercise'] == null ? l.nRestPlainB(x) : l.nRestB('${d['set']}', '${d['exercise']}'),
    ),
    NoteKind.workoutOpen => (l.nOpenT, l.nOpenB(x)),
    NoteKind.streakRisk =>
      d['days'] == null
          ? (l.nStreakPlainT, l.nStreakPlainB(x))
          : (l.nStreakT('${d['days']}'), l.nStreakB(x, '${d['days']}')),
    NoteKind.freezeUsed => (l.nFreezeT, l.nFreezeB(d['left'] as int)),
    NoteKind.streakRepair => (l.nRepairT, l.nRepairB(x)),
    NoteKind.challengeNew => (
      challengeTitle != null ? '🏆 $challengeTitle' : l.nChallengeT(DateFormat.MMMM(lang).format(n.at)),
      l.nChallengeB(x, '${d['target']}'),
    ),
    NoteKind.challengeNear => (l.nNearT(x), l.nNearB(x)),
    NoteKind.checkIn => (
      l.nCheckInT,
      d['stall'] != null
          ? l.nStallB(x, '${d['stall']}')
          : d['fast'] != null
          ? l.nFastB(x)
          : d['target'] != null
          ? l.nCheckInB(count.format(d['target']))
          : l.nCheckInPlainB,
    ),
    NoteKind.ironTip => (l.nIronT, _clip('${d['tip']}', 110)),
    NoteKind.welcomeBack => (l.nBackT, l.nBackB(x)),
    NoteKind.backup => (l.nBackupT, l.nBackupB(x)),
  };
  return (id: n.id, at: n.at, title: title, body: body, urgent: n.kind == NoteKind.restOver);
}

String _clip(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1).trimRight()}…';
