import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import '../../data/food_names.dart';
import '../../l10n/app_localizations.dart';

String fmtInt(BuildContext context, num v) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(v.round());

String fmtDec(BuildContext context, num v, {int digits = 1}) => NumberFormat.decimalPatternDigits(
  locale: Localizations.localeOf(context).toString(),
  decimalDigits: digits,
).format(v);

String mealName(AppLocalizations l, Meal m) => switch (m) {
  Meal.breakfast => l.breakfast,
  Meal.lunch => l.lunch,
  Meal.dinner => l.dinner,
  Meal.snack => l.snack,
};

/// Long weekday and date for the screen subtitle.
String fmtDay(BuildContext context, DateTime d) =>
    DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(d);

String muscleName(AppLocalizations l, String m) => switch (m) {
  'chest' => l.m_chest,
  'shoulders' => l.m_shoulders,
  'triceps' => l.m_triceps,
  'biceps' => l.m_biceps,
  'forearms' => l.m_forearms,
  'lats' => l.m_lats,
  'middle back' => l.m_middle_back,
  'lower back' => l.m_lower_back,
  'traps' => l.m_traps,
  'abdominals' => l.m_abdominals,
  'quadriceps' => l.m_quadriceps,
  'hamstrings' => l.m_hamstrings,
  'glutes' => l.m_glutes,
  'calves' => l.m_calves,
  'adductors' => l.m_adductors,
  'abductors' => l.m_abductors,
  'neck' => l.m_neck,
  _ => m,
};

/// 1:07:05, 47:12 or 0:06, as the prototype writes a clock.
String fmtClock(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Weights drop a trailing .0: 100, 102.5.
String fmtKg(BuildContext context, double kg) => kg == kg.roundToDouble() ? fmtInt(context, kg) : fmtDec(context, kg);

/// Keeps a number range like 5–8 in reading order inside right-to-left text.
String ltr(String s) => '\u2066$s\u2069';

/// A food's name in the app's language, where the staple has one.
String foodName(BuildContext context, String id, String english) =>
    localFoodName(id, english, Localizations.localeOf(context).languageCode);
