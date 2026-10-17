import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import '../../domain/schedule.dart';
import '../kit/kit.dart';

/// The week strip for Today (walks the food log) or Train (walks the plan).
/// On Today a day ahead has nothing to show and stays dim; on Train the days
/// ahead are real, so they stay live with a dotted ring.
List<WeekDay> stripDaysFor(
  BuildContext context, {
  required List<ScheduledDay> schedule,
  required DateTime today,
  required bool train,
  Set<String> logged = const {},
}) {
  final loc = Localizations.localeOf(context).toString();
  final t = DateTime(today.year, today.month, today.day);
  return [
    for (final d in schedule)
      () {
        final ahead = d.date.isAfter(t);
        final isToday = d.date == t;
        final look = train
            ? (ahead && d.hasSession
                  ? DayLook.planned
                  : (!ahead && !isToday && d.done != null ? DayLook.logged : DayLook.normal))
            : (ahead
                  ? DayLook.future
                  : (!isToday && logged.contains(dayKey(d.date)) ? DayLook.logged : DayLook.normal));
        return WeekDay(
          letter: DateFormat('EEEEE', loc).format(d.date),
          number: d.date.day,
          label: DateFormat.MMMMEEEEd(loc).format(d.date),
          look: look,
          dot: d.hasSession,
          today: isToday,
        );
      }(),
  ];
}
