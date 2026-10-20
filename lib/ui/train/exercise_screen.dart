import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/workout.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'exercise_photo.dart';
import 'train_kit.dart';

/// One exercise: its estimated 1RM over time, its bests, how to do it, and
/// every workout it was in.
class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final e = ref.watch(exerciseLibraryProvider).value?[exerciseId];
    final history = ref.watch(exerciseHistoryProvider(exerciseId)).value ?? const [];
    final now = ref.watch(clockProvider)();
    final loc = Localizations.localeOf(context).toString();
    if (e == null) return const Scaffold(body: VScreen(child: SizedBox.shrink()));

    // Oldest first, each workout's best estimated 1RM.
    final points = <(DateTime, double)>[
      for (final (at, sets) in history.reversed)
        if (sets
                .where((s) => s.type != SetType.warmup)
                .map((s) => estimatedOneRepMax(s.weightKg, s.reps))
                .whereType<double>()
                .fold<double?>(null, (b, v) => b == null || v > b ? v : b)
            case final rm?)
          (at, rm),
    ];
    final recent = points.where((p) => now.difference(p.$1).inDays <= 183).toList();
    final current = points.isEmpty ? null : points.last.$2;
    final eightAgo = points.lastWhere(
      (p) => now.difference(p.$1).inDays >= 56,
      orElse: () => points.isEmpty ? (now, 0) : points.first,
    );
    final delta = current == null || points.length < 2 ? null : current - eightAgo.$2;
    double? bestAt(int reps) => history
        .expand((h) => h.$2)
        .where((s) => s.type != SetType.warmup && s.reps >= reps)
        .fold<double?>(null, (b, s) => b == null || s.weightKg > b ? s.weightKg : b);
    final monthAgo = now.subtract(const Duration(days: 28));
    final setsWk =
        history
            .where((h) => h.$1.isAfter(monthAgo))
            .expand((h) => h.$2)
            .fold<double>(0, (n, s) => n + s.type.hardSetWeight) /
        4;
    final insight = current == null
        ? l.exNoHistory
        : (delta == null || delta.abs() < 0.5 ? l.exFlat : (delta > 0 ? l.exClimbing : l.exDropping));

    // A workout is a PR when its best beats every one before it.
    final prDays = <DateTime>{};
    double? top;
    for (final (at, rm) in points) {
      if (top != null && rm > top + 0.01) prDays.add(at);
      if (top == null || rm > top) top = rm;
    }

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: e.name, sub: muscleLine(l, e), titleSize: 17),
            Expanded(
              child: Pad(
                bottom: 24,
                children: [
                  VCard(
                    child: GapCol(
                      gap: 14,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GapCol(
                                gap: 3,
                                children: [
                                  Muted(l.est1rm),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        current == null ? '—' : fmtKg(context, _round(current)),
                                        style: numStyle(28),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(l.kgLbl, style: TextStyle(fontSize: 13, color: Volt.t2)),
                                      if (delta != null && delta.abs() >= 0.5) ...[
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            l.trendKg(
                                              '${delta > 0 ? '+' : '−'}${fmtKg(context, _round(delta.abs()))}',
                                              8,
                                            ),
                                            style: numStyle(
                                              12,
                                              weight: FontWeight.w500,
                                              color: delta > 0 ? Volt.ok : Volt.warn,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            VChip(label: l.months6, flat: true),
                          ],
                        ),
                        SizedBox(
                          height: 132,
                          child: recent.length < 2
                              ? Center(child: Muted(l.chartNeedsTwo, align: TextAlign.center))
                              : CustomPaint(painter: _RmChart(recent, now), size: Size.infinite),
                        ),
                        if (recent.length >= 2)
                          Row(
                            textDirection: TextDirection.ltr,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var m = 5; m >= 0; m -= 2)
                                Text(
                                  DateFormat.MMM(loc).format(DateTime(now.year, now.month - m)),
                                  style: TextStyle(fontSize: 11, color: m == 0 ? Volt.brandInk : Volt.t3),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (final (i, (k, v)) in [(l.best5, bestAt(5)), (l.best8, bestAt(8))].indexed) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: VCard(
                            tight: true,
                            child: GapCol(
                              gap: 3,
                              children: [
                                Muted(k),
                                Text(v == null ? '—' : '${fmtKg(context, v)} ${l.kgLbl}', style: numStyle(17)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      Expanded(
                        child: VCard(
                          tight: true,
                          child: GapCol(
                            gap: 3,
                            children: [
                              Muted(l.setsWk),
                              Text(fmtDec(context, setsWk, digits: setsWk % 1 == 0 ? 0 : 1), style: numStyle(17)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  VCard(
                    tight: true,
                    color: Volt.brandWash,
                    border: Border.all(color: Volt.brandEdge),
                    child: Muted(insight, color: Volt.t2),
                  ),
                  if (e.images.isNotEmpty && ref.watch(showExercisePhotosProvider))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: PageView(
                          children: [
                            for (var i = 0; i < e.images.length; i++)
                              GestureDetector(
                                onTap: () => showExercisePhotos(context, e, initial: i),
                                child: CachedNetworkImage(
                                  imageUrl: e.imageUrl(i),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    color: Volt.card,
                                    alignment: Alignment.center,
                                    child: Muted(l.photoUnavailable),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (e.instructions.isNotEmpty)
                    GapCol(
                      gap: 8,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(child: Eyebrow(l.instructions)),
                              if (e.equipment != null || e.level != null)
                                VTag([e.equipment, e.level].nonNulls.join(' · ')),
                            ],
                          ),
                        ),
                        for (final (i, step) in e.instructions.indexed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: Volt.card2, shape: BoxShape.circle),
                                  child: Text('${i + 1}', style: numStyle(11, color: Volt.t2)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(step, style: TextStyle(fontSize: 14, height: 1.5, color: Volt.t1)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  Eyebrow(l.historyLbl, padding: const EdgeInsetsDirectional.only(start: 4)),
                  if (history.isEmpty)
                    VCard(tight: true, child: Muted(l.noHistory))
                  else
                    VList(
                      children: [
                        for (final (at, sets) in history.take(12))
                          VItem(
                            children: [
                              ItemText(
                                DateUtils.isSameDay(at, now) ? l.todayLbl : DateFormat.MMMEd(loc).format(at),
                                sub: sets
                                    .where((s) => s.type != SetType.warmup)
                                    .map((s) => ltr('${fmtKg(context, s.weightKg)} × ${s.reps}'))
                                    .join(', '),
                              ),
                              Text(
                                prDays.contains(at)
                                    ? l.prLbl
                                    : '${fmtInt(context, totalVolume(sets.map((s) => LoggedSet(weightKg: s.weightKg, reps: s.reps, type: s.type))))} ${l.kgLbl}',
                                style: prDays.contains(at)
                                    ? numStyle(12, color: Volt.ok)
                                    : numStyle(12, weight: FontWeight.w400, color: Volt.t3),
                              ),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
              child: VBtn(label: l.back, expand: true, onTap: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }

  static double _round(double v) => (v * 2).round() / 2;
}

/// The 1RM line over the last six months, the latest point filled.
class _RmChart extends CustomPainter {
  _RmChart(this.points, this.now);
  final List<(DateTime, double)> points;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Volt.line;
    for (final y in [24.0, 62.0, 100.0]) {
      canvas.drawLine(Offset(0, y / 132 * size.height), Offset(size.width, y / 132 * size.height), grid);
    }
    final start = now.subtract(const Duration(days: 183));
    final lo = points.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
    final hi = points.map((p) => p.$2).reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).abs() < 1 ? 1.0 : hi - lo;
    Offset at((DateTime, double) p) {
      final x = 8 + (size.width - 16) * (p.$1.difference(start).inHours / (183 * 24)).clamp(0.0, 1.0);
      final y = size.height - 24 - (size.height - 48) * (p.$2 - lo) / span;
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(at(p).dx, at(p).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Volt.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(at(points.last), 5, Paint()..color = Volt.lime);
  }

  @override
  bool shouldRepaint(_RmChart old) => old.points != points;
}
