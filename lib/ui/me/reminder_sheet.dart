import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/reminders.dart';
import '../../l10n/app_localizations.dart';
import '../../state/reminder_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

String fmtClockTime(BuildContext context, ClockTime t) =>
    DateFormat.Hm(Localizations.localeOf(context).toString()).format(DateTime(2000, 1, 1, t.$1, t.$2));

/// The reminder's own sheet: on or off, and the time of each nudge.
Future<void> showReminderSheet(BuildContext context, ReminderKind group) {
  final l = AppLocalizations.of(context);
  return showVSheet<void>(
    context,
    title: switch (group) {
      ReminderKind.water => l.remindWater,
      ReminderKind.workout => l.remindWorkout,
      _ => l.remindMeals,
    },
    body: (ctx) => [_ReminderBody(group: group)],
  );
}

class _ReminderBody extends ConsumerWidget {
  const _ReminderBody({required this.group});
  final ReminderKind group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(reminderSettingsProvider);
    final n = ref.read(reminderSettingsProvider.notifier);
    final on = switch (group) {
      ReminderKind.water => s.water,
      ReminderKind.workout => s.workout,
      _ => s.meals,
    };
    final slots = <(String, ClockTime, ReminderKind, int)>[
      if (group == ReminderKind.water)
        for (final (i, t) in s.waterAt.indexed) (l.waterNudgeN(i + 1), t, ReminderKind.water, i)
      else if (group == ReminderKind.workout)
        (l.remindWorkoutAt, s.workoutAt, ReminderKind.workout, 0)
      else
        for (final (k, name) in [
          (ReminderKind.breakfast, l.breakfast),
          (ReminderKind.lunch, l.lunch),
          (ReminderKind.dinner, l.dinner),
        ])
          (name, s.mealAt[k]!, k, 0),
    ];

    Future<void> pick(String label, ClockTime t, ReminderKind k, int i) async {
      var chosen = DateTime(2000, 1, 1, t.$1, t.$2);
      final ok = await showVSheet<bool>(
        context,
        title: label,
        body: (ctx) => [
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              // The app's own font, so the wheel matches the numbers around it.
              data: CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: numStyle(
                    22,
                    weight: FontWeight.w500,
                  ).copyWith(fontFamily: DefaultTextStyle.of(ctx).style.fontFamily),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: chosen,
                use24hFormat: true,
                onDateTimeChanged: (d) => chosen = d,
              ),
            ),
          ),
          VBtn(label: l.doneBtn, expand: true, onTap: () => Navigator.pop(ctx, true)),
        ],
      );
      if (ok == true) await n.setTime(k, (chosen.hour, chosen.minute), index: i);
    }

    return GapCol(
      gap: 10,
      cross: CrossAxisAlignment.stretch,
      children: [
        SRow(
          label: on ? l.reminderOn : l.reminderOff,
          trail: VToggle(on: on),
          onTap: () async {
            final ok = await n.set(group, !on);
            if (!ok && context.mounted) showVToast(context, l.remindersOff, info: true);
          },
        ),
        for (final (label, t, k, i) in slots)
          SRow(
            label: label,
            lead: const VIcon('clock', size: 18, color: Volt.brandInk),
            trail: Text(fmtClockTime(context, t), style: numStyle(17)),
            onTap: () => pick(label, t, k, i),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Muted(switch (group) {
            ReminderKind.water => l.remindWaterNote,
            ReminderKind.workout => l.remindWorkoutNote,
            _ => l.remindMealsNote,
          }),
        ),
      ],
    );
  }
}
