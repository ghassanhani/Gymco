import 'dart:io';

import 'package:health/health.dart';

import '../domain/recovery.dart';

/// Apple Health on iPhone, Health Connect on Android: what Gymco reads
/// (weigh-ins, steps, and what a watch or strap records: sleep, heart rate,
/// active energy, workouts) and writes back (workouts, water, weigh-ins).
abstract class HealthSync {
  /// False when the phone has no health store, or Health Connect is not
  /// installed.
  Future<bool> available();

  /// Opens the phone's own permission screen; true when it was granted.
  Future<bool> connect();

  /// Why the last [connect] failed, as the phone put it; null if it did not.
  String? get lastError;

  /// Sends the person to install Health Connect (Android only).
  Future<void> install();

  Future<List<(DateTime, double)>> weights(DateTime since);
  Future<int?> stepsToday(DateTime now);

  /// Readings between [from] and [to]; empty when there are none or the
  /// person did not allow that kind.
  Future<List<Sample>> samples(Metric metric, DateTime from, DateTime to);

  /// Workouts other apps and watches recorded; Gymco's own are left out.
  Future<List<WatchWorkout>> workouts(DateTime from, DateTime to);

  Future<void> writeWater(int ml, DateTime at);
  Future<void> writeWeight(double kg, DateTime at);
  Future<void> writeWorkout(String name, DateTime start, DateTime end);
}

/// For tests and phones without a health store.
class NoHealth implements HealthSync {
  const NoHealth();
  @override
  Future<bool> available() async => false;
  @override
  Future<bool> connect() async => false;
  @override
  String? get lastError => null;
  @override
  Future<void> install() async {}
  @override
  Future<List<(DateTime, double)>> weights(DateTime since) async => const [];
  @override
  Future<int?> stepsToday(DateTime now) async => null;
  @override
  Future<List<Sample>> samples(Metric metric, DateTime from, DateTime to) async => const [];
  @override
  Future<List<WatchWorkout>> workouts(DateTime from, DateTime to) async => const [];
  @override
  Future<void> writeWater(int ml, DateTime at) async {}
  @override
  Future<void> writeWeight(double kg, DateTime at) async {}
  @override
  Future<void> writeWorkout(String name, DateTime start, DateTime end) async {}
}

class DeviceHealth implements HealthSync {
  final _h = Health();
  Future<void>? _ready;
  Future<void> _init() => _ready ??= _h.configure();

  // The two stores name some of these differently: HRV is SDNN on iPhone and
  // RMSSD on Android, and Apple Watch splits sleep into stages where Health
  // Connect keeps one session. Each is only compared with its own normal.
  static final _sleep = Platform.isIOS
      ? const [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
        ]
      : const [HealthDataType.SLEEP_SESSION];
  static final _hrv = Platform.isIOS
      ? HealthDataType.HEART_RATE_VARIABILITY_SDNN
      : HealthDataType.HEART_RATE_VARIABILITY_RMSSD;
  static final _reads = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    _hrv,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    ..._sleep,
  ];
  static final _types = [
    HealthDataType.WEIGHT,
    HealthDataType.STEPS,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
    ..._reads,
  ];
  static final _access = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ,
    HealthDataAccess.WRITE,
    HealthDataAccess.READ_WRITE,
    for (final _ in _reads) HealthDataAccess.READ,
  ];

  /// Gymco's own app id, as the store records the source of what it wrote.
  static const _self = 'app.gymco.gymco';

  @override
  Future<bool> available() async {
    await _init();
    return _h.isHealthConnectAvailable();
  }

  @override
  String? lastError;

  @override
  Future<bool> connect() async {
    lastError = null;
    try {
      if (!await available()) {
        lastError = 'Health store not available on this phone';
        return false;
      }
      final ok = await _h.requestAuthorization(_types, permissions: _access);
      if (!ok) lastError = 'requestAuthorization returned false';
      return ok;
    } catch (e) {
      // On iPhone this is where a missing HealthKit entitlement shows up.
      lastError = '$e';
      return false;
    }
  }

  @override
  Future<void> install() => _h.installHealthConnect();

  @override
  Future<List<(DateTime, double)>> weights(DateTime since) async {
    await _init();
    try {
      final points = await _h.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: since,
        endTime: DateTime.now(),
      );
      return [
        for (final p in points)
          if (p.value case NumericHealthValue(:final numericValue)) (p.dateFrom, numericValue.toDouble()),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<int?> stepsToday(DateTime now) async {
    await _init();
    try {
      return await _h.getTotalStepsInInterval(DateTime(now.year, now.month, now.day), now);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Sample>> samples(Metric metric, DateTime from, DateTime to) async {
    final types = switch (metric) {
      Metric.heartRate => const [HealthDataType.HEART_RATE],
      Metric.restingHr => const [HealthDataType.RESTING_HEART_RATE],
      Metric.hrv => [_hrv],
      Metric.activeKcal => const [HealthDataType.ACTIVE_ENERGY_BURNED],
      Metric.sleep => _sleep,
      Metric.steps => const [HealthDataType.STEPS],
    };
    await _init();
    try {
      final points = await _h.getHealthDataFromTypes(types: types, startTime: from, endTime: to);
      return [
        for (final p in points)
          if (p.value case NumericHealthValue(:final numericValue))
            Sample(
              p.dateFrom,
              p.dateTo,
              // A sleep stage's length is what counts, whatever its value says.
              metric == Metric.sleep ? p.dateTo.difference(p.dateFrom).inSeconds / 60 : numericValue.toDouble(),
              source: p.sourceId,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<WatchWorkout>> workouts(DateTime from, DateTime to) async {
    await _init();
    try {
      final points = await _h.getHealthDataFromTypes(
        types: const [HealthDataType.WORKOUT],
        startTime: from,
        endTime: to,
      );
      return [
        for (final p in points)
          if (p.value case WorkoutHealthValue(:final workoutActivityType, :final totalEnergyBurned)
              when !p.sourceId.startsWith(_self))
            WatchWorkout(
              start: p.dateFrom,
              end: p.dateTo,
              kind: _kind(workoutActivityType),
              source: p.sourceName,
              kcal: totalEnergyBurned,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static WorkoutKind _kind(HealthWorkoutActivityType t) {
    final n = t.name;
    if (n.contains('RUNNING')) return WorkoutKind.run;
    if (n.contains('WALKING') || n == 'HIKING') return WorkoutKind.walk;
    if (n.contains('BIKING') || n.contains('CYCLING')) return WorkoutKind.ride;
    if (n.contains('SWIMMING')) return WorkoutKind.swim;
    if (n.contains('STRENGTH') || n == 'WEIGHTLIFTING' || n == 'CROSS_TRAINING') return WorkoutKind.strength;
    if (n.contains('INTERVAL') || n == 'HIGH_INTENSITY_INTERVAL_TRAINING') return WorkoutKind.hiit;
    if (n.contains('YOGA') || n == 'PILATES') return WorkoutKind.yoga;
    return WorkoutKind.other;
  }

  // Writes are best effort: a refused or missing store never stops logging.
  Future<void> _quiet(Future<Object?> Function() run) async {
    try {
      await _init();
      await run();
    } catch (_) {}
  }

  @override
  Future<void> writeWater(int ml, DateTime at) => _quiet(
    () => _h.writeHealthData(
      value: ml / 1000,
      unit: HealthDataUnit.LITER,
      type: HealthDataType.WATER,
      startTime: at,
      endTime: at,
      recordingMethod: RecordingMethod.manual,
    ),
  );

  @override
  Future<void> writeWeight(double kg, DateTime at) => _quiet(
    () => _h.writeHealthData(
      value: kg,
      unit: HealthDataUnit.KILOGRAM,
      type: HealthDataType.WEIGHT,
      startTime: at,
      endTime: at,
      recordingMethod: RecordingMethod.manual,
    ),
  );

  @override
  Future<void> writeWorkout(String name, DateTime start, DateTime end) => _quiet(
    () => _h.writeWorkoutData(
      activityType: Platform.isIOS
          ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
          : HealthWorkoutActivityType.STRENGTH_TRAINING,
      start: start,
      end: end,
      title: name,
      recordingMethod: RecordingMethod.manual,
    ),
  );
}
