import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/training.dart';
import '../../domain/recovery.dart';
import '../../domain/volume.dart';
import '../../domain/workout.dart';
import '../../l10n/app_localizations.dart';
import '../../state/health_providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'train_kit.dart';

/// What a finished workout did: time, volume, hard sets, the best set of
/// each exercise, and where the week now stands.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.done});
  final FinishedWorkout done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = done.session;
    final lib = ref.watch(exerciseLibraryProvider).value;
    final time = fmtClock(done.endedAt.difference(s.startedAt));
    final date = DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString()).format(s.startedAt);
    final volume = '${fmtInt(context, s.volume)} ${l.kgLbl}';
    final hard = fmtDec(context, s.hardSetsDone, digits: s.hardSetsDone % 1 == 0 ? 0 : 1);

    final best = [
      for (final e in s.exercises)
        if (e.sets.where((x) => x.done && x.type != SetType.warmup && (x.reps ?? 0) > 0).fold<({double kg, int reps})?>(
              null,
              (b, x) {
                final kg = x.weightKg ?? 0, r = x.reps!;
                return b == null || kg * r > b.kg * b.reps ? (kg: kg, reps: r) : b;
              },
            )
            case final b?)
          (e.exerciseId, lib?[e.exerciseId]?.name ?? e.name, b),
    ];

    // Where the week stands for the muscle this session hit hardest.
    final week = ref.watch(setsThisWeekProvider).value ?? const <LoggedExerciseSet>[];
    String? insight;
    if (lib != null && s.exercises.isNotEmpty) {
      final g = groupOf(lib[s.exercises.first.exerciseId]?.primary.firstOrNull ?? '');
      if (g != null) {
        final n = week
            .where((x) => groupOf(lib[x.exerciseId]?.primary.firstOrNull ?? '') == g)
            .fold<double>(0, (sum, x) => sum + x.type.hardSetWeight)
            .round();
        final name = groupName(l, g);
        insight = n < volumeLow
            ? l.insightUnder(name, l.hardSetsN(n))
            : (n > volumeHigh ? l.insightOver(name, l.hardSetsN(n)) : l.insightIn(name, l.hardSetsN(n)));
      }
    }

    void saveAsRoutine() {
      final items = [
        for (final e in s.exercises)
          () {
            final working = e.sets.where((x) => x.done && x.type != SetType.warmup && (x.reps ?? 0) > 0).toList();
            var lo = working.isEmpty ? (e.repLow ?? 8) : working.map((x) => x.reps!).reduce(math.min);
            var hi = working.isEmpty ? (e.repHigh ?? 12) : working.map((x) => x.reps!).reduce(math.max);
            if (hi - lo < 2) {
              lo = math.max(1, lo - 1);
              hi = hi + 1;
            }
            return RoutineItem(
              exerciseId: e.exerciseId,
              sets: math.max(1, working.length),
              repLow: lo,
              repHigh: hi,
              restSeconds: e.restSeconds == 0 ? 150 : e.restSeconds,
            );
          }(),
      ];
      context.push(
        '/routine/new',
        extra: Routine(id: null, name: s.name, items: items, folder: RoutineFolder.mine),
      );
    }

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 16, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: GapCol(
                  gap: 2,
                  children: [
                    Text(
                      l.doneTitle(s.name),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Volt.t1),
                    ),
                    Muted('$date · $time'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Pad(
                bottom: 24,
                children: [
                  VCard(
                    color: Volt.brandWash,
                    border: Border.all(color: Volt.brandEdge, width: 1.5),
                    child: GapCol(
                      gap: 14,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            for (final (k, v) in [(l.durationLbl, time), (l.volumeLbl, volume), (l.hardSetsLbl, hard)])
                              Expanded(
                                child: GapCol(
                                  gap: 3,
                                  children: [
                                    Eyebrow(k),
                                    Text(v, style: numStyle(19)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Muted(l.volumeExplain, color: Volt.t2),
                      ],
                    ),
                  ),
                  _Heart(start: s.startedAt, end: done.endedAt),
                  if (best.isNotEmpty) ...[
                    Eyebrow(l.bestSetEach, padding: const EdgeInsetsDirectional.only(start: 4)),
                    VList(
                      children: [
                        for (final (id, name, b) in best)
                          VItem(
                            children: [
                              ItemText(name, sub: ltr('${fmtKg(context, b.kg)} ${l.kgLbl} × ${b.reps}')),
                              if (done.bests.containsKey(id))
                                VTag(l.prLbl, background: Volt.okWash, color: Volt.ok, bold: true),
                            ],
                          ),
                      ],
                    ),
                  ],
                  if (insight != null) VCard(tight: true, child: Muted(insight)),
                  Row(
                    children: [
                      Expanded(
                        child: VBtn(
                          label: l.saveAsRoutine,
                          kind: BtnKind.ghost,
                          small: true,
                          expand: true,
                          onTap: saveAsRoutine,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: VBtn(
                          label: l.share,
                          kind: BtnKind.ghost,
                          small: true,
                          expand: true,
                          onTap: () => SharePlus.instance.share(
                            ShareParams(
                              text: [
                                l.shareText(s.name, time, volume, hard),
                                for (final (_, name, b) in best) '$name: ${fmtKg(context, b.kg)} × ${b.reps}',
                              ].join('\n'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
              child: VBtn(
                label: l.doneBtn,
                expand: true,
                onTap: () {
                  final solo = s.routineId == null && s.exercises.length == 1;
                  if (solo) showVToast(context, l.soloLogged(lib?[s.exercises.first.exerciseId]?.shortName ?? s.name));
                  context.canPop() ? context.pop() : context.go('/train');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The watch's heart rate while the session ran: average, peak, and how it
/// moved. Only there when a watch sent enough readings.
class _Heart extends ConsumerWidget {
  const _Heart({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(workoutHeartProvider((start, end))).value;
    if (h == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return VCard(
      child: GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Volt.warn.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: VIcon('pulse', size: 18, color: Volt.warn),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GapCol(
                  gap: 1,
                  children: [
                    Text(
                      l.heartRateTitle,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                    ),
                    Muted(l.heartFromWatch, size: 11),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              for (final (k, v) in [(l.avgLbl, h.avg), (l.peakLbl, h.peak)])
                Expanded(
                  child: GapCol(
                    gap: 3,
                    children: [
                      Eyebrow(k),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$v', style: numStyle(19)),
                            TextSpan(
                              text: ' ${l.bpmUnit}',
                              style: TextStyle(fontSize: 11, color: Volt.t3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 56, child: CustomPaint(painter: _HeartBars(h, Volt.warn, Volt.soft))),
        ],
      ),
    );
  }
}

class _HeartBars extends CustomPainter {
  _HeartBars(this.h, this.color, this.empty);
  final HeartSummary h;
  final Color color;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final known = h.bars.whereType<double>();
    final lo = known.reduce(math.min) - 8, hi = known.reduce(math.max);
    final n = h.bars.length, gap = 3.0;
    final w = (size.width - gap * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      final v = h.bars[i];
      final f = v == null ? 0.08 : ((v - lo) / math.max(1, hi - lo)).clamp(0.12, 1.0);
      final top = size.height * (1 - f);
      // Hotter toward the peak.
      final paint = Paint()..color = v == null ? empty : color.withValues(alpha: 0.35 + 0.65 * f);
      canvas.drawRRect(
        RRect.fromLTRBR(i * (w + gap), top, i * (w + gap) + w, size.height, const Radius.circular(3)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeartBars old) => old.h != h || old.color != color;
}
