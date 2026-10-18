import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/reminder_scheduler.dart';
import '../domain/hydration.dart';
import '../domain/reminders.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'training_providers.dart';

/// Puts reminders on the phone; tests swap in [NoReminders].
final reminderSchedulerProvider = Provider<ReminderScheduler>((_) => DeviceReminders());

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _kMeals = 'remindMeals', _kWater = 'remindWater', _kWorkout = 'remindWorkout';

  @override
  ReminderSettings build() {
    final p = ref.watch(prefsProvider);
    return ReminderSettings(
      meals: p.getBool(_kMeals) ?? false,
      water: p.getBool(_kWater) ?? false,
      workout: p.getBool(_kWorkout) ?? false,
    );
  }

  /// Turns one on (asking for permission first) or off. False when the
  /// phone said no.
  Future<bool> set(ReminderKind kind, bool on) async {
    if (on && !await ref.read(reminderSchedulerProvider).requestPermission()) return false;
    final p = ref.read(prefsProvider);
    switch (kind) {
      case ReminderKind.water:
        await p.setBool(_kWater, on);
        state = ReminderSettings(meals: state.meals, water: on, workout: state.workout);
      case ReminderKind.workout:
        await p.setBool(_kWorkout, on);
        state = ReminderSettings(meals: state.meals, water: state.water, workout: on);
      case _:
        await p.setBool(_kMeals, on);
        state = ReminderSettings(meals: on, water: state.water, workout: state.workout);
    }
    return true;
  }
}

final reminderSettingsProvider = NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  ReminderSettingsNotifier.new,
);

/// Keeps what is scheduled in step with the day: rebuilt whenever food,
/// water, workouts or the settings change, and when the app comes back.
final reminderSyncProvider = FutureProvider<void>((ref) async {
  final settings = ref.watch(reminderSettingsProvider);
  final scheduler = ref.watch(reminderSchedulerProvider);
  final profile = ref.watch(profileProvider);
  if (!settings.any || profile == null) return scheduler.replaceAll(const []);

  final now = ref.watch(clockProvider)();
  final day = ref.watch(todayKeyProvider);
  final entries = await ref.watch(dayEntriesProvider(day).future);
  final water = ref.watch(waterProvider(day)).ml;
  final routines = await ref.watch(routinesProvider.future);
  final workouts = await ref.watch(recentWorkoutsProvider.future);
  final trained = workouts.any((w) => dayKey(w.startedAt) == day);
  final goal = ref.watch(waterGoalProvider) ?? waterGoalMl(weightKg: profile.weightKg, trained: trained);

  final plan = planReminders(
    now: now,
    settings: settings,
    mealsLoggedToday: {
      for (final e in entries)
        ?switch (e.meal) {
          Meal.breakfast => ReminderKind.breakfast,
          Meal.lunch => ReminderKind.lunch,
          Meal.dinner => ReminderKind.dinner,
          Meal.snack => null,
        },
    },
    waterMlToday: water,
    waterGoalMl: goal,
    trainedToday: trained,
    planByWeekday: {
      for (final r in routines)
        if (r.weekday != null) r.weekday!: r.name,
    },
  );

  final code = ref.watch(settingsProvider).languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  final l = lookupAppLocalizations(
    Locale(AppLocalizations.supportedLocales.any((x) => x.languageCode == code) ? code : 'en'),
  );
  final litres = (goal / 1000).toStringAsFixed(1);
  await scheduler.replaceAll([
    for (final r in plan)
      (
        id: r.id,
        at: r.at,
        title: switch (r.kind) {
          ReminderKind.breakfast => l.remindBreakfastTitle,
          ReminderKind.lunch => l.remindLunchTitle,
          ReminderKind.dinner => l.remindDinnerTitle,
          ReminderKind.water => l.remindWaterTitle,
          ReminderKind.workout => l.remindWorkoutTitle(r.routine ?? ''),
        },
        body: switch (r.kind) {
          ReminderKind.water => l.remindWaterBody(litres),
          ReminderKind.workout => l.remindWorkoutBody,
          _ => l.remindMealBody,
        },
      ),
  ]);
});
