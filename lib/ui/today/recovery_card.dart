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

    final (word, tone) = switch (r.readiness) {
      Readiness.ready => (l.readyReady, Volt.ok),
      Readiness.steady => (l.readySteady, Volt.orange),
      Readiness.easy => (l.readyEasy, heartRed),
      Readiness.learning => (l.readyLearning, Volt.t3),
    };
    final advice = switch (r.readiness) {
      Readiness.ready => l.adviceReady,
      Readiness.steady => l.adviceSteady,
      Readiness.easy => l.adviceEasy,
      Readiness.learning => l.adviceLearning,
    };

    String hm(int min) => min < 60 ? l.minutesOnly(min) : l.hoursMinutes(min ~/ 60, min % 60);
    String signed(double d, String Function(double) show) => '${d > 0 ? '+' : '−'}${show(d)}';
    final tiles = [
      if (r.sleepMin case final s?)
        MetricTile(
          icon: 'moon',
          color: Volt.violet,
          label: l.recoverySleep,
          value: hm(s),
          sub: _delta(
            l,
            s.toDouble(),
            r.sleepBase,
            near: 15,
            higherIsBetter: true,
            show: (d) => signed(d, (d) => hm(d.abs().round())),
          ),
        ),
      if (r.restingHr case final h?)
        MetricTile(
          icon: 'pulse',
          color: heartRed,
          label: l.recoveryRestingHr,
          value: '${h.round()}',
          unit: l.bpmUnit,
          sub: _delta(
            l,
            h,
            r.restingBase,
            near: 2,
            higherIsBetter: false,
            show: (d) => signed(d, (d) => '${d.abs().round()}'),
          ),
        ),
      if (r.hrv case final v?)
        MetricTile(
          icon: 'heart',
          color: _hrvTeal,
          label: l.recoveryHrv,
          value: '${v.round()}',
          unit: l.msUnit,
          sub: _delta(
            l,
            v,
            r.hrvBase,
            near: (r.hrvBase ?? 0) * 0.05,
            higherIsBetter: true,
            show: (d) => signed(d, (d) => '${d.abs().round()}'),
          ),
        ),
    ];

    return GapCol(
      gap: 10,
      cross: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(
          title: l.recoveryTitle,
          trailing: VTag(word, background: tone.withValues(alpha: 0.14), color: tone, bold: true),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: tiles[i]),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Muted(advice, color: Volt.t2),
        ),
      ],
    );
  }

  /// How today sits against the normal, worded and coloured; null without
  /// a normal yet.
  static (String, Color)? _delta(
    AppLocalizations l,
    double now,
    double? base, {
    required double near,
    required bool higherIsBetter,
    required String Function(double) show,
  }) {
    if (base == null) return null;
    final d = now - base;
    if (d.abs() <= near) return (l.asUsual, Volt.t3);
    final good = (d > 0) == higherIsBetter;
    return (l.vsUsual(show(d)), good ? Volt.ok : heartRed);
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
  const _SectionHead({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

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
        ?trailing,
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
