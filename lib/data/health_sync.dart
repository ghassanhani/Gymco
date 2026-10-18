import 'dart:io';

import 'package:health/health.dart';

/// Apple Health on iPhone, Health Connect on Android: what Gymco reads
/// (weigh-ins, steps) and writes back (workouts, water, weigh-ins).
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

  static const _types = [HealthDataType.WEIGHT, HealthDataType.STEPS, HealthDataType.WATER, HealthDataType.WORKOUT];
  static const _access = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ,
    HealthDataAccess.WRITE,
    HealthDataAccess.WRITE,
  ];

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
