import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import '../../data/models.dart';
import '../../domain/awards.dart';
import '../../domain/streak.dart';
import '../../l10n/app_localizations.dart';
import '../../state/awards_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'badge3d.dart';
import '../../state/config_providers.dart';

// ---------------------------------------------------------------- names

/// A pack award's or challenge's own text in the app's language.
String? _packText(Map<String, String>? by, String locale) =>
    by == null ? null : by[locale.split(RegExp('[_-]')).first] ?? by['en'] ?? by.values.firstOrNull;

String awardName(AppLocalizations l, Award a, DateTime now, String locale) =>
    _packText(a.names, locale) ?? _builtInName(l, a, now, locale);

String _builtInName(AppLocalizations l, Award a, DateTime now, String locale) => switch (a.id) {
  's7' => l.awFirstWeek,
  's14' => l.awTwoWeeks,
  's30' => l.awOneMonth,
  's66' => l.awHabit,
  's90' => l.awFull,
  'back' => l.awComeback,
  'f1' => l.awFirstFullDay,
  'f100' => l.awHundredMeals,
  'fp' => l.awProteinWeek,
  't1' => l.awFirstWorkout,
  't25' => l.awTwentyFive,
  'tpr' => l.awTenBests,
  _ => l.awMonth(DateFormat.MMMM(locale).format(now)),
};

String awardDesc(AppLocalizations l, Award a, [String locale = 'en']) =>
    _packText(a.descriptions, locale) ?? _builtInDesc(l, a);

String _builtInDesc(AppLocalizations l, Award a) => switch (a.id) {
  's7' => l.awFirstWeekD,
  's14' => l.awTwoWeeksD,
  's30' => l.awOneMonthD,
  's66' => l.awHabitD,
  's90' => l.awFullD,
  'back' => l.awComebackD,
  'f1' => l.awFirstFullDayD,
  'f100' => l.awHundredMealsD,
  'fp' => l.awProteinWeekD,
  't1' => l.awFirstWorkoutD,
  't25' => l.awTwentyFiveD,
  'tpr' => l.awTenBestsD,
  _ => l.awMonthD(a.need),
};

String _medalSmall(AppLocalizations l, String? s) => switch (s) {
  'DAYS' => l.mdDays,
  'MEALS' => l.mdMeals,
  'PROTEIN' => l.mdProtein,
  'WORKOUTS' => l.mdWorkouts,
  'BESTS' => l.mdBests,
  _ => s ?? '',
};

// ---------------------------------------------------------------- medal

const _tones = {
  MedalTone.lime: [Color(0xFFF4FFD0), Color(0xFFB6F02A), Color(0xFF3F6212)],
  MedalTone.gold: [Color(0xFFFEF3C7), Color(0xFFF59E0B), Color(0xFF78350F)],
  MedalTone.green: [Color(0xFFBBF7D0), Color(0xFF22C55E), Color(0xFF14532D)],
  MedalTone.orange: [Color(0xFFFED7AA), Color(0xFFF97316), Color(0xFF7C2D12)],
  MedalTone.blue: [Color(0xFFBFDBFE), Color(0xFF3B82F6), Color(0xFF1E3A8A)],
};

/// The prototype's medal: a hex, a disc or a shield, gradient when earned,
/// dark and outlined while locked.
class Medal extends StatelessWidget {
  const Medal({super.key, required this.award, required this.size, this.month});
  final Award award;
  final double size;

  /// The challenge medal shows the month instead of a number.
  final String? month;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = award.earned;
    if (badgeArt.containsKey(award.id)) {
      return Semantics(
        label: on ? l.earnedLabel : l.lockedLabel,
        child: BadgeFace(
          award: award,
          size: size,
          month: award.id == 'month'
              ? month ?? DateFormat.MMM(Localizations.localeOf(context).toString()).format(DateTime.now()).toUpperCase()
              : null,
        ),
      );
    }
    final ink = on ? Colors.white : Volt.t4;
    final k = size / 88;
    final big =
        month ??
        (on || award.group == AwardGroup.streak ? award.big : '${math.min(award.have, award.need)}/${award.need}');
    final fs = (big ?? '').length > 4 ? 16.0 : ((big ?? '').length > 3 ? 19.0 : 26.0);
    return Semantics(
      label: on ? l.earnedLabel : l.lockedLabel,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size.square(size), painter: _MedalPainter(award.shape, award.tone, on, size > 120)),
            if (award.icon != null)
              VIcon(award.icon!, size: 36 * k, color: ink, strokeWidth: 2)
            else
              Padding(
                padding: EdgeInsets.only(top: award.shape == MedalShape.shield ? 0 : 2 * k),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      big ?? '',
                      style: TextStyle(fontSize: fs * k, fontWeight: FontWeight.w800, color: ink, height: 1),
                    ),
                    if (award.small != null && month == null) ...[
                      SizedBox(height: 3 * k),
                      Text(
                        _medalSmall(l, award.small),
                        style: TextStyle(
                          fontSize: 7.5 * k,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1 * k,
                          color: ink,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.shape, this.tone, this.on, this.sheen);
  final MedalShape shape;
  final MedalTone tone;
  final bool on;
  final bool sheen;

  Path _outer(double k) => switch (shape) {
    MedalShape.hex =>
      Path()..addPolygon([
        for (final (x, y) in [(44.0, 3.0), (80.0, 23.5), (80.0, 64.5), (44.0, 85.0), (8.0, 64.5), (8.0, 23.5)])
          Offset(x * k, y * k),
      ], true),
    MedalShape.circle => Path()..addOval(Rect.fromCircle(center: Offset(44 * k, 44 * k), radius: 40 * k)),
    MedalShape.shield =>
      Path()
        ..moveTo(44 * k, 4 * k)
        ..lineTo(80 * k, 18 * k)
        ..lineTo(80 * k, 46 * k)
        ..cubicTo(80 * k, 66 * k, 64 * k, 78 * k, 44 * k, 85 * k)
        ..cubicTo(24 * k, 78 * k, 8 * k, 66 * k, 8 * k, 46 * k)
        ..lineTo(8 * k, 18 * k)
        ..close(),
  };

  Path _inner(double k) => switch (shape) {
    MedalShape.hex =>
      Path()..addPolygon([
        for (final (x, y) in [(44.0, 12.0), (72.0, 28.0), (72.0, 60.0), (44.0, 76.0), (16.0, 60.0), (16.0, 28.0)])
          Offset(x * k, y * k),
      ], true),
    MedalShape.circle => Path()..addOval(Rect.fromCircle(center: Offset(44 * k, 44 * k), radius: 32 * k)),
    MedalShape.shield =>
      Path()
        ..moveTo(44 * k, 14 * k)
        ..lineTo(71 * k, 24.5 * k)
        ..lineTo(71 * k, 46 * k)
        ..cubicTo(71 * k, 61 * k, 59 * k, 70.5 * k, 44 * k, 76 * k)
        ..cubicTo(29 * k, 70.5 * k, 17 * k, 61 * k, 17 * k, 46 * k)
        ..lineTo(17 * k, 24.5 * k)
        ..close(),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 88;
    final outer = _outer(k);
    if (on) {
      final c = _tones[tone]!;
      canvas.drawPath(
        outer,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c,
            stops: const [0, 0.5, 1],
          ).createShader(Offset.zero & size),
      );
      if (sheen && shape == MedalShape.hex) {
        canvas.drawPath(
          Path()
            ..moveTo(8 * k, 23.5 * k)
            ..lineTo(44 * k, 3 * k)
            ..lineTo(80 * k, 23.5 * k)
            ..lineTo(80 * k, 44 * k)
            ..lineTo(8 * k, 44 * k)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: 0.14),
        );
      }
      canvas.drawPath(
        _inner(k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * k
          ..color = Colors.white.withValues(alpha: 0.45),
      );
    } else {
      canvas.drawPath(outer, Paint()..color = Volt.card2);
      canvas.drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * k
          ..color = Volt.line2,
      );
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.on != on || old.tone != tone || old.shape != shape;
}

/// Three rings: the commitment, today's meals, today's training.
class StreakRings extends StatelessWidget {
  const StreakRings({super.key, required this.info, required this.size, this.onLime = false});
  final StreakInfo info;
  final double size;
  final bool onLime;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _RingsPainter([
      (math.min(1.0, info.kept / info.goal), onLime ? Volt.ink : Volt.lime),
      (info.mealsToday / 3, onLime ? const Color(0xFF14532D) : Volt.ok),
      (
        info.trainedToday || (info.restToday && info.mealsToday == 3) ? 1.0 : 0.0,
        onLime ? const Color(0xFF7C2D12) : Volt.orange,
      ),
    ], onLime ? Colors.black.withValues(alpha: 0.12) : Volt.line),
  );
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.rings, this.track);
  final List<(double, Color)> rings;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 120;
    final c = size.center(Offset.zero);
    for (final (i, (p, color)) in rings.indexed) {
      final r = [46.0, 32.0, 18.0][i] * k;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * k
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(c, r, stroke..color = track);
      if (p > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          2 * math.pi * math.max(0.01, p),
          false,
          stroke..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => true;
}

// ---------------------------------------------------------------- the card on Progress

/// The Progress tab's way into awards: a lime card with the rings.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(streakProvider).value;
    if (s == null) return const SizedBox.shrink();
    final next = nextStreakAward(s.awards);
    final loc = Localizations.localeOf(context).toString();
    final now = ref.watch(clockProvider)();
    return Pressable(
      onTap: () => context.push('/progress/awards'),
      scale: 0.99,
      label: l.awardsTitle,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(gradient: Volt.glow, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            StreakRings(info: s, size: 60, onLime: true),
            const SizedBox(width: 14),
            Expanded(
              child: GapCol(
                gap: 2,
                children: [
                  Text(
                    l.commitmentDays(s.goal).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: Color(0xFF243B06),
                    ),
                  ),
                  Text(
                    l.keptOfGoal(s.kept, s.goal),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Volt.ink),
                  ),
                  Text(
                    next == null
                        ? l.allStreakAwards
                        : l.nextAwardIn(awardName(l, next, now, loc), next.need - s.state.best),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2E4A0A)),
                  ),
                ],
              ),
            ),
            const VIcon('fwd', size: 18, color: Color(0xFF2E4A0A)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- awards

class AwardsScreen extends ConsumerWidget {
  const AwardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(streakProvider).value;
    final now = ref.watch(clockProvider)();
    final loc = Localizations.localeOf(context).toString();
    if (s == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: VScreen(child: SizedBox.shrink()),
      );
    }
    final day = s.kept + (s.keptToday ? 0 : 1);
    final month = s.awards.firstWhere((a) => a.id == 'month');
    final daysLeft = DateUtils.getDaysInMonth(now.year, now.month) - now.day;

    Widget legend(Color c, String t) => Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(t, style: TextStyle(fontSize: 12, color: Volt.t2)),
        ),
      ],
    );

    final Widget nudge;
    if (s.goalDone) {
      nudge = _Nudge(
        icon: 'star',
        color: const Color(0xFFF59E0B),
        text: l.goalReached(s.goal),
        action: l.seeRecap,
        onAction: () => context.push('/goal/done'),
      );
    } else if (s.keptToday) {
      nudge = _Nudge(icon: 'check', color: Volt.ok, text: l.dayKept(day));
    } else if (s.mealsToday < 3) {
      nudge = Consumer(
        builder: (context, ref, _) {
          final entries = ref.watch(dayEntriesProvider(dayKey(now))).value ?? const <LogEntry>[];
          final have = {for (final e in entries) e.meal};
          final m = [
            Meal.breakfast,
            Meal.lunch,
            Meal.dinner,
          ].firstWhere((x) => !have.contains(x), orElse: () => Meal.dinner);
          return _Nudge(
            icon: 'food',
            color: Volt.ok,
            text: l.logToKeep(mealName(l, m).toLowerCase(), day),
            action: l.logBtn,
            onAction: () => context.push('/add/${m.name}'),
          );
        },
      );
    } else {
      nudge = _Nudge(
        icon: 'dumb',
        color: Volt.orange,
        text: l.trainToKeep(s.plannedToday ?? l.workoutDefaultName, day),
        action: l.trainBtn,
        onAction: () => context.go('/train'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VScreen(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Row(
                children: [
                  IconBtn(
                    'back',
                    small: true,
                    iconSize: 18,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: () => context.canPop() ? context.pop() : context.go('/progress'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: EmTitle(l.awardsTitleEm)),
                  VChip(label: l.editGoal, onTap: () => context.push('/goal')),
                ],
              ),
            ),
            Expanded(
              child: Pad(
                children: [
                  VCard(
                    child: GapCol(
                      gap: 16,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            StreakRings(info: s, size: 124),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GapCol(
                                gap: 10,
                                children: [
                                  GapCol(
                                    gap: 2,
                                    children: [
                                      Muted(l.commitmentDays(s.goal)),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text('${s.kept}', style: numStyle(30, weight: FontWeight.w700, height: 1.1)),
                                          const SizedBox(width: 6),
                                          Text(l.ofDays(s.goal), style: TextStyle(fontSize: 14, color: Volt.t2)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  GapCol(
                                    gap: 5,
                                    children: [
                                      legend(Volt.lime, l.legendStreak(math.max(0, s.goal - s.kept))),
                                      legend(Volt.ok, l.legendFood(s.mealsToday)),
                                      legend(
                                        Volt.orange,
                                        s.trainedToday
                                            ? l.legendTrainDone
                                            : (s.restToday ? l.legendRest : l.legendPlanned(s.plannedToday ?? '')),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        nudge,
                        GapCol(
                          gap: 8,
                          cross: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l.thisWeek,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Volt.t1),
                                  ),
                                ),
                                Muted(l.restDaysCount),
                              ],
                            ),
                            _Week(info: s, now: now),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _Stat(label: l.bestStreak, value: l.nDays(math.max(s.state.best, s.kept))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Stat(
                                label: l.freezesLbl,
                                value: l.freezesOf(s.state.freezes, maxFreezes),
                                icon: VIcon('freeze', size: 16, color: Volt.blue),
                              ),
                            ),
                          ],
                        ),
                        const _PauseRow(),
                      ],
                    ),
                  ),
                  // The month's challenge sits on the lime glow, as the prototype draws it.
                  if (ref.watch(remoteConfigProvider).monthlyChallenge)
                    Pressable(
                      onTap: () => context.push('/progress/award/month'),
                      scale: 0.99,
                      label: awardName(l, month, now, loc),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(gradient: Volt.glow, borderRadius: BorderRadius.circular(24)),
                        child: Row(
                          children: [
                            // The challenge under way shows in colour, done or not.
                            BadgeFace(
                              award: month,
                              size: 58,
                              month: DateFormat.MMM(loc).format(now).toUpperCase(),
                              dim: false,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: GapCol(
                                gap: 6,
                                cross: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          awardName(l, month, now, loc),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Volt.ink,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${math.min(month.have, month.need)} / ${month.need}',
                                        textDirection: TextDirection.ltr,
                                        style: numStyle(12, color: const Color(0xFF2E4A0A)),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    month.earned ? l.challengeDone(month.need) : l.challengeLeft(month.need, daysLeft),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF2E4A0A)),
                                  ),
                                  VBar(
                                    fraction: math.min(1, month.have / month.need),
                                    color: Volt.ink,
                                    track: const Color(0x2E000000),
                                    height: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _Shelf(title: l.shelfStreaks, awards: s.awards.where((a) => a.group == AwardGroup.streak).toList()),
                  _Shelf(title: l.shelfFood, awards: s.awards.where((a) => a.group == AwardGroup.food).toList()),
                  _Shelf(
                    title: l.shelfTraining,
                    awards: s.awards.where((a) => a.group == AwardGroup.training).toList(),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 0), child: Muted(l.awardsNote)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Nudge extends StatelessWidget {
  const _Nudge({required this.icon, required this.color, required this.text, this.action, this.onAction});
  final String icon;
  final Color color;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Volt.bg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Volt.line),
    ),
    child: Row(
      children: [
        VIcon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Volt.t2)),
        ),
        if (action != null)
          VBtn(
            label: action!,
            small: true,
            minHeight: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: onAction,
          ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: Volt.bg, borderRadius: BorderRadius.circular(18)),
    child: GapCol(
      gap: 2,
      children: [
        Muted(label),
        Row(
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 6)],
            Text(value, style: numStyle(16)),
          ],
        ),
      ],
    ),
  );
}

/// Monday to Sunday: kept, kept on a rest day, open, today, ahead.
class _Week extends StatelessWidget {
  const _Week({required this.info, required this.now});
  final StreakInfo info;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    final today = DateTime(now.year, now.month, now.day);
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          () {
            final d = DateTime(monday.year, monday.month, monday.day + i);
            final mark = info.state.marks[d];
            final isToday = d == today;
            final kept = mark == DayMark.kept;
            final Widget dot;
            if (kept && info.restKept.contains(d)) {
              dot = _dot(
                fill: Volt.brandWash,
                border: Volt.lime,
                child: VIcon('moon', size: 16, color: Volt.brandInk),
              );
            } else if (kept) {
              dot = _dot(
                fill: Volt.lime,
                child: const VIcon('check', size: 16, color: Volt.ink, strokeWidth: 2.4),
              );
            } else if (isToday) {
              dot = _dot(
                border: Volt.lime,
                dashed: true,
                child: Text('${d.day}', style: numStyle(12, color: Volt.t1)),
              );
            } else if (mark == DayMark.frozen) {
              dot = _dot(
                fill: const Color(0x1A4CC9F0),
                child: VIcon('freeze', size: 15, color: Volt.blue),
              );
            } else if (mark == DayMark.repairable) {
              dot = _dot(
                border: Volt.warn,
                dashed: true,
                child: Text('${d.day}', style: numStyle(12, color: Volt.warn)),
              );
            } else {
              dot = _dot(
                border: Volt.line2,
                child: Text(
                  '${d.day}',
                  style: numStyle(12, weight: FontWeight.w500, color: Volt.t4),
                ),
              );
            }
            return Column(
              children: [
                Text(
                  DateFormat.EEEEE(loc).format(d),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? Volt.t1 : Volt.t3,
                  ),
                ),
                const SizedBox(height: 6),
                dot,
              ],
            );
          }(),
      ],
    );
  }

  Widget _dot({Color? fill, Color? border, bool dashed = false, required Widget child}) => SizedBox.square(
    dimension: 34,
    child: CustomPaint(
      painter: border == null ? null : _Ring(border, dashed),
      child: Container(
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child,
      ),
    ),
  );
}

class _Ring extends CustomPainter {
  _Ring(this.color, this.dashed);
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final r = Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5);
    if (!dashed) return canvas.drawOval(r, p);
    for (var a = 0.0; a < 2 * math.pi; a += 2 * math.pi / 16) {
      canvas.drawArc(r, a, 2 * math.pi / 32, false, p);
    }
  }

  @override
  bool shouldRepaint(_Ring old) => old.color != color || old.dashed != dashed;
}

class _Shelf extends ConsumerWidget {
  const _Shelf({required this.title, required this.awards});
  final String title;
  final List<Award> awards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final loc = Localizations.localeOf(context).toString();
    final got = awards.where((a) => a.earned).length;
    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
                ),
              ),
              Muted(l.gotOf(got, awards.length)),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (_, c) {
            final w = (c.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 14,
              children: [
                for (final a in awards)
                  SizedBox(
                    width: w,
                    child: Pressable(
                      onTap: () => context.push('/progress/award/${a.id}'),
                      label: awardName(l, a, now, loc),
                      child: Column(
                        children: [
                          Medal(award: a, size: 76),
                          const SizedBox(height: 6),
                          Text(
                            awardName(l, a, now, loc),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              color: a.earned ? Volt.t1 : Volt.t2,
                            ),
                          ),
                          Text(
                            awardStatus(l, a, loc),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, height: 1.3, color: Volt.t3),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

String awardStatus(AppLocalizations l, Award a, String loc) {
  if (a.earned) return a.earnedOn == null ? l.earnedLbl : DateFormat.MMMd(loc).format(a.earnedOn!);
  if (a.id == 'back') return l.restartAfterBreak;
  return l.nToGo(a.toGo);
}

// ---------------------------------------------------------------- detail

class AwardDetailScreen extends ConsumerWidget {
  const AwardDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(streakProvider).value;
    final now = ref.watch(clockProvider)();
    final loc = Localizations.localeOf(context).toString();
    final a = s?.awards.where((x) => x.id == id).firstOrNull;
    if (s == null || a == null) return const Scaffold(body: VScreen(child: SizedBox.shrink()));
    final name = awardName(l, a, now, loc);
    final next = a.group == AwardGroup.streak && a.earned ? nextStreakAward(s.awards) : null;
    final monthLabel = DateFormat.MMM(loc).format(now).toUpperCase();
    final engravedDate = DateFormat.yMMMMd(loc).format(a.earnedOn ?? now);
    final status = a.earned
        ? (a.earnedOn == null ? l.earnedLbl : l.earnedOn(DateFormat.yMMMd(loc).format(a.earnedOn!)))
        : awardStatus(l, a, loc);

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: '', titleSize: 1),
            Expanded(
              child: Pad(
                bottom: 24,
                children: [
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: a.earned
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [_tones[a.tone]![1].withValues(alpha: 0.35), Colors.transparent],
                              ),
                            )
                          : BoxDecoration(shape: BoxShape.circle, color: Volt.card),
                      alignment: Alignment.center,
                      child: badgeArt.containsKey(a.id)
                          ? Badge3D(
                              award: a,
                              size: 216,
                              month: a.id == 'month' ? monthLabel : null,
                              name: name,
                              date: engravedDate,
                              backLabel: l.badgeBackLabel(name, engravedDate),
                            )
                          : Medal(award: a, size: 196, month: a.id == 'month' ? monthLabel : null),
                    ),
                  ),
                  if (a.earned && badgeArt.containsKey(a.id))
                    Text(
                      l.badgeTurnHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Volt.t3),
                    ),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, color: Volt.t1),
                  ),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Volt.t3),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        awardDesc(l, a, loc),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, height: 1.5, color: Volt.t2),
                      ),
                    ),
                  ),
                  if (!a.earned && a.need > 1)
                    VCard(
                      tight: true,
                      child: GapCol(
                        gap: 8,
                        cross: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.progressLbl,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Volt.t1),
                                ),
                              ),
                              Text(
                                '${a.have} / ${a.need}',
                                textDirection: TextDirection.ltr,
                                style: numStyle(12, color: Volt.t2),
                              ),
                            ],
                          ),
                          VBar(fraction: a.have / a.need, color: Volt.lime, height: 8),
                        ],
                      ),
                    ),
                  if (next != null)
                    VCard(
                      tight: true,
                      child: Row(
                        children: [
                          Medal(award: next, size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: GapCol(
                              gap: 6,
                              cross: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l.nextNamed(awardName(l, next, now, loc)),
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Volt.t1),
                                      ),
                                    ),
                                    Text(
                                      '${next.have} / ${next.need}',
                                      textDirection: TextDirection.ltr,
                                      style: numStyle(12, color: Volt.t2),
                                    ),
                                  ],
                                ),
                                VBar(fraction: next.have / next.need, color: Volt.lime, height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
              child: a.earned
                  ? VBtn(
                      label: l.shareAward,
                      expand: true,
                      onTap: () => SharePlus.instance.share(ShareParams(text: l.shareAwardText(name))),
                    )
                  : VBtn(label: l.backToAwards, kind: BtnKind.ghost, expand: true, onTap: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- commitment

class GoalSetScreen extends ConsumerStatefulWidget {
  const GoalSetScreen({super.key});

  @override
  ConsumerState<GoalSetScreen> createState() => _GoalSetScreenState();
}

class _GoalSetScreenState extends ConsumerState<GoalSetScreen> {
  int? _pick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(streakProvider).value;
    final goal = ref.watch(commitmentGoalProvider);
    final now = ref.watch(clockProvider)();
    final loc = Localizations.localeOf(context).toString();
    final pick = _pick ?? goal;
    final kept = s?.kept ?? 0;
    final tooShort = pick <= kept;
    final finish = DateTime(now.year, now.month, now.day + (pick - kept - 1));
    final options = [(21, l.goal21), (30, l.goal30), (66, l.goal66), (90, l.goal90)];

    Widget option(int days, String sub) {
      final on = pick == days;
      return Pressable(
        onTap: () => setState(() => _pick = days),
        scale: 0.98,
        label: l.nDays(days),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: on ? Volt.brandWash : Volt.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: on ? Volt.lime : Volt.line, width: on ? 1.5 : 1),
          ),
          child: GapCol(
            gap: 2,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$days', style: numStyle(22, weight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Muted(l.daysWord),
                ],
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? Volt.t1 : Volt.t2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget rule(String icon, Color c, String title, String sub) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Volt.card2, shape: BoxShape.circle),
            child: Center(child: VIcon(icon, size: 16, color: c)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GapCol(
              gap: 0,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Volt.t1),
                ),
                Muted(sub),
              ],
            ),
          ),
          VIcon('check', size: 18, color: Volt.brandInk),
        ],
      ),
    );

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(
              title: l.yourCommitment,
              icon: 'close',
              backLabel: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
            Expanded(
              child: Pad(
                bottom: 24,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GapCol(
                      gap: 4,
                      children: [
                        Text(
                          l.howLong,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, color: Volt.t1),
                        ),
                        Muted(l.howLongSub, size: 13),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (_, c) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (d, sub) in options) SizedBox(width: (c.maxWidth - 10) / 2, child: option(d, sub)),
                      ],
                    ),
                  ),
                  SRow(
                    label: l.customLbl,
                    trail: Muted(l.customRange),
                    on: !options.any((o) => o.$1 == pick),
                    onTap: () => _custom(context),
                  ),
                  VCard(
                    child: GapCol(
                      gap: 4,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            l.dayCountsWhen,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                          ),
                        ),
                        rule('food', Volt.ok, l.ruleMeals, l.ruleMealsSub),
                        rule('dumb', Volt.orange, l.ruleTrain, l.ruleTrainSub),
                      ],
                    ),
                  ),
                  VCard(
                    tight: true,
                    child: Row(
                      children: [
                        VIcon('freeze', size: 20, color: Volt.blue),
                        const SizedBox(width: 12),
                        Expanded(child: Muted(l.freezeNote(daysPerFreeze, maxFreezes), color: Volt.t2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
              child: GapCol(
                gap: 8,
                cross: CrossAxisAlignment.stretch,
                children: [
                  VBtn(
                    label: tooShort ? l.alreadyPast(pick) : (pick == goal ? l.keepMyDays(pick) : l.commitTo(pick)),
                    expand: true,
                    onTap: tooShort
                        ? null
                        : () async {
                            await setCommitment(ref, pick);
                            if (context.mounted) context.pop();
                          },
                  ),
                  Text(
                    kept > 0
                        ? l.carryOver(kept, DateFormat.MMMEd(loc).format(finish))
                        : l.startsToday(DateFormat.MMMEd(loc).format(finish)),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Volt.t3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _custom(BuildContext context) async {
    final l = AppLocalizations.of(context);
    var v = '${_pick ?? 45}';
    await showVSheet<void>(
      context,
      title: l.customLbl,
      body: (ctx) => [
        StatefulBuilder(
          builder: (ctx, set) {
            final n = int.tryParse(v) ?? 0;
            return GapCol(
              gap: 12,
              cross: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(v.isEmpty ? '—' : v, style: numStyle(44, height: 1.05)),
                    const SizedBox(width: 6),
                    Text(l.daysWord, style: TextStyle(fontSize: 18, color: Volt.t2)),
                  ],
                ),
                Muted(l.customRange),
                Keypad(
                  decimal: '',
                  deleteLabel: l.deleteDigit,
                  onKey: (k) => set(() {
                    if (k == 'del') {
                      v = v.isEmpty ? v : v.substring(0, v.length - 1);
                    } else if (k.isNotEmpty && v.length < 3) {
                      v = v == '0' ? k : v + k;
                    }
                  }),
                ),
                VBtn(
                  label: l.useThis,
                  expand: true,
                  onTap: n < 7 || n > 365
                      ? null
                      : () {
                          setState(() => _pick = n);
                          Navigator.pop(ctx);
                        },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The commitment reached: a gold medal and what the run held.
class GoalDoneScreen extends ConsumerWidget {
  const GoalDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(streakProvider).value;
    final loc = Localizations.localeOf(context).toString();
    if (s == null) return const Scaffold(body: VScreen(child: SizedBox.shrink()));
    final gold = Award(
      id: 'goal',
      group: AwardGroup.streak,
      shape: MedalShape.hex,
      tone: MedalTone.gold,
      big: '${s.goal}',
      small: 'DAYS',
      need: 1,
      have: 1,
    );
    final kept = s.state.marks.entries.where((e) => e.value == DayMark.kept).map((e) => e.key).toList()..sort();
    final frozen = s.state.marks.values.where((m) => m == DayMark.frozen).length;
    final from = kept.isEmpty ? DateTime.now() : kept.first;
    final to = kept.isEmpty ? DateTime.now() : kept.last;
    int count(String id) => s.awards.firstWhere((a) => a.id == id).have;
    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconBtn('close', small: true, iconSize: 18, label: l.backToAwards, onTap: () => context.pop()),
              ),
            ),
            Expanded(
              child: Pad(
                bottom: 24,
                children: [
                  Center(
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [Color(0x59F59E0B), Colors.transparent]),
                      ),
                      alignment: Alignment.center,
                      child: Medal(award: gold, size: 168),
                    ),
                  ),
                  Eyebrow(l.awFull, color: const Color(0xFFF59E0B), padding: EdgeInsets.zero),
                  Text(
                    l.goalDoneTitle(s.goal),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, color: Volt.t1),
                  ),
                  Text(
                    l.goalDoneSub(DateFormat.MMMd(loc).format(from), DateFormat.MMMEd(loc).format(to), frozen),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Volt.t3),
                  ),
                  LayoutBuilder(
                    builder: (_, c) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (k, v, color) in [
                          (l.workoutsLbl, count('t25'), Volt.orange),
                          (l.restDaysKept, s.restKept.length, Volt.t1),
                          (l.mealsLoggedLbl, count('f100'), Volt.ok),
                          (l.personalBests, count('tpr'), Volt.t1),
                        ])
                          SizedBox(
                            width: (c.maxWidth - 10) / 2,
                            child: VCard(
                              tight: true,
                              child: GapCol(
                                gap: 3,
                                children: [
                                  Muted(k),
                                  Text(
                                    '$v',
                                    style: numStyle(22, weight: FontWeight.w700, color: color),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    l.goalDoneNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.5, color: Volt.t2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
              child: GapCol(
                gap: 8,
                cross: CrossAxisAlignment.stretch,
                children: [
                  VBtn(
                    label: l.shareMyDays(s.goal),
                    expand: true,
                    onTap: () => SharePlus.instance.share(ShareParams(text: l.shareGoalText(s.goal))),
                  ),
                  VBtn(
                    label: l.setNextCommitment,
                    kind: BtnKind.ghost,
                    expand: true,
                    onTap: () => context.pushReplacement('/goal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ill or away: pause the streak instead of watching it break.
class _PauseRow extends ConsumerWidget {
  const _PauseRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final pause = ref.watch(streakPauseProvider);
    final active = pause != null && !pause.$2.isBefore(today);
    final until = active ? DateFormat('d MMM', Localizations.localeOf(context).toString()).format(pause.$2) : '';

    void sheet() => showVSheet<void>(
      context,
      title: active ? l.pausedUntil(until) : l.pauseStreak,
      body: (ctx) => [
        Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 4), child: Muted(l.pauseSub)),
        if (active)
          SRow(
            label: l.endPause,
            tint: Volt.brandInk,
            onTap: () {
              Navigator.pop(ctx);
              setStreakPause(ref, 0);
            },
          )
        else
          RGrid(
            columns: 3,
            children: [
              for (final n in [3, 7, 14])
                RChip(
                  label: l.nDays(n),
                  on: false,
                  onTap: () {
                    Navigator.pop(ctx);
                    setStreakPause(ref, n);
                    showVToast(context, l.streakPaused(n));
                  },
                ),
            ],
          ),
      ],
    );

    return Pressable(
      onTap: sheet,
      label: active ? l.pausedUntil(until) : l.pauseStreak,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0x1A4CC9F0) : Volt.tint.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            VIcon(active ? 'play' : 'moon', size: 16, color: active ? Volt.blue : Volt.t2),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                active ? l.pausedUntil(until) : l.pauseStreak,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Volt.t1),
              ),
            ),
            Text(active ? l.endPause : l.pauseHint, style: TextStyle(fontSize: 12.5, color: Volt.t3)),
          ],
        ),
      ),
    );
  }
}
