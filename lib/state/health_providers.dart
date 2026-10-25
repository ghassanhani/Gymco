import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../domain/recovery.dart';
import 'providers.dart';

/// Connects the health store, or disconnects. False when the phone said no.
Future<bool> setHealth(WidgetRef ref, bool on) async {
  if (on && !await ref.read(healthSyncProvider).connect()) return false;
  await ref.read(healthOnProvider.notifier).set(on);
  if (on) {
    await ref.read(watchReadsAskedProvider.notifier).done();
    refreshHealth(ref);
  }
  return true;
}

/// Brings in the scale's weigh-ins from the last 30 days, for days that
/// have none of Gymco's own. Run on connecting and on each return to the app.
final healthImportProvider = FutureProvider<int>((ref) async {
  if (!ref.watch(healthOnProvider)) return 0;
  final db = ref.read(dbProvider);
  final now = ref.read(clockProvider)();
  final have = {for (final (day, _) in await db.weighIns()) day};
  final byDay = <String, double>{};
  for (final (at, kg) in await ref.read(healthSyncProvider).weights(now.subtract(const Duration(days: 30)))) {
    // The latest reading of a day stands for it.
    byDay[dayKey(at)] = kg;
  }
  var added = 0;
  for (final MapEntry(key: day, value: kg) in byDay.entries) {
    if (have.contains(day) || kg < 25 || kg > 350) continue;
    await db.setWeight(day, double.parse(kg.toStringAsFixed(1)));
    added++;
  }
  if (added > 0) ref.invalidate(weighInsProvider);
  return added;
});

/// Today's steps from the health store, or null when not connected.
final stepsTodayProvider = FutureProvider<int?>((ref) async {
  if (!ref.watch(healthOnProvider)) return null;
  return ref.read(healthSyncProvider).stepsToday(ref.read(clockProvider)());
});

/// Whether Gymco has asked for the watch reads (sleep, heart rate, active
/// energy, workouts). People who connected before they existed are asked
/// once, from the Recovery card.
final watchReadsAskedProvider = NotifierProvider<WatchReadsAsked, bool>(WatchReadsAsked.new);

class WatchReadsAsked extends Notifier<bool> {
  @override
  bool build() => ref.read(prefsProvider).getBool('healthWatchReads') ?? false;

  Future<void> done() async {
    await ref.read(prefsProvider).setBool('healthWatchReads', true);
    state = true;
  }
}

/// Asks the phone again, now for the watch reads too.
Future<void> askWatchReads(WidgetRef ref) async {
  await ref.read(healthSyncProvider).connect();
  await ref.read(watchReadsAskedProvider.notifier).done();
  refreshHealth(ref);
}

/// Everything read from the health store, read again: on return to the app
/// and after the phone's permission screen.
void refreshHealth(WidgetRef ref) {
  ref.invalidate(healthImportProvider);
  ref.invalidate(stepsTodayProvider);
  ref.invalidate(stepsWeekProvider);
  ref.invalidate(recoveryProvider);
  ref.invalidate(watchWorkoutDaysProvider);
  ref.invalidate(workoutHeartProvider);
}

/// Today's sleep, resting heart rate, HRV and active energy next to the last
/// two weeks, and any watch workouts today. Null when not connected.
final recoveryProvider = FutureProvider<Recovery?>((ref) async {
  if (!ref.watch(healthOnProvider)) return null;
  final h = ref.read(healthSyncProvider);
  final now = ref.read(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final from = today.subtract(const Duration(days: 15));
  // Last night starts the evening before.
  final reads = await Future.wait([
    h.samples(Metric.sleep, from.subtract(const Duration(hours: 6)), now),
    h.samples(Metric.restingHr, from, now),
    h.samples(Metric.hrv, from, now),
    h.samples(Metric.activeKcal, today.subtract(const Duration(days: 6)), now),
  ]);
  return recoveryFrom(
    now: now,
    sleep: reads[0],
    restingHr: reads[1],
    hrv: reads[2],
    activeKcal: reads[3],
    workouts: await h.workouts(today, now),
  );
});

/// Days a watch or another app recorded a workout of ten minutes or more:
/// they keep the streak like a Gymco session does. Health Connect only
/// shares the last 30 days, so that is how far back this looks.
final watchWorkoutDaysProvider = FutureProvider<Set<String>>((ref) async {
  if (!ref.watch(healthOnProvider)) return const {};
  final now = ref.read(clockProvider)();
  try {
    final all = await ref
        .read(healthSyncProvider)
        .workouts(now.subtract(const Duration(days: 30)), now)
        .timeout(const Duration(seconds: 4));
    return watchWorkoutDays(all);
  } catch (_) {
    return const {};
  }
});

/// The watch's heart rate across a Gymco workout. Null when there is none.
final workoutHeartProvider = FutureProvider.family<HeartSummary?, (DateTime, DateTime)>((ref, span) async {
  if (!ref.watch(healthOnProvider)) return null;
  final (start, end) = span;
  return HeartSummary.of(await ref.read(healthSyncProvider).samples(Metric.heartRate, start, end), start, end);
});

/// Steps for each of the last seven days, oldest first; today's is the
/// store's own total, as on the Steps tile. Null when not connected.
final stepsWeekProvider = FutureProvider<List<double?>?>((ref) async {
  if (!ref.watch(healthOnProvider)) return null;
  final now = ref.read(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final h = ref.read(healthSyncProvider);
  final week = lastWeek(
    perDay(await h.samples(Metric.steps, today.subtract(const Duration(days: 6)), now), sum: true),
    now,
  );
  final steps = await ref.watch(stepsTodayProvider.future);
  return [...week.take(6), steps?.toDouble() ?? week.last];
});
