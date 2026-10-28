import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/notifications.dart';
import '../../domain/reminders.dart';
import '../../l10n/app_localizations.dart';
import '../../state/reminder_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

String fmtClockTime(BuildContext context, ClockTime t) =>
    DateFormat.Hm(Localizations.localeOf(context).toString()).format(DateTime(2000, 1, 1, t.$1, t.$2));

String _weekday(BuildContext context, int wd, {bool short = false}) {
  final loc = Localizations.localeOf(context).toString();
  final d = DateTime(2024, 1, 1 + wd);
  return short ? DateFormat.E(loc).format(d) : DateFormat.EEEE(loc).format(d);
}

/// The Me tab's reminder rows: the switch, its icon, name and when it goes.
List<(NoteGroup, String, String, String)> reminderRows(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  final s = ref.watch(reminderSettingsProvider);
  final meals = ref.watch(mealTimesProvider);
  final usual = ref.watch(usualTrainingProvider);
  final (checkDay, checkAt) = regionCheckIn(ref.watch(regionProvider));
  String t(ClockTime x) => fmtClockTime(context, x);
  return [
    (
      NoteGroup.meals,
      'food',
      l.remindMeals,
      l.remindMealsSub(
        t(meals[ReminderKind.breakfast]!),
        t(meals[ReminderKind.lunch]!),
        t(meals[ReminderKind.dinner]!),
      ),
    ),
    (NoteGroup.protein, 'bolt', l.remindProtein, l.remindProteinSub),
    (NoteGroup.water, 'drop', l.remindWater, l.remindWaterSub(t(s.waterAt[0]), t(s.waterAt[1]), t(s.waterAt[2]))),
    (NoteGroup.workout, 'dumb', l.remindWorkout, l.remindWorkoutSub(t(usual))),
    (
      NoteGroup.weighIn,
      'scale',
      l.remindWeighIn,
      l.remindWeighSub(
        [for (final d in s.weighDays.toList()..sort()) _weekday(context, d, short: true)].join(', '),
        t(s.weighAt),
      ),
    ),
    (NoteGroup.streak, 'flame', l.remindStreak, l.remindStreakSub),
    (NoteGroup.checkIn, 'chart', l.remindCheckIn, l.remindCheckInSub(_weekday(context, checkDay), t(checkAt))),
    (NoteGroup.iron, 'sparkles', l.remindIron, l.remindIronSub),
    (NoteGroup.timer, 'clock', l.remindTimer, l.remindTimerSub),
    (NoteGroup.account, 'shield', l.remindAccount, l.remindAccountSub),
  ];
}

Future<ClockTime?> _pickTime(BuildContext context, String label, ClockTime t) async {
  final l = AppLocalizations.of(context);
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
            brightness: Volt.isLight ? Brightness.light : Brightness.dark,
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
  return ok == true ? (chosen.hour, chosen.minute) : null;
}

Widget _timeRow(BuildContext context, String label, ClockTime t, ValueChanged<ClockTime> set) => SRow(
  label: label,
  lead: VIcon('clock', size: 18, color: Volt.brandInk),
  trail: Text(fmtClockTime(context, t), style: numStyle(17)),
  onTap: () async {
    final picked = await _pickTime(context, label, t);
    if (picked != null) set(picked);
  },
);

/// The reminder's own sheet: on or off, and its times.
Future<void> showReminderSheet(BuildContext context, NoteGroup group) {
  return showVSheet<void>(
    context,
    title: _title(AppLocalizations.of(context), group),
    body: (ctx) => [_ReminderBody(group: group)],
  );
}

String _title(AppLocalizations l, NoteGroup g) => switch (g) {
  NoteGroup.meals => l.remindMeals,
  NoteGroup.protein => l.remindProtein,
  NoteGroup.water => l.remindWater,
  NoteGroup.workout => l.remindWorkout,
  NoteGroup.weighIn => l.remindWeighIn,
  NoteGroup.streak => l.remindStreak,
  NoteGroup.checkIn => l.remindCheckIn,
  NoteGroup.iron => l.remindIron,
  NoteGroup.timer => l.remindTimer,
  NoteGroup.account => l.remindAccount,
};

class _ReminderBody extends ConsumerWidget {
  const _ReminderBody({required this.group});
  final NoteGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(reminderSettingsProvider);
    final n = ref.read(reminderSettingsProvider.notifier);
    final meals = ref.watch(mealTimesProvider);
    final on = s.allowed && s.isOn(group);
    final sub = {for (final (g, _, _, sub) in reminderRows(context, ref)) g: sub}[group]!;

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
        ...switch (group) {
          NoteGroup.meals => [
            for (final (k, name) in [
              (ReminderKind.breakfast, l.breakfast),
              (ReminderKind.lunch, l.lunch),
              (ReminderKind.dinner, l.dinner),
            ])
              _timeRow(context, name, meals[k]!, (t) => n.setTime(k, t, meals: meals)),
          ],
          NoteGroup.water => [
            for (final (i, t) in s.waterAt.indexed)
              _timeRow(
                context,
                l.waterNudgeN(i + 1),
                t,
                (x) => n.setTime(ReminderKind.water, x, index: i, meals: meals),
              ),
          ],
          NoteGroup.workout => [
            _timeRow(
              context,
              l.remindWorkoutAt,
              ref.watch(usualTrainingProvider),
              (t) => n.setTime(ReminderKind.workout, t, meals: meals),
            ),
          ],
          NoteGroup.weighIn => [
            _timeRow(context, l.remindWeighIn, s.weighAt, n.setWeighAt),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var d = 0; d < 7; d++)
                    VChip(
                      label: _weekday(context, d, short: true),
                      on: s.weighDays.contains(d),
                      height: 34,
                      onTap: () => n.toggleWeighDay(d),
                    ),
                ],
              ),
            ),
          ],
          _ => const <Widget>[],
        },
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Muted(switch (group) {
            NoteGroup.meals => l.remindMealsNote,
            NoteGroup.water => l.remindWaterNote,
            NoteGroup.workout => l.remindWorkoutNote,
            _ => sub,
          }),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.remindRulesNote, size: 12)),
      ],
    );
  }
}

/// Quiet hours: nothing but the rest timer goes off in between.
Future<void> showQuietHoursSheet(BuildContext context) =>
    showVSheet<void>(context, title: AppLocalizations.of(context).quietHours, body: (ctx) => [const _QuietBody()]);

class _QuietBody extends ConsumerWidget {
  const _QuietBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(reminderSettingsProvider);
    final n = ref.read(reminderSettingsProvider.notifier);
    return GapCol(
      gap: 10,
      cross: CrossAxisAlignment.stretch,
      children: [
        _timeRow(context, l.quietFrom, s.quietFrom, (t) => n.setQuiet(from: t)),
        _timeRow(context, l.quietTo, s.quietTo, (t) => n.setQuiet(to: t)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.remindRulesNote)),
      ],
    );
  }
}
