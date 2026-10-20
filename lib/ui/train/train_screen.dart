import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/packs.dart' show PackTemplate;
import '../../data/templates.dart';
import '../../data/training.dart';
import '../../domain/schedule.dart';
import '../../domain/volume.dart';
import '../../domain/workout.dart';
import '../../l10n/app_localizations.dart';
import '../../state/pack_providers.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/day_strip.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'train_kit.dart';

/// Train is a day, not a catalogue. The strip picks the day; the body is
/// that day's exercises. The library sits behind one button.
class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});

  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  /// The strip index showing; null is today.
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final routines = ref.watch(routinesProvider).value;
    final live = ref.watch(activeWorkoutProvider) != null;
    if (routines == null) return const VScreen(child: SizedBox.shrink());
    if (routines.isEmpty) {
      return VScreen(
        overlays: const [ResumeBar()],
        child: Column(
          children: [
            VAppBar(title: l.trainTitle, sub: l.noRoutinesTitle),
            Expanded(
              child: Pad(bottom: live ? 190 : 116, children: const [_FirstRoutine()]),
            ),
          ],
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final sched = ref.watch(weekScheduleProvider).value ?? const <ScheduledDay>[];
    final todayI = sched.indexWhere((d) => d.date == today);
    final i = (_picked ?? todayI).clamp(0, sched.isEmpty ? 0 : sched.length - 1);
    final isToday = i == todayI;
    final day = sched.isEmpty ? null : sched[i];
    final loc = Localizations.localeOf(context).toString();
    final planDays = routines.fold(0, (n, r) => n + r.days.length);
    final p = ref.watch(profileProvider);
    final week = p == null ? 1 : now.difference(p.startedOn).inDays ~/ 7 + 1;

    return VScreen(
      overlays: const [ResumeBar()],
      child: Column(
        children: [
          VAppBar(
            title: isToday || day == null ? l.trainTitleEm : DateFormat.EEEE(loc).format(day.date),
            sub: isToday || day == null
                ? (planDays == 0 ? l.noWeeklyPlan : l.trainSub(planDays, week))
                : (day.date.isAfter(today)
                      ? l.dayAhead(DateFormat.MMMMd(loc).format(day.date))
                      : l.dayClosed(DateFormat.MMMMd(loc).format(day.date))),
            right: isToday ? null : VChip(label: l.backToToday, onTap: () => setState(() => _picked = null)),
          ),
          if (sched.isNotEmpty)
            WeekStrip(
              days: stripDaysFor(context, schedule: sched, today: now, train: true),
              selected: i,
              onPick: (n) => setState(() => _picked = n == todayI ? null : n),
            ),
          Expanded(
            child: Pad(
              bottom: live ? 190 : 116,
              children: [
                if (day != null) ..._body(context, sched, i, todayI),
                _ToLibrary(count: routines.length),
                if (isToday) const _WeekCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, List<ScheduledDay> sched, int i, int todayI) {
    final day = sched[i];
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    Routine? byId(int? id) => routines.where((r) => r.id == id).firstOrNull;
    if (day.done != null) return [_ClosedDay(day: day, routine: byId(day.done!.routineId))];
    if (day.routine != null) {
      final r = byId(day.routine!.id);
      if (r != null) return _plannedDay(context, day, r, ahead: i > todayI, isToday: i == todayI);
    }
    int? next;
    for (var j = i + 1; j < sched.length; j++) {
      if (sched[j].hasSession) {
        next = j;
        break;
      }
    }
    return _restDay(context, day, sched, next, todayI, ahead: i >= todayI);
  }

  Future<void> _start(Routine r) async {
    final lib = await ref.read(exerciseLibraryProvider.future);
    await ref.read(activeWorkoutProvider.notifier).startRoutine(r, lib);
    if (mounted) context.push('/workout');
  }

  Future<void> _startOne(Routine r, int index) async {
    final lib = await ref.read(exerciseLibraryProvider.future);
    await ref.read(activeWorkoutProvider.notifier).startOne(r, index, lib);
    if (mounted) context.push('/workout');
  }

  void _startEmpty() {
    final l = AppLocalizations.of(context);
    if (ref.read(activeWorkoutProvider) == null) {
      ref.read(activeWorkoutProvider.notifier).startEmpty(l.workoutDefaultName);
    }
    context.push('/workout');
  }

  List<Widget> _plannedDay(
    BuildContext context,
    ScheduledDay day,
    Routine r, {
    required bool ahead,
    required bool isToday,
  }) {
    final l = AppLocalizations.of(context);
    final lib = ref.watch(exerciseLibraryProvider).value;
    final logged = isToday ? (ref.watch(loggedTodayProvider).value ?? const <String>{}) : const <String>{};
    final done = r.items.where((it) => logged.contains(it.exerciseId)).length;
    final last = ref.watch(lastRunProvider)[r.id];
    final dayName = weekdayName(context, weekdayIndex(day.date));
    final eyebrow = day.moved && day.movedFrom != null
        ? l.movedHere(weekdayName(context, weekdayIndex(day.movedFrom!)))
        : (isToday ? l.todayLbl : l.plannedOn(dayName));
    return [
      VCard(
        color: Volt.brandWash,
        border: Border.all(color: Volt.lime, width: 1.5),
        child: GapCol(
          gap: 12,
          cross: CrossAxisAlignment.stretch,
          children: [
            GapCol(
              gap: 4,
              children: [
                Eyebrow(eyebrow, color: Volt.brandInk),
                Text(
                  r.name,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Volt.t1),
                ),
              ],
            ),
            ExList(
              onBrand: true,
              children: [
                for (final (n, it) in r.items.indexed)
                  ExLine(
                    item: it,
                    exercise: lib?[it.exerciseId],
                    lead: true,
                    done: logged.contains(it.exerciseId),
                    onStart: ahead ? null : () => _startOne(r, n),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Muted(
                    done > 0
                        ? l.loggedOfPlanned(done, r.items.length, r.totalSets)
                        : l.setsAbout(r.totalSets, routineMinutes(r)),
                  ),
                ),
                VBtn(
                  label: ahead ? l.startEarly : (done > 0 ? l.continueBtn : l.startAll),
                  small: true,
                  onTap: () => _start(r),
                ),
              ],
            ),
          ],
        ),
      ),
      if (ahead) ...[
        VCard(
          tight: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: VIcon('info', size: 17, color: Volt.t3),
              ),
              const SizedBox(width: 10),
              Expanded(child: Muted(l.startEarlyNote)),
            ],
          ),
        ),
        if (last != null)
          _InfoRow(
            icon: 'dumb',
            label: l.lastTimeRan,
            value: DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(last),
          ),
      ] else
        VBtn(label: l.somethingElse, kind: BtnKind.ghost, small: true, icon: 'plus', expand: true, onTap: _startEmpty),
    ];
  }

  List<Widget> _restDay(
    BuildContext context,
    ScheduledDay day,
    List<ScheduledDay> sched,
    int? next,
    int todayI, {
    required bool ahead,
  }) {
    final l = AppLocalizations.of(context);
    final body = day.missed != null
        ? l.restMissed(day.missed!.name)
        : (ahead ? l.restAhead(weekdayName(context, weekdayIndex(day.date))) : l.restPast);
    final n = next == null ? null : sched[next];
    final nextName = n?.done?.name ?? n?.routine?.name;
    return [
      VCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Volt.card2, shape: BoxShape.circle),
              child: Center(child: VIcon('clock', size: 22, color: Volt.t2)),
            ),
            const SizedBox(height: 12),
            Text(
              l.restDay,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Volt.t1),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Muted(body, align: TextAlign.center),
            ),
          ],
        ),
      ),
      if (n != null && nextName != null)
        _InfoRow(
          icon: 'dumb',
          label: next! > todayI ? l.nextSession : l.sessionAfter,
          value: '$nextName · ${DateFormat.E(Localizations.localeOf(context).toString()).format(n.date)}',
          onTap: () => setState(() => _picked = next == todayI ? null : next),
        ),
      VBtn(label: l.logAnyway, kind: BtnKind.ghost, expand: true, onTap: _startEmpty),
    ];
  }
}

/// A day you closed: what you actually did.
class _ClosedDay extends ConsumerWidget {
  const _ClosedDay({required this.day, required this.routine});
  final ScheduledDay day;
  final Routine? routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rec = (ref.watch(recentWorkoutsProvider).value ?? const <WorkoutRecord>[])
        .where((w) => DateUtils.isSameDay(w.startedAt, day.date))
        .firstOrNull;
    if (rec == null) return const SizedBox.shrink();
    final sets = ref.watch(setsOfWorkoutProvider(rec.id)).value ?? const <LoggedExerciseSet>[];
    final best = bestSets(sets);
    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        VCard(
          child: GapCol(
            gap: 14,
            cross: CrossAxisAlignment.stretch,
            children: [
              GapCol(
                gap: 3,
                children: [
                  Eyebrow(l.closedLbl),
                  Text(
                    rec.name,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Volt.t1),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final (k, v) in [
                    (l.durationLbl, l.minutesShort('${rec.duration.inMinutes}')),
                    (l.volumeLbl, '${fmtInt(context, rec.volume)} ${l.kgLbl}'),
                    (l.hardSetsLbl, fmtInt(context, rec.hardSets)),
                  ])
                    Expanded(
                      child: GapCol(
                        gap: 2,
                        children: [
                          Muted(k),
                          Text(v, style: numStyle(17)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (best.isNotEmpty) ...[
          Eyebrow(l.bestSetEach, padding: const EdgeInsetsDirectional.only(start: 4)),
          VList(
            children: [
              for (final b in best)
                VItem(
                  onTap: () => context.push('/exercise/${Uri.encodeComponent(b.exerciseId)}'),
                  children: [
                    ItemText(b.exerciseName, sub: ltr('${fmtKg(context, b.weightKg)} ${l.kgLbl} × ${b.reps}')),
                  ],
                ),
            ],
          ),
        ],
        if (routine != null)
          VBtn(
            label: l.runAgain(routine!.name),
            expand: true,
            onTap: () async {
              final lib = await ref.read(exerciseLibraryProvider.future);
              await ref.read(activeWorkoutProvider.notifier).startRoutine(routine!, lib);
              if (context.mounted) context.push('/workout');
            },
          ),
      ],
    );
  }
}

/// The heaviest working set of each exercise, by weight × reps, in order.
List<LoggedExerciseSet> bestSets(List<LoggedExerciseSet> sets) {
  final out = <String, LoggedExerciseSet>{};
  for (final s in sets) {
    if (s.type == SetType.warmup || s.reps <= 0) continue;
    final b = out[s.exerciseId];
    if (b == null || s.weightKg * s.reps > b.weightKg * b.reps) out[s.exerciseId] = s;
  }
  return out.values.toList();
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.onTap});
  final String icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => VCard(
    tight: true,
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Volt.card2, shape: BoxShape.circle),
          child: Center(child: VIcon(icon, size: 18, color: Volt.t2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GapCol(
            gap: 2,
            children: [
              Muted(label),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
              ),
            ],
          ),
        ),
        if (onTap != null) VIcon('fwd', size: 18, color: Volt.t3),
      ],
    ),
  );
}

/// The way into the library, and the only place routines are listed.
class _ToLibrary extends StatelessWidget {
  const _ToLibrary({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _InfoRowBig(
      icon: 'list',
      title: l.allRoutines,
      sub: l.allRoutinesSub(count),
      onTap: () => context.push('/train/routines'),
    );
  }
}

class _InfoRowBig extends StatelessWidget {
  const _InfoRowBig({required this.icon, required this.title, required this.sub, required this.onTap});
  final String icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => VCard(
    tight: true,
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Volt.card2, shape: BoxShape.circle),
          child: Center(child: VIcon(icon, size: 18, color: Volt.t2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GapCol(
            gap: 2,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
              ),
              Muted(sub),
            ],
          ),
        ),
        VIcon('fwd', size: 18, color: Volt.t3),
      ],
    ),
  );
}

/// The muscle the week leans on most, against the 10–20 band.
class _WeekCard extends ConsumerWidget {
  const _WeekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lib = ref.watch(exerciseLibraryProvider).value;
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    if (lib == null) return const SizedBox.shrink();
    final plan = [
      for (final r in routines)
        for (final _ in r.days)
          for (final i in r.items)
            if (lib[i.exerciseId]?.primary.firstOrNull case final m?) (m, i.sets),
    ];
    final rows = weeklyVolume(plan, const []);
    if (rows.isEmpty) return const SizedBox.shrink();
    final g = rows.first;
    final (color, zone) = switch (g.state) {
      VolumeState.inRange => (Volt.ok, l.zoneIn),
      VolumeState.under => (Volt.t3, l.zoneUnder),
      VolumeState.over => (Volt.warn, l.zoneOver),
    };
    return VCard(
      tight: true,
      child: Row(
        children: [
          Expanded(
            child: GapCol(
              gap: 6,
              children: [
                Muted(l.weeklySetsOf(groupName(l, g.group).toLowerCase())),
                Text.rich(
                  TextSpan(
                    text: l.hardSetsN(g.total),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                    children: [
                      TextSpan(
                        text: ' · $zone',
                        style: TextStyle(fontWeight: FontWeight.w500, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 84,
            child: VolumeBar(total: g.total, color: color, height: 12),
          ),
        ],
      ),
    );
  }
}

/// A localised name for each template role.
String templateRoleName(AppLocalizations l, String r) => switch (r) {
  'upperA' => l.tplUpperA,
  'upperB' => l.tplUpperB,
  'lowerA' => l.tplLowerA,
  'lowerB' => l.tplLowerB,
  'pushA' => l.tplPushA,
  'pushB' => l.tplPushB,
  'pullA' => l.tplPullA,
  'pullB' => l.tplPullB,
  'legsA' => l.tplLegsA,
  'legsB' => l.tplLegsB,
  'fullA' => l.tplFullA,
  'fullB' => l.tplFullB,
  _ => l.tplFullC,
};

/// The three starter blocks, as (kind, title, sub).
List<(TemplateKind, String, String)> templateChoices(AppLocalizations l) => [
  (TemplateKind.upperLower, l.tplUL, l.tplULSub),
  (TemplateKind.pushPullLegs, l.tplPPL, l.tplPPLSub),
  (TemplateKind.fullBody, l.tplFB, l.tplFBSub),
];

/// "3 days a week · beginner" for a template from the pack.
String packTemplateSub(AppLocalizations l, PackTemplate t) {
  final days = l.tplPackDays({for (final r in t.routines) r.weekday}.length);
  final level = switch (t.level) {
    'beginner' => l.tplLevelBeginner,
    'intermediate' => l.tplLevelIntermediate,
    'expert' => l.tplLevelExpert,
    _ => null,
  };
  return level == null ? days : '$days · $level';
}

/// No routines yet: an empty workout, your own routine, or a template.
class _FirstRoutine extends ConsumerWidget {
  const _FirstRoutine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    // A card per way in: the icon says which is the main one (lime).
    Widget choice(String icon, String title, String sub, VoidCallback onTap, {bool main = false}) => Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: VCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: main ? Volt.brand : Volt.brandWash),
              child: VIcon(icon, size: 20, color: main ? Volt.ink : Volt.brandInk),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GapCol(
                gap: 2,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Volt.t1),
                  ),
                  Muted(sub, size: 12.5),
                ],
              ),
            ),
            const SizedBox(width: 8),
            VIcon('fwd', size: 18, color: Volt.t3),
          ],
        ),
      ),
    );

    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Column(
            children: [
              const EmptyArt(size: 72),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Muted(l.trainEmptyBody, align: TextAlign.center),
              ),
            ],
          ),
        ),
        choice('play', l.startEmptyWorkout, l.startEmptySub, main: true, () {
          ref.read(activeWorkoutProvider.notifier).startEmpty(l.workoutDefaultName);
          context.push('/workout');
        }),
        choice('plus', l.buildOwn, l.buildOwnSub, () => context.push('/routine/new')),
        Eyebrow(l.orTemplate, padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 0)),
        TemplateList(onDone: (title) => showVToast(context, l.templateAdded(title))),
      ],
    );
  }
}

/// The template rows; tapping one adds its routines to the weekly plan.
class TemplateList extends ConsumerWidget {
  const TemplateList({super.key, required this.onDone});
  final ValueChanged<String> onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    VItem row(String title, String sub, Future<void> Function() apply) => VItem(
      semantics: title,
      onTap: () async {
        await apply();
        onDone(title);
      },
      children: [
        ItemText(title, sub: sub, weight: FontWeight.w600),
        VIcon('fwd', size: 18, color: Volt.t1),
      ],
    );
    final actions = ref.read(routineActionsProvider);
    return VList(
      children: [
        for (final (k, title, sub) in templateChoices(l))
          row(title, sub, () => actions.applyTemplate(k, (r) => templateRoleName(l, r))),
        // Templates from the content pack come after the built-in three.
        for (final t in ref.watch(packsProvider).templates)
          row(t.name.of(lang), packTemplateSub(l, t), () => actions.applyPackTemplate(t, lang)),
      ],
    );
  }
}
