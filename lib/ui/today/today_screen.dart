import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import '../../data/training.dart';
import '../../domain/energy.dart';
import '../../domain/hydration.dart';
import '../../domain/schedule.dart';
import '../../domain/volume.dart';
import '../../l10n/app_localizations.dart';
import '../../state/awards_providers.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/day_strip.dart';
import '../common/format.dart';
import '../kit/kit.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final view = ref.watch(viewDayProvider);
    final today = DateTime(now.year, now.month, now.day);
    final showing = view ?? today;
    final sched =
        ref.watch(weekScheduleProvider).value ??
        schedule(days: stripDays(now), today: now, routines: const [], workouts: const []);
    final logged = ref.watch(loggedDaysProvider).value ?? const <String>{};

    final strip = WeekStrip(
      days: stripDaysFor(context, schedule: sched, today: now, train: false, logged: logged),
      selected: sched.indexWhere((d) => d.date == showing).clamp(0, sched.length - 1),
      onPick: (i) {
        final d = sched[i].date;
        if (d.isAfter(today)) return;
        ref.read(viewDayProvider.notifier).show(d == today ? null : d);
      },
    );

    final Widget body;
    if (view != null && view != today) {
      body = _PastDay(day: view, strip: strip, schedule: sched);
    } else {
      body = _Today(strip: strip, schedule: sched);
    }
    return VScreen(child: body);
  }
}

// ---------------------------------------------------------------- today

class _Today extends ConsumerWidget {
  const _Today({required this.strip, required this.schedule});
  final Widget strip;
  final List<ScheduledDay> schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final profile = ref.watch(profileProvider)!;
    final key = ref.watch(todayKeyProvider);
    final entries = ref.watch(dayEntriesProvider(key)).value ?? const <LogEntry>[];
    final totals = DayTotals(entries);
    final dayOne = DateUtils.isSameDay(profile.startedOn, now);
    final week = now.difference(profile.startedOn).inDays ~/ 7 + 1;
    final date = DateFormat('EEE d MMM', Localizations.localeOf(context).toString()).format(now);
    final sub = dayOne ? l.todaySubDayOne(date) : l.todaySub(date, goalShort(l, profile.goal), week);

    return Column(
      children: [
        VAppBar(title: l.todayTitleEm, sub: sub, logo: true, right: const _AwardsButton()),
        strip,
        Expanded(
          child: Pad(
            children: [
              _Hero(schedule: schedule, week: week),
              _RingCard(totals: totals, targets: profile.targets, kcalTarget: profile.targetKcal),
              if (dayOne && entries.isEmpty) const _FirstRun(),
              _Meals(totals: totals, dayKey: key, canRepeat: true),
              const _Trend(),
              _Water(day: key, trained: schedule.where((d) => d.today).firstOrNull?.done != null),
            ],
          ),
        ),
      ],
    );
  }
}

/// The workout is the headline of the day.
class _Hero extends ConsumerWidget {
  const _Hero({required this.schedule, required this.week});
  final List<ScheduledDay> schedule;
  final int week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    final lib = ref.watch(exerciseLibraryProvider).value;
    final active = ref.watch(activeWorkoutProvider);
    final now = ref.watch(clockProvider)();
    final today = schedule.where((d) => d.today).firstOrNull;
    final planned = today?.routine;
    final r = planned == null ? null : routines.where((x) => x.id == planned.id).firstOrNull;
    final done = today?.done != null;
    final live = active != null && !done;

    if (routines.isEmpty) {
      return _HeroShell(
        tags: [_WoTag(l.noSessionPlanned, icon: 'dumb', ghost: true)],
        title: l.heroSetupTitle,
        body: Muted(l.heroSetupBody, color: Volt.t2),
        cta: _HeroCta(label: l.chooseRoutine, onTap: () => context.go('/train')),
      );
    }
    if (r == null && !live) {
      return _HeroShell(
        tags: [_WoTag(done ? l.heroTagDone : l.restDay, icon: done ? 'check' : 'clock', ghost: !done)],
        title: done ? l.heroDoneTitle(today!.done!.name) : l.heroRestTitle,
        body: Muted(done ? l.heroDoneBody : l.heroRestBody, color: Volt.t2),
        cta: _HeroCta(label: done ? l.savedSeeTrain : l.seeTheWeek, ghost: true, onTap: () => context.go('/train')),
        done: done,
      );
    }

    final items = r?.items ?? const <RoutineItem>[];
    final names = [for (final i in items) lib?[i.exerciseId]?.shortName ?? i.exerciseId];
    final muscles = {
      for (final i in items)
        if (lib?[i.exerciseId]?.primary.firstOrNull case final m?) groupOf(m),
    }.whereType<MuscleGroup>().length;
    final mins = planMinutes([for (final i in items) (i.sets, i.restSeconds)]);
    final title = live ? active.name : r!.name;
    final parts = title.split(' ');
    final em = parts.length > 1 ? '${parts.first} <em>${parts.skip(1).join(' ')}</em>' : '<em>$title</em>';

    return _HeroShell(
      done: done,
      tags: [
        _WoTag(done ? l.heroTagDone : (live ? l.heroTagInProgress : l.heroTagToday), icon: done ? 'check' : 'dumb'),
        _WoTag(l.heroWeekTag(week), ghost: true),
      ],
      title: em,
      stats: live
          ? null
          : [
              (fmtInt(context, mins), l.heroMin),
              (fmtInt(context, r!.totalSets), l.heroSets),
              (fmtInt(context, items.length), l.heroExercises),
              (fmtInt(context, muscles), l.heroMuscles),
            ],
      chips: live ? null : [...names.take(4), if (names.length > 4) l.moreCount(names.length - 4)],
      cta: done
          ? _HeroCta(label: l.savedSeeTrain, ghost: true, onTap: () => context.go('/train'))
          : live
          ? _HeroCta(
              label: l.resumeAt(fmtClock(active.elapsed(now))),
              icon: 'play',
              onTap: () => context.push('/workout'),
            )
          : _HeroCta(
              label: l.startWorkout,
              onTap: () async {
                if (lib == null) return;
                await ref.read(activeWorkoutProvider.notifier).startRoutine(r!, lib);
                if (context.mounted) context.push('/workout');
              },
            ),
    );
  }
}

class _HeroShell extends StatelessWidget {
  const _HeroShell({
    required this.tags,
    required this.title,
    required this.cta,
    this.body,
    this.stats,
    this.chips,
    this.done = false,
  });
  final List<Widget> tags;
  final String title;
  final Widget cta;
  final Widget? body;
  final List<(String, String)>? stats;
  final List<String>? chips;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: const Alignment(-0.42, -1),
          end: const Alignment(0.42, 1),
          colors: done ? const [Color(0xFF13261B), Volt.card] : const [Color(0xFF1C2410), Volt.card],
          stops: const [0, 0.62],
        ),
        boxShadow: done
            ? null
            : const [BoxShadow(color: Color(0x99B6F02A), blurRadius: 40, offset: Offset(0, 24), spreadRadius: -28)],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: done ? const Color(0x297CF0B0) : const Color(0x29C6F432)),
      ),
      child: Stack(
        children: [
          if (!done)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1, -1),
                    radius: 1.2,
                    colors: [Volt.brand.withValues(alpha: 0.26), Volt.brand.withValues(alpha: 0)],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
          // .wo-art: a big dumbbell, tilted, behind everything
          PositionedDirectional(
            end: -34,
            top: -26,
            child: Transform.rotate(
              angle: -28 * math.pi / 180,
              child: const Opacity(opacity: 0.14, child: VIcon('dumb', size: 180, color: Volt.brand, strokeWidth: 1.2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: GapCol(
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: tags),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: EmTitle(title, size: 36, letterSpacing: -0.035, height: 1, emScale: 1.12),
                ),
                ?body,
                if (stats != null)
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      for (final (v, label) in stats!)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v, style: numStyle(22, weight: FontWeight.w800, height: 1.1)),
                            const SizedBox(height: 1),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Volt.t3,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.22,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                if (chips != null && chips!.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in chips!)
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          decoration: BoxDecoration(
                            color: const Color(0x12FFFFFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Volt.t2),
                            ),
                          ),
                        ),
                    ],
                  ),
                Padding(padding: const EdgeInsets.only(top: 2), child: cta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WoTag extends StatelessWidget {
  const _WoTag(this.label, {this.icon, this.ghost = false});
  final String label;
  final String? icon;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final fg = ghost ? Volt.t2 : Volt.ink;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: ghost ? const Color(0x14FFFFFF) : Volt.brand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[VIcon(icon!, size: 14, color: fg, strokeWidth: 2), const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: ghost ? FontWeight.w600 : FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}

/// `.wo-cta`: the big pill with the round dark arrow at its end.
class _HeroCta extends StatelessWidget {
  const _HeroCta({required this.label, required this.onTap, this.ghost = false, this.icon = 'fwd'});
  final String label;
  final VoidCallback onTap;
  final bool ghost;
  final String icon;

  @override
  Widget build(BuildContext context) => VBtn(
    label: label,
    onTap: onTap,
    kind: ghost ? BtnKind.ghost : BtnKind.primary,
    minHeight: 58,
    padding: const EdgeInsetsDirectional.fromSTEB(22, 0, 6, 0),
    fontSize: 16,
    child: Row(
      children: [
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: ghost ? Volt.card : Volt.ink),
          child: VIcon(icon, size: icon == 'play' ? 18 : 20, color: ghost ? Volt.t1 : Volt.brand),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------- ring

/// The ring card: kcal left in a 108 px ring, macro bars beside it.
class _RingCard extends StatelessWidget {
  const _RingCard({required this.totals, required this.targets, required this.kcalTarget, this.closed = false});
  final DayTotals totals;
  final Macros targets;
  final double kcalTarget;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final empty = totals.entries.isEmpty && !closed;
    final left = kcalTarget - totals.kcal;
    final over = closed && totals.kcal > kcalTarget + 100;
    return VCard(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 108,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (totals.kcal / kcalTarget).clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: voltEase,
              builder: (context, f, child) => CustomPaint(
                painter: _Ring(fraction: f, empty: empty, color: closed ? (over ? Volt.warn : Volt.t3) : Volt.brand),
                child: child,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedNum(
                      empty ? kcalTarget : (closed ? totals.kcal : left),
                      from: empty || closed ? 0 : kcalTarget,
                      format: fmtInt,
                      style: numStyle(closed ? 24 : 26, height: 1.15, color: empty ? Volt.t2 : Volt.t1),
                    ),
                    Text(
                      empty
                          ? l.kcalToLog
                          : (closed ? l.kcalLoggedLabel : (left >= 0 ? l.kcalLeftLabel : l.kcalOverLabel)),
                      style: const TextStyle(fontSize: 11, color: Volt.t3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: empty
                ? GapCol(
                    gap: 8,
                    children: [
                      Text(l.ringEmptyBody, style: const TextStyle(fontSize: 13, color: Volt.t2)),
                      Muted(
                        l.targetsLine(
                          fmtInt(context, targets.protein),
                          fmtInt(context, targets.carbs),
                          fmtInt(context, targets.fat),
                        ),
                      ),
                    ],
                  )
                : GapCol(
                    cross: CrossAxisAlignment.stretch,
                    children: [
                      _MacroRow(
                        label: l.protein,
                        have: totals.macros.protein,
                        target: targets.protein,
                        color: Volt.protein,
                      ),
                      _MacroRow(label: l.carbs, have: totals.macros.carbs, target: targets.carbs, color: Volt.carbs),
                      _MacroRow(label: l.fat, have: totals.macros.fat, target: targets.fat, color: Volt.fat),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.label, required this.have, required this.target, required this.color});
  final String label;
  final double have;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) => GapCol(
    gap: 5,
    cross: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Volt.t2),
            ),
          ),
          AnimatedNum(have, format: fmtInt, style: numStyle(13)),
          const SizedBox(width: 5),
          Text(
            AppLocalizations.of(context).ofTarget(fmtInt(context, target)),
            style: numStyle(11, weight: FontWeight.w400, color: Volt.t3),
          ),
        ],
      ),
      VBar(fraction: target == 0 ? 0 : have / target, color: color),
    ],
  );
}

class _Ring extends CustomPainter {
  _Ring({required this.fraction, required this.empty, required this.color});
  final double fraction;
  final bool empty;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 46.0, w = 11.0;
    final track = Paint()
      ..color = Volt.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = empty ? StrokeCap.round : StrokeCap.butt;
    if (empty) {
      // stroke-dasharray="4 10" round
      const circ = 2 * math.pi * r;
      final n = (circ / 14).floor();
      for (var i = 0; i < n; i++) {
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * 2 * math.pi / n, 4 / r, false, track);
      }
      return;
    }
    canvas.drawCircle(c, r, track);
    if (fraction <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Ring o) => o.fraction != fraction || o.empty != empty || o.color != color;
}

// ---------------------------------------------------------------- meals

class _Meals extends ConsumerWidget {
  const _Meals({required this.totals, required this.dayKey, this.canRepeat = false, this.readOnly = false});
  final DayTotals totals;
  final String dayKey;
  final bool canRepeat;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return GapCol(
      gap: 8,
      cross: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(child: Eyebrow(l.meals)),
              if (readOnly)
                VChip(
                  label: l.copyToToday,
                  icon: 'repeat',
                  onTap: () async {
                    await ref.read(logActionsProvider).copyDay(dayKey);
                    ref.read(viewDayProvider.notifier).show(null);
                    if (context.mounted) showVToast(context, l.copiedToToday);
                  },
                )
              else if (canRepeat && totals.entries.isNotEmpty)
                VChip(
                  label: l.repeatYesterday,
                  icon: 'repeat',
                  onTap: () async {
                    final now = ref.read(clockProvider)();
                    final n = await ref
                        .read(logActionsProvider)
                        .copyDay(dayKeyOf(DateTime(now.year, now.month, now.day - 1)));
                    if (context.mounted) {
                      showVToast(context, n == 0 ? l.nothingYesterdayDay : l.yesterdayCopied, info: n == 0);
                    }
                  },
                ),
            ],
          ),
        ),
        VList(
          children: [for (final m in Meal.values) _MealItem(meal: m, entries: totals.inMeal(m), readOnly: readOnly)],
        ),
      ],
    );
  }
}

String dayKeyOf(DateTime d) => dayKey(d);

class _MealItem extends ConsumerWidget {
  const _MealItem({required this.meal, required this.entries, this.readOnly = false});
  final Meal meal;
  final List<LogEntry> entries;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final kcal = entries.fold<double>(0, (s, e) => s + e.kcal);
    final sub = entries.isEmpty
        ? l.nothingLogged
        : '${entries.take(3).map((e) => e.foodName.split(',').first).join(', ')} · ${l.itemsCount(entries.length)}';
    return VItem(
      semantics: mealName(l, meal),
      onTap: readOnly
          ? null
          : () => entries.isEmpty ? context.push('/add/${meal.name}') : context.push('/meal/${meal.name}'),
      children: [
        MealIco(meal: meal.index, on: entries.isNotEmpty),
        ItemText(mealName(l, meal), sub: sub),
        if (entries.isNotEmpty)
          Text(fmtInt(context, kcal), style: numStyle(14, color: Volt.t2))
        else if (!readOnly)
          const Pick(),
      ],
    );
  }
}

// ---------------------------------------------------------------- the rest

class _FirstRun extends StatelessWidget {
  const _FirstRun();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VCard(
      child: GapCol(
        cross: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.logFirstMeal,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
          ),
          VBtn(
            label: l.scanABarcode,
            onTap: () => context.push('/add/${Meal.breakfast.name}?mode=barcode'),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const VIcon('scan', size: 20, color: Volt.ink),
                const SizedBox(width: 12),
                Expanded(child: Text(l.scanABarcode)),
                Opacity(opacity: 0.85, child: Text(l.freeAlways, style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
          VBtn(
            label: l.searchDatabase,
            kind: BtnKind.ghost,
            onTap: () => context.push('/add/${Meal.breakfast.name}'),
            child: Row(
              children: [
                const VIcon('search', size: 20, color: Volt.t1),
                const SizedBox(width: 12),
                Expanded(child: Text(l.searchDatabase)),
              ],
            ),
          ),
          Muted(l.firstRunTip),
        ],
      ),
    );
  }
}

class _Trend extends ConsumerWidget {
  const _Trend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final w = ref.watch(weighInsProvider).value ?? const <(String, double)>[];
    final enough = w.length >= 7;
    final trend = trendWeights([for (final x in w) x.$2]);
    double? rate;
    if (enough) {
      final from = trend[trend.length - 7], to = trend.last;
      rate = observedRatePctPerWeek(fromKg: from, toKg: to, days: 7);
    }
    return VCard(
      tight: true,
      onTap: () => context.go('/progress'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Volt.brandWash, shape: BoxShape.circle),
            child: const VIcon('scale', size: 20, color: Volt.brandInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GapCol(
              gap: 3,
              children: [
                Muted(l.trendWeight),
                if (!enough) ...[
                  Text(
                    l.weighInsSoFar(w.length),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                  ),
                  Muted(l.trendNeedsDays),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(fmtDec(context, trend.last), style: numStyle(22)),
                      const SizedBox(width: 8),
                      Text(l.kgLbl, style: const TextStyle(fontSize: 13, color: Volt.t2)),
                      const SizedBox(width: 8),
                      Text(
                        l.ratePerWeekShort(fmtDec(context, rate!, digits: 2)),
                        style: numStyle(12, weight: FontWeight.w500, color: Volt.ok),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (enough)
            SizedBox(width: 112, height: 42, child: CustomPaint(painter: _Spark(w.map((e) => e.$2).toList(), trend))),
        ],
      ),
    );
  }
}

class _Spark extends CustomPainter {
  _Spark(this.raw, this.trend);
  final List<double> raw;
  final List<double> trend;

  @override
  void paint(Canvas canvas, Size size) {
    final r = raw.length > 10 ? raw.sublist(raw.length - 10) : raw;
    final t = trend.length > 10 ? trend.sublist(trend.length - 10) : trend;
    final all = [...r, ...t];
    final lo = all.reduce(math.min), hi = all.reduce(math.max);
    final span = (hi - lo).abs() < 0.01 ? 1 : hi - lo;
    Path line(List<double> v) {
      final p = Path();
      for (var i = 0; i < v.length; i++) {
        final x = 2 + (size.width - 4) * (v.length == 1 ? 0 : i / (v.length - 1));
        final y = 4 + (size.height - 8) * (1 - (v[i] - lo) / span);
        i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      return p;
    }

    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(line(r), stroke(Volt.line2, 1.5));
    canvas.drawPath(line(t), stroke(Volt.brand, 2.5));
  }

  @override
  bool shouldRepaint(_Spark o) => true;
}

const _waterBlue = Volt.blue;
const _waterWash = Color(0x1F4CC9F0);

/// The day's goal: the one the user set, or one from their weight.
int _goalFor(WidgetRef ref, {required bool trained}) =>
    ref.watch(waterGoalProvider) ?? waterGoalMl(weightKg: ref.watch(profileProvider)?.weightKg ?? 75, trained: trained);

Future<void> _drink(BuildContext context, WidgetRef ref, String day, int ml, int goal) async {
  final l = AppLocalizations.of(context);
  final before = ref.read(waterProvider(day)).ml;
  await ref.read(waterProvider(day).notifier).add(ml);
  if (!context.mounted) return;
  HapticFeedback.lightImpact();
  showVToast(context, before < goal && before + ml >= goal ? l.waterGoalReached : l.waterAddedMl(ml));
}

/// Hydration: today's water against a goal that knows your weight and
/// whether you trained, with one-tap amounts and the day's log behind it.
class _Water extends ConsumerWidget {
  const _Water({required this.day, required this.trained});
  final String day;
  final bool trained;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(waterProvider(day));
    final goal = _goalFor(ref, trained: trained);
    final done = d.ml >= goal;
    final auto = ref.watch(waterGoalProvider) == null;

    Widget quick(int ml, String label) => Expanded(
      child: Pressable(
        onTap: () => _drink(context, ref, day, ml, goal),
        label: l.addWaterMl(ml),
        radius: 14,
        child: Container(
          height: 52,
          decoration: BoxDecoration(color: Volt.card2, borderRadius: BorderRadius.circular(14)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('+${fmtInt(context, ml.toDouble())}', style: numStyle(14, color: Volt.t1)),
              const SizedBox(height: 1),
              Text(label, style: const TextStyle(fontSize: 11, color: Volt.t3)),
            ],
          ),
        ),
      ),
    );

    return VCard(
      onTap: () => _waterSheet(context, day: day, trained: trained),
      child: GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: _waterWash, shape: BoxShape.circle),
                child: const VIcon('drop', size: 20, color: _waterBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GapCol(
                  gap: 1,
                  children: [
                    Muted(l.hydration),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedNum(d.ml / 1000, format: (c, v) => fmtDec(c, v, digits: 2), style: numStyle(22)),
                        const SizedBox(width: 6),
                        Text(
                          l.ofLitres(fmtDec(context, goal / 1000)),
                          style: const TextStyle(fontSize: 13, color: Volt.t2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (done)
                Pop(
                  trigger: done,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: _waterWash, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VIcon('check', size: 14, color: _waterBlue),
                        const SizedBox(width: 4),
                        Text(
                          l.goalMet,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _waterBlue),
                        ),
                      ],
                    ),
                  ),
                )
              else
                AnimatedNum(
                  (d.ml * 100 / goal).clamp(0, 100).toDouble(),
                  format: (_, v) => '${v.round()}%',
                  style: numStyle(14, color: _waterBlue),
                ),
            ],
          ),
          VBar(fraction: d.ml / goal, color: _waterBlue, height: 8, track: Volt.card2),
          Row(
            children: [
              quick(250, l.waterGlass),
              const SizedBox(width: 8),
              quick(500, l.waterBottle),
              const SizedBox(width: 8),
              quick(750, l.waterLarge),
              const SizedBox(width: 8),
              Opacity(
                opacity: d.sips.isEmpty ? 0.4 : 1,
                child: IconBtn(
                  'repeat',
                  label: l.undoLastDrink,
                  size: 52,
                  iconSize: 18,
                  color: Volt.t2,
                  onTap: d.sips.isEmpty ? null : () => ref.read(waterProvider(day).notifier).undo(),
                ),
              ),
            ],
          ),
          if (auto && trained) Muted(l.waterTrainingBonus, color: Volt.t3),
        ],
      ),
    );
  }
}

/// The day's drinks, a custom amount, and the goal.
Future<void> _waterSheet(BuildContext context, {required String day, required bool trained}) {
  final l = AppLocalizations.of(context);
  var custom = 330;
  return showVSheet<void>(
    context,
    title: l.waterToday,
    body: (ctx) => [
      Consumer(
        builder: (ctx, ref, _) => StatefulBuilder(
          builder: (ctx, setState) {
            final d = ref.watch(waterProvider(day));
            final set = ref.watch(waterGoalProvider);
            final goal = _goalFor(ref, trained: trained);
            final auto = waterGoalMl(weightKg: ref.watch(profileProvider)?.weightKg ?? 75, trained: trained);
            String clock(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
            return GapCol(
              gap: 12,
              cross: CrossAxisAlignment.stretch,
              children: [
                if (d.sips.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.noWaterYet))
                else
                  VList(
                    children: [
                      for (final (i, x) in d.sips.indexed.toList().reversed)
                        VItem(
                          children: [
                            const VIcon('drop', size: 18, color: _waterBlue),
                            ItemText(
                              l.mlAmount(fmtInt(ctx, x.ml.toDouble())),
                              sub: x.minute == 0 && d.sips.length == 1 ? null : clock(x.minute),
                            ),
                            IconBtn(
                              'trash',
                              label: l.removeDrink,
                              size: 34,
                              iconSize: 16,
                              background: Colors.transparent,
                              color: Volt.t3,
                              onTap: () => ref.read(waterProvider(day).notifier).removeAt(i),
                            ),
                          ],
                        ),
                    ],
                  ),
                VCard(
                  color: Volt.card2,
                  tight: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l.otherAmount, style: const TextStyle(fontSize: 14, color: Volt.t1)),
                      ),
                      VStepper(
                        label: l.mlAmount(fmtInt(ctx, custom.toDouble())),
                        onMinus: custom > 50 ? () => setState(() => custom -= 50) : null,
                        onPlus: custom < 2000 ? () => setState(() => custom += 50) : null,
                      ),
                      const SizedBox(width: 8),
                      IconBtn(
                        'plus',
                        label: l.addWaterMl(custom),
                        size: 36,
                        iconSize: 16,
                        background: _waterBlue,
                        color: Volt.ink,
                        onTap: () => _drink(ctx, ref, day, custom, goal),
                      ),
                    ],
                  ),
                ),
                VCard(
                  color: Volt.card2,
                  tight: true,
                  child: GapCol(
                    gap: 10,
                    cross: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GapCol(
                              gap: 2,
                              children: [
                                Text(l.dailyGoal, style: const TextStyle(fontSize: 14, color: Volt.t1)),
                                Muted(set == null ? l.waterGoalAuto : l.waterGoalSet),
                              ],
                            ),
                          ),
                          VStepper(
                            label: l.litres(fmtDec(ctx, goal / 1000)),
                            onMinus: goal > 1000 ? () => ref.read(waterGoalProvider.notifier).set(goal - 250) : null,
                            onPlus: goal < 6000 ? () => ref.read(waterGoalProvider.notifier).set(goal + 250) : null,
                          ),
                        ],
                      ),
                      if (set != null)
                        VBtn(
                          label: l.useAutoGoal(fmtDec(ctx, auto / 1000)),
                          kind: BtnKind.ghost,
                          small: true,
                          expand: true,
                          onTap: () => ref.read(waterGoalProvider.notifier).set(null),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------- a closed day

class _PastDay extends ConsumerWidget {
  const _PastDay({required this.day, required this.strip, required this.schedule});
  final DateTime day;
  final Widget strip;
  final List<ScheduledDay> schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).toString();
    final profile = ref.watch(profileProvider)!;
    final key = dayKey(day);
    final totals = DayTotals(ref.watch(dayEntriesProvider(key)).value ?? const []);
    final diff = totals.kcal - profile.targetKcal;
    final sd = schedule.where((d) => d.date == day).firstOrNull;
    final note = diff.abs() < 120
        ? l.pastNoteWithin
        : (diff > 0 ? l.pastNoteOver(fmtInt(context, diff)) : l.pastNoteUnder(fmtInt(context, -diff)));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Row(
            children: [
              const VLogo(size: 37),
              const SizedBox(width: 12),
              Expanded(
                child: GapCol(
                  gap: 2,
                  children: [
                    Text(
                      DateFormat.EEEE(loc).format(day),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.475,
                        color: Volt.t1,
                      ),
                    ),
                    Text(
                      l.closedDay(DateFormat.MMMMd(loc).format(day)),
                      style: const TextStyle(fontSize: 12.5, color: Volt.t3),
                    ),
                  ],
                ),
              ),
              VChip(label: l.backToToday, onTap: () => ref.read(viewDayProvider.notifier).show(null)),
            ],
          ),
        ),
        strip,
        Expanded(
          child: Pad(
            children: [
              _RingCard(totals: totals, targets: profile.targets, kcalTarget: profile.targetKcal, closed: true),
              VCard(
                tight: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: VIcon('info', size: 17, color: Volt.t3),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Muted(note)),
                  ],
                ),
              ),
              _Meals(totals: totals, dayKey: key, readOnly: true),
              VCard(
                tight: true,
                onTap: sd?.done == null ? null : () => context.go('/train'),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Volt.card2),
                      child: VIcon(sd?.done != null ? 'dumb' : 'clock', size: 18, color: Volt.t2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GapCol(
                        gap: 2,
                        children: [
                          Muted(l.training),
                          Text(
                            sd?.done?.name ?? l.restDay,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                          ),
                        ],
                      ),
                    ),
                    if (sd?.done != null) const VIcon('fwd', size: 18, color: Volt.t3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String goalShort(AppLocalizations l, Goal g) => switch (g) {
  Goal.cut => l.goalShortCut,
  Goal.bulk => l.goalShortBulk,
  Goal.recomp => l.goalShortRecomp,
  Goal.maintain => l.goalShortMaintain,
  Goal.prep => l.goalShortPrep,
};

/// The way into Awards from Today: a lime medal that shows how many are won.
class _AwardsButton extends ConsumerWidget {
  const _AwardsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final earned = ref.watch(streakProvider).value?.awards.where((a) => a.earned).length ?? 0;
    return Pressable(
      onTap: () => context.go('/progress/awards'),
      label: l.awardsButton(earned),
      child: SizedBox.square(
        dimension: 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: Volt.glow,
                boxShadow: [
                  BoxShadow(color: Color(0xB3B6F02A), blurRadius: 22, offset: Offset(0, 8), spreadRadius: -8),
                ],
              ),
              child: const VIcon('medal', size: 26, color: Volt.ink, strokeWidth: 1.8),
            ),
            if (earned > 0)
              PositionedDirectional(
                top: -4,
                end: -4,
                child: Pop(
                  trigger: earned,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Volt.ink,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Volt.brand, width: 1.5),
                    ),
                    child: Text(
                      '$earned',
                      style: numStyle(11, weight: FontWeight.w800, color: Volt.brand),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
