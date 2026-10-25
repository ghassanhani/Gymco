import 'dart:math' as math;

import '../data/models.dart';
import 'energy.dart';
import 'session.dart';

/// How loud a signal is. Red is a warning sign: Iron stops pushing, says so
/// plainly and points to a doctor. The rules decide red, never the AI.
enum SignalLevel { info, watch, red }

/// One thing the rules noticed, with the numbers behind it.
class IronSignal {
  const IronSignal(this.id, this.level, [this.values = const {}]);
  final String id;
  final SignalLevel level;
  final Map<String, Object> values;

  Map<String, Object> toJson() => {'id': id, 'level': level.name, ...values};
}

/// The seven PAR-Q+ questions everyone answers before exercise.
const parqQuestions = 7;

/// What the user told Iron about their health. Kept on the phone; sent to
/// the AI only when they allow it.
class HealthProfile {
  const HealthProfile({
    this.injuries = const {},
    this.conditions = const {},
    this.medication = false,
    this.pregnant = false,
    this.parq = const [],
    this.cleared = false,
    this.note = '',
  });

  /// Areas that hurt or were injured, as [PainArea] names.
  final Set<String> injuries;

  /// Diagnosed conditions: 'blood_pressure', 'heart', 'diabetes', 'asthma',
  /// 'joints', 'other'.
  final Set<String> conditions;
  final bool medication;
  final bool pregnant;

  /// The PAR-Q+ answers, true for yes, in order.
  final List<bool> parq;

  /// The user says a doctor cleared them for exercise.
  final bool cleared;
  final String note;

  bool get anyParqYes => parq.any((a) => a);
  bool get answered => parq.length == parqQuestions;

  HealthProfile copyWith({
    Set<String>? injuries,
    Set<String>? conditions,
    bool? medication,
    bool? pregnant,
    List<bool>? parq,
    bool? cleared,
    String? note,
  }) => HealthProfile(
    injuries: injuries ?? this.injuries,
    conditions: conditions ?? this.conditions,
    medication: medication ?? this.medication,
    pregnant: pregnant ?? this.pregnant,
    parq: parq ?? this.parq,
    cleared: cleared ?? this.cleared,
    note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'injuries': injuries.toList()..sort(),
    'conditions': conditions.toList()..sort(),
    'medication': medication,
    'pregnant': pregnant,
    'parq': parq,
    'cleared': cleared,
    if (note.trim().isNotEmpty) 'note': note.trim(),
  };

  factory HealthProfile.fromJson(Map<String, Object?> j) => HealthProfile(
    injuries: {for (final i in (j['injuries'] as List? ?? const [])) '$i'},
    conditions: {for (final c in (j['conditions'] as List? ?? const [])) '$c'},
    medication: j['medication'] == true,
    pregnant: j['pregnant'] == true,
    parq: [for (final a in (j['parq'] as List? ?? const [])) a == true],
    cleared: j['cleared'] == true,
    note: '${j['note'] ?? ''}',
  );
}

/// Everything the rules read, gathered from the app's own data.
class IronFacts {
  const IronFacts({
    required this.now,
    required this.profile,
    required this.calorieFloor,
    this.restingByDay = const {},
    this.sleepByDay = const {},
    this.dayKcal = const {},
    this.trend = const [],
    this.pain = const {},
    this.health,
    this.proteinToday = 0,
    this.waterToday = 0,
    this.waterGoal = 0,
    this.planDaysThisWeek = const {},
    this.trainedDaysThisWeek = const {},
    this.mealsToday = 0,
  });

  final DateTime now;
  final Profile profile;
  final double calorieFloor;

  /// Resting heart rate and minutes asleep, by day.
  final Map<String, double> restingByDay;
  final Map<String, double> sleepByDay;

  /// Logged calories and how many meals, by day.
  final Map<String, ({double kcal, int meals})> dayKcal;

  /// Trend weight, oldest first, one a day.
  final List<double> trend;

  /// The last pain flagged on each exercise: area, sharp, day.
  final Map<String, ({PainArea area, bool sharp, String day})> pain;
  final HealthProfile? health;
  final double proteinToday;
  final int waterToday;
  final int waterGoal;

  /// Weekdays (0 Monday) planned and trained so far this week.
  final Set<int> planDaysThisWeek;
  final Set<int> trainedDaysThisWeek;
  final int mealsToday;
}

String _back(DateTime now, int days) => dayKey(DateTime(now.year, now.month, now.day - days));

/// The rules. Red ones are warning signs; the rest tell Iron what matters
/// today. Each is a plain, fixed threshold so it can be tested and trusted.
List<IronSignal> ironSignals(IronFacts f) {
  final out = <IronSignal>[];
  final today = DateTime(f.now.year, f.now.month, f.now.day);

  // Resting heart rate 10+ above its usual three days running.
  final usual = [for (var d = 4; d <= 17; d++) ?f.restingByDay[_back(today, d)]]..sort();
  if (usual.length >= 5) {
    final base = usual[usual.length ~/ 2];
    final last3 = [for (var d = 0; d < 3; d++) f.restingByDay[_back(today, d)]];
    if (last3.every((v) => v != null && v >= base + 10)) {
      out.add(IronSignal('rhr_high', SignalLevel.red, {'usual': base.round(), 'now': last3.first!.round()}));
    }
  }

  // Losing faster than 1.5% of body weight a week over two weeks.
  if (f.trend.length >= 15) {
    final from = f.trend[f.trend.length - 15], to = f.trend.last;
    final ratePerWeek = (to - from) / from * 100 / 2;
    if (ratePerWeek <= -1.5) {
      out.add(IronSignal('fast_loss', SignalLevel.red, {'pct_week': double.parse(ratePerWeek.toStringAsFixed(1))}));
    }
  }

  // Three of the last four days logged with two meals or more, under the
  // floor by 300 or more: eating too little, not logging too little.
  final low = [
    for (var d = 1; d <= 4; d++)
      if (f.dayKcal[_back(today, d)] case final t? when t.meals >= 2 && t.kcal < f.calorieFloor - 300) d,
  ];
  if (low.length >= 3) out.add(IronSignal('under_eating', SignalLevel.red, {'days': low.length}));

  // Sharp pain this week, or the same area hurting on two exercises.
  final recent = [
    for (final p in f.pain.values)
      if (!DateTime.parse(p.day).isBefore(today.subtract(const Duration(days: 14)))) p,
  ];
  final sharp = recent.where(
    (p) => p.sharp && !DateTime.parse(p.day).isBefore(today.subtract(const Duration(days: 7))),
  );
  if (sharp.isNotEmpty) {
    out.add(IronSignal('sharp_pain', SignalLevel.red, {'area': sharp.first.area.name}));
  } else {
    final byArea = <PainArea, int>{};
    for (final p in recent) {
      byArea[p.area] = (byArea[p.area] ?? 0) + 1;
    }
    final repeated = byArea.entries.where((e) => e.value >= 2).firstOrNull;
    if (repeated != null) out.add(IronSignal('repeated_pain', SignalLevel.red, {'area': repeated.key.name}));
  }

  // A yes on the PAR-Q+ and no doctor's clearance yet.
  final h = f.health;
  if (h != null && h.anyParqYes && !h.cleared) out.add(const IronSignal('needs_clearance', SignalLevel.red));
  if (h != null && h.pregnant) out.add(const IronSignal('pregnant', SignalLevel.watch));
  if (h != null && h.injuries.isNotEmpty) {
    out.add(IronSignal('injuries', SignalLevel.watch, {'areas': (h.injuries.toList()..sort()).join(',')}));
  }

  // Under six hours a night for the last three.
  final nights = [for (var d = 0; d < 3; d++) f.sleepByDay[_back(today, d)]];
  if (nights.every((n) => n != null && n < 360)) {
    out.add(
      IronSignal('short_sleep', SignalLevel.watch, {'avg_min': (nights.fold<double>(0, (s, n) => s + n!) / 3).round()}),
    );
  }

  // Today: protein behind by the afternoon, water behind by evening.
  final target = f.profile.targets.protein;
  if (f.now.hour >= 14 && target > 0 && f.proteinToday < target * 0.5) {
    out.add(IronSignal('protein_gap', SignalLevel.info, {'left_g': (target - f.proteinToday).round()}));
  }
  if (f.now.hour >= 16 && f.waterGoal > 0 && f.waterToday < f.waterGoal * 0.5) {
    out.add(IronSignal('water_gap', SignalLevel.info, {'left_ml': f.waterGoal - f.waterToday}));
  }

  // Planned days this week gone by untrained.
  final missed = f.planDaysThisWeek.where((d) => d < today.weekday - 1 && !f.trainedDaysThisWeek.contains(d)).length;
  if (missed >= 2) out.add(IronSignal('missed_training', SignalLevel.watch, {'days': missed}));

  // Weight flat for three weeks on a cut or a bulk.
  if (f.trend.length >= 21 && f.profile.goal != Goal.maintain) {
    final change = (f.trend.last - f.trend[f.trend.length - 21]).abs();
    if (change < 0.2) out.add(IronSignal('plateau', SignalLevel.watch, {'weeks': 3}));
  }

  // The streak needs its meals by evening.
  if (f.now.hour >= 19 && f.mealsToday < 3) {
    out.add(IronSignal('streak_risk', SignalLevel.info, {'meals_left': math.max(0, 3 - f.mealsToday)}));
  }
  return out;
}
