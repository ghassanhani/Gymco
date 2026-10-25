import 'dart:math' as math;

import '../data/training.dart';
import 'energy.dart';
import 'routine_ai.dart';

/// What Iron's tip asks the user to do, and the screen that does it.
enum IronAction { logFood, startWorkout, drinkWater, weighIn, rest, walk, none }

IronAction _action(Object? v) => switch (v) {
  'log_food' => IronAction.logFood,
  'start_workout' => IronAction.startWorkout,
  'drink_water' => IronAction.drinkWater,
  'weigh_in' => IronAction.weighIn,
  'rest' => IronAction.rest,
  'walk' => IronAction.walk,
  _ => IronAction.none,
};

/// Today's tip from Iron, kept for the day it was given.
class IronTip {
  const IronTip({required this.day, required this.title, required this.tip, required this.action});
  final String day;
  final String title;
  final String tip;
  final IronAction action;

  static IronTip? fromJson(Map<String, Object?> j, String day) {
    final title = '${j['title'] ?? ''}'.trim(), tip = '${j['tip'] ?? ''}'.trim();
    if (title.isEmpty || tip.isEmpty) return null;
    return IronTip(day: day, title: title, tip: tip, action: _action(j['action']));
  }

  Map<String, Object?> toJson() => {'day': day, 'title': title, 'tip': tip, 'action': _names[action]};

  static IronTip? stored(Map<String, Object?> j) => j['day'] is String ? fromJson(j, j['day']! as String) : null;

  static const _names = {
    IronAction.logFood: 'log_food',
    IronAction.startWorkout: 'start_workout',
    IronAction.drinkWater: 'drink_water',
    IronAction.weighIn: 'weigh_in',
    IronAction.rest: 'rest',
    IronAction.walk: 'walk',
    IronAction.none: 'none',
  };
}

/// Iron's program: daily targets for eating and a week of training.
class IronProgram {
  const IronProgram({
    required this.summary,
    required this.kcal,
    required this.macros,
    required this.why,
    required this.plan,
    required this.habits,
  });
  final String summary;
  final double kcal;
  final Macros macros;
  final String why;
  final AiPlan plan;
  final List<String> habits;

  bool get isEmpty => kcal <= 0 && plan.isEmpty;
}

double _num(Object? v) => v is num && v.isFinite ? v.toDouble() : 0;

/// Reads Iron's program answer; the routines are matched to [lib] as the
/// routine builder's are.
IronProgram programFrom(Map<String, Object?> data, ExerciseLibrary lib) => IronProgram(
  summary: '${data['summary'] ?? ''}'.trim(),
  kcal: _num(data['kcal']),
  macros: Macros(protein: _num(data['protein']), carbs: _num(data['carbs']), fat: _num(data['fat'])),
  why: '${data['why'] ?? ''}'.trim(),
  plan: planFrom({'routines': data['routines'], 'summary': ''}, lib),
  habits: [
    for (final h in (data['habits'] as List? ?? const []))
      if ('$h'.trim().isNotEmpty) '$h'.trim(),
  ].take(3).toList(),
);

/// Iron's targets held to the same rules as the weekly check-in: never under
/// the calorie floor, and no more than [maxChange] kcal away from today's
/// target in one step. Protein and fat stay as Iron set them (protein capped
/// at 2.5 g/kg); carbs take what is left. Returns whether it was held back.
(double, Macros, bool) safeTargets({
  required double current,
  required IronProgram p,
  required double floor,
  required double maxChange,
  required double weightKg,
}) {
  final wanted = math.max(floor, p.kcal);
  final kcal = wanted.clamp(math.max(floor, current - maxChange), current + maxChange).roundToDouble();
  final protein = p.macros.protein.clamp(0, weightKg * 2.5).roundToDouble();
  final fat = p.macros.fat.clamp(0, kcal * 0.4 / 9).roundToDouble();
  final carbs = math.max(0, (kcal - protein * 4 - fat * 9) / 4).roundToDouble();
  return (kcal, Macros(protein: protein, carbs: carbs, fat: fat), (kcal - p.kcal).abs() >= 1);
}

/// Iron's look back at a week, kept for that week.
class IronReview {
  const IronReview({
    required this.week,
    required this.headline,
    this.wins = const [],
    this.slips = const [],
    this.next = const [],
  });
  final String week;
  final String headline;
  final List<String> wins;
  final List<String> slips;
  final List<String> next;

  static List<String> _list(Object? v) => [
    for (final x in (v as List? ?? const []))
      if ('$x'.trim().isNotEmpty) '$x'.trim(),
  ];

  static IronReview? fromJson(Map<String, Object?> j, String week) {
    final headline = '${j['headline'] ?? ''}'.trim();
    if (headline.isEmpty) return null;
    return IronReview(
      week: week,
      headline: headline,
      wins: _list(j['wins']),
      slips: _list(j['slips']),
      next: _list(j['next']),
    );
  }

  Map<String, Object?> toJson() => {'week': week, 'headline': headline, 'wins': wins, 'slips': slips, 'next': next};
}

/// The Monday that starts [d]'s week, as a day key: the week a review is for.
String weekKey(DateTime d) {
  final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

/// Something Iron made: a program or a weekly review, kept so the user can
/// open it again. [data] is what the AI sent back, [ask] what the user said.
class IronHistoryEntry {
  const IronHistoryEntry({
    required this.kind,
    required this.day,
    required this.title,
    this.data = const {},
    this.ask = '',
  });
  final String kind;
  final String day;
  final String title;
  final Map<String, Object?> data;
  final String ask;

  static const program = 'program', review = 'review';

  Map<String, Object?> toJson() => {'kind': kind, 'day': day, 'title': title, 'data': data, 'ask': ask};

  static IronHistoryEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final kind = j['kind'], day = j['day'], title = j['title'];
    if (kind is! String || day is! String || title is! String) return null;
    return IronHistoryEntry(
      kind: kind,
      day: day,
      title: title,
      data: j['data'] is Map ? (j['data'] as Map).cast<String, Object?>() : const {},
      ask: '${j['ask'] ?? ''}',
    );
  }
}
