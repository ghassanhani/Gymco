import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'providers.dart';

/// Connects the health store, or disconnects. False when the phone said no.
Future<bool> setHealth(WidgetRef ref, bool on) async {
  if (on && !await ref.read(healthSyncProvider).connect()) return false;
  await ref.read(healthOnProvider.notifier).set(on);
  if (on) ref.invalidate(healthImportProvider);
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
