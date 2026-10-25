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

/// Last night's sleep, resting heart rate and HRV against the person's own
/// normal, with one line on how hard to go today. Until the watch reads are
/// allowed it asks for them once instead.
class RecoveryCard extends ConsumerWidget {
  const RecoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(watchReadsAskedProvider)) return const _Ask();
    final r = ref.watch(recoveryProvider).value;
    if (r == null || r.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    final (word, tone) = switch (r.readiness) {
      Readiness.ready => (l.readyReady, Volt.ok),
      Readiness.steady => (l.readySteady, Volt.orange),
      Readiness.easy => (l.readyEasy, Volt.warn),
      Readiness.learning => (l.readyLearning, Volt.t3),
    };
    final advice = switch (r.readiness) {
      Readiness.ready => l.adviceReady,
      Readiness.steady => l.adviceSteady,
      Readiness.easy => l.adviceEasy,
      Readiness.learning => l.adviceLearning,
    };

    String hm(int min) => min < 60 ? l.minutesOnly(min) : l.hoursMinutes(min ~/ 60, min % 60);
    final stats = [
      if (r.sleepMin case final s?)
        _Stat(
          l.recoverySleep,
          hm(s),
          null,
          _delta(l, s.toDouble(), r.sleepBase, near: 15, higherIsBetter: true, show: (d) => hm(d.abs().round())),
        ),
      if (r.restingHr case final h?)
        _Stat(
          l.recoveryRestingHr,
          '${h.round()}',
          l.bpmUnit,
          _delta(l, h, r.restingBase, near: 2, higherIsBetter: false, show: (d) => '${d.abs().round()}'),
        ),
      if (r.hrv case final v?)
        _Stat(
          l.recoveryHrv,
          '${v.round()}',
          l.msUnit,
          _delta(
            l,
            v,
            r.hrvBase,
            near: (r.hrvBase ?? 0) * 0.05,
            higherIsBetter: true,
            show: (d) => '${d.abs().round()}',
          ),
        ),
    ];

    return VCard(
      child: GapCol(
        gap: 14,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Dot(icon: 'heart', color: Volt.violet),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.recoveryTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
                ),
              ),
              VTag(word, background: tone.withValues(alpha: 0.14), color: tone, bold: true),
            ],
          ),
          if (stats.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final s in stats) Expanded(child: s)],
            ),
          if (r.hasBody) Muted(advice, color: Volt.t2),
          if (r.activeKcal != null || r.workouts.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Volt.line)),
              ),
              child: GapCol(
                gap: 10,
                cross: CrossAxisAlignment.stretch,
                children: [
                  if (r.activeKcal case final k?)
                    _Line(icon: 'bolt', color: Volt.orange, text: l.activeKcalToday(fmtInt(context, k))),
                  for (final w in r.workouts)
                    _Line(
                      icon: 'watch',
                      color: Volt.ok,
                      text: l.watchWorkoutLine(workoutKindName(l, w.kind), w.length.inMinutes, w.source),
                      sub: l.watchCountsStreak,
                    ),
                ],
              ),
            ),
        ],
      ),
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
    return (l.vsUsual('${d > 0 ? '+' : '−'}${show(d)}'), good ? Volt.ok : Volt.warn);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.unit, this.delta);
  final String label;
  final String value;
  final String? unit;
  final (String, Color)? delta;

  @override
  Widget build(BuildContext context) => GapCol(
    gap: 3,
    children: [
      Eyebrow(label),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: ltr(value), style: numStyle(19)),
            if (unit != null)
              TextSpan(
                text: ' $unit',
                style: TextStyle(fontSize: 11, color: Volt.t3),
              ),
          ],
        ),
      ),
      if (delta case (final text, final color)) Muted(text, size: 11, color: color),
    ],
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
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
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
      _Dot(icon: icon, color: color, size: 30),
      const SizedBox(width: 10),
      Expanded(
        child: GapCol(
          gap: 1,
          children: [
            Text(
              text,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Volt.t1),
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
