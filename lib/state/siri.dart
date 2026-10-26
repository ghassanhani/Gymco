import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/kit/kit.dart' show showVToast;
import '../domain/hydration.dart';
import 'providers.dart';
import 'training_providers.dart';

// Siri reads today's numbers from [siriTodayKey] in the app's preferences
// (the phone's UserDefaults, where shared_preferences keeps keys under
// "flutter.") to answer out loud. What it is asked to do it keeps in its own
// inbox, which the app takes over [_siri] when it runs and carries out. The
// Siri section of ios/Runner/AppDelegate.swift is the other side.

const siriTodayKey = 'siriToday';
const siriQueueKey = 'siriQueue';

/// Today's numbers for Siri: calories and protein left, water so far. Kept up
/// to date whenever any of them changes.
final siriTodayProvider = FutureProvider<void>((ref) async {
  final p = ref.watch(profileProvider);
  if (p == null) return;
  final day = ref.watch(todayKeyProvider);
  final entries = await ref.watch(dayEntriesProvider(day).future);
  final water = ref.watch(waterProvider(day)).ml;
  final goal = ref.watch(waterGoalProvider) ?? waterGoalMl(weightKg: p.weightKg, trained: false);
  double sum(double Function(LogEntry) f) => entries.fold(0, (a, e) => a + f(e));
  await ref
      .read(prefsProvider)
      .setString(
        siriTodayKey,
        jsonEncode({
          'day': day,
          'kcal_left': (p.targetKcal - sum((e) => e.kcal)).round(),
          'protein_left': (p.targets.protein - sum((e) => e.protein)).round(),
          'water_ml': water,
          'water_goal_ml': goal,
        }),
      );
});

const _siri = MethodChannel('gymco/siri');

/// Siri's inbox, emptied. Where there is no native side (Android for now,
/// and tests) requests can wait in the preferences under [siriQueueKey].
Future<String?> _takeQueue(WidgetRef ref) async {
  try {
    return await _siri.invokeMethod<String>('take');
  } on MissingPluginException {
    final prefs = ref.read(prefsProvider);
    final raw = prefs.getString(siriQueueKey);
    if (raw != null) await prefs.remove(siriQueueKey);
    return raw;
  } on PlatformException {
    return null;
  }
}

/// Carries out what Siri was asked while the app was closed or in the
/// background: water, a weigh-in, a meal to write down, today's workout.
Future<void> runSiriQueue(WidgetRef ref, GoRouter router) async {
  // Let the router settle on its first page, or that page would replace ours.
  await WidgetsBinding.instance.endOfFrame;
  final raw = await _takeQueue(ref);
  if (raw == null || raw.isEmpty) return;
  List<Object?> actions;
  try {
    actions = jsonDecode(raw) as List<Object?>;
  } on Object {
    return;
  }
  final today = ref.read(todayKeyProvider);
  for (final a in actions.whereType<Map<String, Object?>>()) {
    // One request that fails doesn't stop the rest.
    try {
      await _run(ref, router, a, today);
    } on Object catch (e) {
      debugPrint('siri: ${a['a']} failed: $e');
    }
  }
}

Future<void> _run(WidgetRef ref, GoRouter router, Map<String, Object?> a, String today) async {
  {
    switch (a['a']) {
      case 'water':
        final ml = (a['ml'] as num?)?.toInt();
        if (ml == null || ml <= 0 || ml > 2000) return;
        await ref.read(waterProvider(today).notifier).add(ml);
        final context = router.routerDelegate.navigatorKey.currentContext;
        if (context != null && context.mounted) showVToast(context, AppLocalizations.of(context).waterAddedMl(ml));
      case 'weight':
        final kg = (a['kg'] as num?)?.toDouble();
        if (kg == null || kg < 25 || kg > 350) return;
        await ref.read(dbProvider).setWeight(today, double.parse(kg.toStringAsFixed(1)));
        ref.invalidate(weighInsProvider);
      case 'food':
        final text = '${a['text'] ?? ''}'.trim();
        final meal = Meal.values.where((m) => m.name == a['meal']).firstOrNull ?? _mealNow(ref);
        router.push(Uri(path: '/add/${meal.name}', queryParameters: {if (text.isNotEmpty) 'text': text}).toString());
      case 'workout':
        await _startToday(ref, router);
      case 'open':
        // Only the app's own top-level places.
        final to = a['to'];
        if (to is String && const ['/today', '/progress', '/train', '/iron/home'].contains(to)) router.go(to);
    }
  }
}

Meal _mealNow(WidgetRef ref) {
  final h = ref.read(clockProvider)().hour;
  return h < 11
      ? Meal.breakfast
      : h < 16
      ? Meal.lunch
      : h < 21
      ? Meal.dinner
      : Meal.snack;
}

/// Today's planned session started, or the Train tab when nothing is planned.
Future<void> _startToday(WidgetRef ref, GoRouter router) async {
  if (ref.read(activeWorkoutProvider) != null) {
    router.push('/workout');
    return;
  }
  final days = await ref.read(weekScheduleProvider.future);
  final planned = days.where((d) => d.today && d.routine != null && d.done == null).firstOrNull?.routine;
  final routine = planned == null
      ? null
      : (await ref.read(routinesProvider.future)).where((r) => r.id == planned.id).firstOrNull;
  if (routine == null) {
    router.go('/train');
    return;
  }
  await ref.read(activeWorkoutProvider.notifier).startRoutine(routine, await ref.read(exerciseLibraryProvider.future));
  router.push('/workout');
}
