import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
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
