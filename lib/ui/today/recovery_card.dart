import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/recovery.dart';
import '../../l10n/app_localizations.dart';
import '../../state/health_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

String workoutKindName(AppLocalizations l, WorkoutKind k) => switch (k) {
  WorkoutKind.run => l.kindRun,
  WorkoutKind.walk => l.kindWalk,
  WorkoutKind.ride => l.kindRide,
  WorkoutKind.swim => l.kindSwim,
  WorkoutKind.strength => l.kindStrength,
  WorkoutKind.hiit => l.kindHiit,
  WorkoutKind.yoga => l.kindYoga,
  WorkoutKind.other => l.kindOther,
};

/// The heart's own colour, the same in both looks.
const heartRed = Color(0xFFFF5C7A);
const _hrvTeal = Color(0xFF2EC4B6);

/// Last night's sleep, resting heart rate and HRV against the person's own
/// normal, as three tiles, and one line on how
/// hard to go today. Until the watch reads are allowed it asks once instead.
class RecoveryCard extends ConsumerWidget {
  const RecoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(watchReadsAskedProvider)) return const _Ask();
    final r = ref.watch(recoveryProvider).value;
    if (r == null || !r.hasBody) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    final (word, tone, head, advice) = switch (r.readiness) {
      Readiness.ready => (l.readyReady, Volt.ok, l.headReady, l.adviceReady),
      Readiness.steady => (l.readySteady, Volt.orange, l.headSteady, l.adviceSteady),
      Readiness.easy => (l.readyEasy, heartRed, l.headEasy, l.adviceEasy),
      Readiness.learning => (l.readyLearning, Volt.t3, l.headLearning, l.adviceLearning),
    };

    String hm(int min) => min < 60 ? l.minutesOnly(min) : l.hoursMinutes(min ~/ 60, min % 60);
    String signed(double d, String Function(double) show) => '${d > 0 ? '+' : '−'}${show(d)}';
    (String, Color)? short(
      double now,
      double? base, {
      required double near,
      required bool up,
      required String Function(double) show,
    }) {
      if (base == null) return null;
      final d = now - base;
      if (d.abs() <= near) return null;
      return (signed(d, show), (d > 0) == up ? Volt.ok : heartRed);
    }

    final chips = [
      if (r.sleepMin case final s?)
        _Chip(
          icon: 'moon',
          color: Volt.violet,
          value: hm(s),
          delta: short(s.toDouble(), r.sleepBase, near: 15, up: true, show: (d) => hm(d.abs().round())),
          label: l.recoverySleep,
        ),
      if (r.restingHr case final h?)
        _Chip(
          icon: 'pulse',
          color: heartRed,
          value: '${h.round()} ${l.bpmUnit}',
          delta: short(h, r.restingBase, near: 2, up: false, show: (d) => '${d.abs().round()}'),
          label: l.recoveryRestingHr,
        ),
      if (r.hrv case final v?)
        _Chip(
          icon: 'heart',
          color: _hrvTeal,
          value: '${v.round()} ${l.msUnit}',
          delta: short(v, r.hrvBase, near: (r.hrvBase ?? 0) * 0.05, up: true, show: (d) => '${d.abs().round()}'),
          label: l.recoveryHrv,
        ),
    ];

    return VCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Gauge(score: r.score, tone: tone, word: word, label: l.readinessLbl),
              const SizedBox(width: 14),
              Expanded(
                child: GapCol(
                  gap: 3,
                  children: [
                    Text(
                      word.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: tone),
                    ),
                    Text(
                      head,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2, color: Volt.t1),
                    ),
                    Text(
                      advice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, height: 1.3, color: Volt.t2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: chips[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Steps and active energy side by side, each against its average, and any
/// workout a watch recorded today. Only there once health is connected.
class ActivityTiles extends ConsumerWidget {
  const ActivityTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepsWeekProvider).value;
    final r = ref.watch(recoveryProvider).value;
    final l = AppLocalizations.of(context);
    String? avg(List<double?> week) {
      final past = week.take(week.length - 1).whereType<double>();
      return past.isEmpty ? null : l.avgShort(fmtInt(context, past.reduce((a, b) => a + b) / past.length));
    }

    final tiles = [
      if (steps != null && steps.last != null)
        MetricTile(
          icon: 'shoe',
          color: Volt.orange,
          label: l.healthSteps,
          value: fmtInt(context, steps.last!),
          unit: l.stepsUnit,
          sub: switch (avg(steps)) {
            final a? => (a, Volt.t3),
            null => null,
          },
          big: true,
        ),
      if (r?.activeKcal case final k?)
        MetricTile(
          icon: 'flame',
          color: heartRed,
          label: l.healthActive,
          value: fmtInt(context, k),
          unit: l.kcal,
          sub: switch (avg(r!.kcalWeek)) {
            final a? => (a, Volt.t3),
            null => null,
          },
          big: true,
        ),
    ];
    final workouts = r?.workouts ?? const <WatchWorkout>[];
    if (tiles.isEmpty && workouts.isEmpty) return const SizedBox.shrink();
    return GapCol(
      gap: 10,
      cross: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(title: l.activityTitle),
        if (tiles.isNotEmpty)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          ),
        for (final w in workouts)
          VCard(
            tight: true,
            child: _Line(
              icon: 'watch',
              color: Volt.ok,
              text: l.watchWorkoutLine(workoutKindName(l, w.kind), w.length.inMinutes, w.source),
              sub: l.watchCountsStreak,
            ),
          ),
      ],
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Volt.t1),
          ),
        ),
      ],
    ),
  );
}

/// One number with its icon and how it compares.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.unit,
    this.sub,
    this.big = false,
  });
  final String icon;
  final Color color;
  final String label;
  final String value;
  final String? unit;
  final (String, Color)? sub;

  /// Two to a row rather than three: a larger number and wider bars.
  final bool big;

  @override
  Widget build(BuildContext context) => VCard(
    padding: EdgeInsets.all(big ? 14 : 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Volt.t2),
              ),
            ),
            _Dot(icon: icon, color: color, size: big ? 30 : 26),
          ],
        ),
        SizedBox(height: big ? 10 : 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: ltr(value), style: numStyle(big ? 24 : 20)),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(fontSize: 11, color: Volt.t3),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        if (sub case (final text, final c))
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(text, style: TextStyle(fontSize: 11, color: c)),
          ),
      ],
    ),
  );
}

/// The readiness score on a half ring that fills from violet through teal
/// to lime, the word under it in the colour of the day.
class _Gauge extends StatelessWidget {
  const _Gauge({required this.score, required this.tone, required this.word, required this.label});
  final int? score;
  final Color tone;
  final String word;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label ${score ?? '—'}, $word',
    child: SizedBox(
      width: 96,
      height: 58,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (score ?? 0) / 100),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, f, _) => CustomPaint(
          painter: _GaugePainter(f, Volt.tint.withValues(alpha: 0.08)),
          child: Align(
            alignment: const Alignment(0, 0.9),
            child: Text(score == null ? '—' : '${(f * 100).round()}', style: numStyle(26, height: 1)),
          ),
        ),
      ),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.fraction, this.track);
  final double fraction;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 8.0;
    final r = size.width / 2 - w / 2;
    final c = Offset(size.width / 2, r + w / 2);
    final rect = Rect.fromCircle(center: c, radius: r);
    Paint arc(Color? color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = color ?? const Color(0xFFFFFFFF);
    canvas.drawArc(rect, math.pi, math.pi, false, arc(track));
    if (fraction <= 0) return;
    final fill = arc(null)
      ..shader = const SweepGradient(
        startAngle: math.pi,
        endAngle: 2 * math.pi,
        colors: [Color(0xFF8B7CF6), Color(0xFF2EC4B6), Color(0xFFC6F432)],
      ).createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi * fraction, false, fill);
  }

  @override
  bool shouldRepaint(_GaugePainter o) => o.fraction != fraction || o.track != track;
}

/// One of the numbers behind the score, small: icon, value, and how far it
/// is from the usual when it is.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.color, required this.value, required this.label, this.delta});
  final String icon;
  final Color color;
  final String value;
  final String label;
  final (String, Color)? delta;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: smooth(BoxDecoration(color: Volt.card2, borderRadius: BorderRadius.circular(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VIcon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Volt.t3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: ltr(value), style: numStyle(14)),
                  if (delta case (final d, final c))
                    TextSpan(
                      text: '  ${ltr(d)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.icon, required this.color, this.size = 40});
  final String icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
    child: VIcon(icon, size: size / 2, color: color),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text, this.sub});
  final String icon;
  final Color color;
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Dot(icon: icon, color: color, size: 34),
      const SizedBox(width: 12),
      Expanded(
        child: GapCol(
          gap: 1,
          children: [
            Text(
              text,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
            ),
            if (sub != null) Muted(sub!, size: 11, color: Volt.ok),
          ],
        ),
      ),
    ],
  );
}

/// Asks once for what the watch records. For someone already connected it
/// opens the phone's permission screen again, now with the new reads.
class _Ask extends ConsumerStatefulWidget {
  const _Ask();

  @override
  ConsumerState<_Ask> createState() => _AskState();
}

class _AskState extends ConsumerState<_Ask> {
  var _busy = false;

  Future<void> _allow() async {
    setState(() => _busy = true);
    if (ref.read(healthOnProvider)) {
      await askWatchReads(ref);
    } else if (!await setHealth(ref, true)) {
      // Said no: do not ask again from here; the Health screen still can.
      await ref.read(watchReadsAskedProvider.notifier).done();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = Platform.isIOS ? l.appleHealth : l.healthConnect;
    return VCard(
      child: GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Dot(icon: 'watch', color: Volt.violet),
              const SizedBox(width: 12),
              Expanded(
                child: GapCol(
                  gap: 3,
                  children: [
                    Text(
                      l.recoveryConnectTitle,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
                    ),
                    Muted(l.recoveryConnectBody(store), color: Volt.t2),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(watchReadsAskedProvider.notifier).done(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: VIcon('close', size: 16, color: Volt.t3),
                ),
              ),
            ],
          ),
          VBtn(label: l.allowBtn, small: true, expand: true, onTap: _busy ? null : _allow),
        ],
      ),
    );
  }
}
