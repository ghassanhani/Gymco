import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/energy.dart';
import '../../domain/volume.dart';
import '../../l10n/app_localizations.dart';
import '../../state/progress_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'photos_view.dart';
import '../train/train_kit.dart';
import 'awards_screen.dart' show StreakCard;

enum _View { weight, measure, strength, photos }

/// Progress: weight and its trend, waist, strength, and the week's sets.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _View _view = _View.weight;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VAppBar(
            title: l.progressTitleEm,
            right: IconBtn(
              'plus',
              label: l.addWeighIn,
              background: Volt.brand,
              color: Volt.ink,
              onTap: () => _view == _View.measure ? addWaist(context, ref) : addWeighIn(context, ref),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            // Chips start at the edge, like the prototype's row.
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                for (final (i, (v, label)) in [
                  (_View.weight, l.weightTab),
                  (_View.measure, l.measureTab),
                  (_View.strength, l.strengthTab),
                  (_View.photos, l.photosTab),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  VChip(label: label, on: _view == v, onTap: () => setState(() => _view = v)),
                ],
              ],
            ),
          ),
          Expanded(
            child: Pad(
              children: switch (_view) {
                _View.weight => [
                  const StreakCard(),
                  const _TrendCard(),
                  const _WeightTiles(),
                  const _WeekSets(),
                  VBtn(label: l.openCheckIn, expand: true, onTap: () => context.push('/checkin')),
                ],
                _View.measure => [const _Waist()],
                _View.strength => [const _Strength()],
                _View.photos => [const PhotosView()],
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A number on the keypad: a weigh-in, a waist measurement.
Future<void> showNumberSheet(
  BuildContext context, {
  required String title,
  required String unit,
  required double? initial,
  required String note,
  required ValueChanged<double> onSave,
  double max = 400,
}) {
  final l = AppLocalizations.of(context);
  final decimal = fmtDec(context, 1.5).contains(',') ? ',' : '.';
  var v = initial == null ? '' : fmtDec(context, initial).replaceAll(RegExp('[^0-9,.]'), '');
  var fresh = true;
  return showVSheet<void>(
    context,
    title: title,
    body: (ctx) => [
      StatefulBuilder(
        builder: (ctx, setState) {
          final value = double.tryParse(v.replaceAll(',', '.'));
          return GapCol(
            gap: 12,
            cross: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Volt.lime, width: 2)),
                    ),
                    child: Text(
                      v.isEmpty ? '—' : v,
                      textDirection: TextDirection.ltr,
                      style: numStyle(44, height: 1.05),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Volt.t2),
                  ),
                ],
              ),
              Muted(note),
              Keypad(
                decimal: decimal,
                deleteLabel: l.deleteDigit,
                onKey: (k) => setState(() {
                  // The first key replaces last time's number.
                  if (fresh && k != 'del') v = '';
                  fresh = false;
                  if (k == 'del') {
                    v = v.isEmpty ? v : v.substring(0, v.length - 1);
                  } else if (k == decimal) {
                    if (!v.contains(decimal)) v = v.isEmpty ? '0$decimal' : '$v$decimal';
                  } else if (v.length < 5) {
                    v += k;
                  }
                }),
              ),
              VBtn(
                label: l.save,
                expand: true,
                onTap: value == null || value <= 0 || value > max
                    ? null
                    : () {
                        onSave(value);
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

Future<void> addWeighIn(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final ws = await ref.read(weightSummaryProvider.future);
  if (!context.mounted) return;
  return showNumberSheet(
    context,
    title: l.weighInToday,
    unit: l.kgLbl,
    initial: ws.points.isEmpty ? ref.read(profileProvider)?.weightKg : ws.points.last.$2,
    note: l.weighInNote,
    onSave: (kg) {
      ref.read(progressActionsProvider).weigh(ref.read(clockProvider)(), kg);
      showVToast(context, l.weighInSaved);
    },
  );
}

Future<void> addWaist(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final all = await ref.read(measurementsProvider('waist').future);
  if (!context.mounted) return;
  return showNumberSheet(
    context,
    title: l.waistToday,
    unit: l.cm,
    initial: all.isEmpty ? null : all.last.$2,
    note: l.waistNote,
    max: 250,
    onSave: (cm) {
      ref.read(progressActionsProvider).measure(ref.read(clockProvider)(), 'waist', cm);
      showVToast(context, l.measurementSaved);
    },
  );
}

String _signed(BuildContext context, double v, {int digits = 1}) =>
    '${v > 0 ? '+' : (v < 0 ? '−' : '')}${fmtDec(context, v.abs(), digits: digits)}';

class _TrendCard extends ConsumerWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ws = ref.watch(weightSummaryProvider).value;
    final p = ref.watch(profileProvider);
    final now = ref.watch(clockProvider)();
    if (ws == null || p == null) return const SizedBox.shrink();
    final rate = ws.ratePct;
    final goal = p.ratePctPerWeek;
    // Moving the way the plan asks reads as good; the other way, as a note.
    final rateColor = rate == null
        ? Volt.t3
        : ((goal == 0 ? rate.abs() < 0.25 : rate.sign == goal.sign) ? Volt.ok : Volt.warn);
    final loc = Localizations.localeOf(context).toString();
    final start = ws.points.isEmpty ? now : ws.points.first.$1;
    final ahead = DateTime(now.year, now.month, now.day + 28);
    return VCard(
      child: GapCol(
        gap: 14,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: GapCol(
                  gap: 3,
                  children: [
                    Muted(l.trendWeight),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(ws.current == null ? '—' : fmtDec(context, ws.current!), style: numStyle(30)),
                          const SizedBox(width: 8),
                          Text(l.kgLbl, style: TextStyle(fontSize: 14, color: Volt.t2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Muted(l.rateLbl),
                  Text(
                    rate == null ? '—' : l.pctWk(_signed(context, rate, digits: 2)),
                    textDirection: TextDirection.ltr,
                    style: numStyle(15, color: rateColor),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 146,
            child: ws.points.length < 2
                ? Center(child: Muted(l.trendNeedsTwo, align: TextAlign.center))
                : CustomPaint(
                    size: Size.infinite,
                    painter: _TrendChart(points: ws.points, trend: ws.trend, now: now, goalRatePct: goal),
                  ),
          ),
          if (ws.points.length >= 2)
            Row(
              // Time runs left to right in the chart, in every language.
              textDirection: TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final t in [
                  DateFormat.MMMd(loc).format(start),
                  DateFormat.MMMd(loc).format(
                    DateTime.fromMillisecondsSinceEpoch(
                      (start.millisecondsSinceEpoch + now.millisecondsSinceEpoch) ~/ 2,
                    ),
                  ),
                  l.todayLbl.toLowerCase(),
                  DateFormat.MMMd(loc).format(ahead),
                ])
                  Text(t, style: TextStyle(fontSize: 11, color: Volt.t3)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Weigh-ins as dots, the trend as a line, the plan's next four weeks
/// dashed, with a widening band for the uncertainty.
class _TrendChart extends CustomPainter {
  _TrendChart({required this.points, required this.trend, required this.now, required this.goalRatePct});
  final List<(DateTime, double)> points;
  final List<double> trend;
  final DateTime now;
  final double goalRatePct;

  @override
  void paint(Canvas canvas, Size size) {
    final start = points.first.$1;
    final end = DateTime(now.year, now.month, now.day + 28);
    final todayX = 0.72;
    double xOf(DateTime d) {
      final past = now.difference(start).inHours;
      if (!d.isAfter(now)) return past == 0 ? 0 : d.difference(start).inHours / past * todayX;
      return todayX + d.difference(now).inHours / end.difference(now).inHours * (1 - todayX);
    }

    final last = trend.last;
    final projected = last * (1 + goalRatePct / 100 * 4);
    final band = last * 0.006 * 4;
    final values = [...points.map((p) => p.$2), ...trend, projected - band, projected + band];
    var lo = values.reduce(math.min), hi = values.reduce(math.max);
    if (hi - lo < 1) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.5;
      hi = mid + 0.5;
    }
    Offset at(double x, double v) =>
        Offset(6 + (size.width - 12) * x, 8 + (size.height - 16) * (1 - (v - lo) / (hi - lo)));

    final tx = at(todayX, last).dx;
    canvas.drawPath(
      Path()
        ..moveTo(tx, at(todayX, last).dy)
        ..lineTo(size.width, at(1, projected - band).dy)
        ..lineTo(size.width, at(1, projected + band).dy)
        ..close(),
      Paint()..color = Volt.brandWash,
    );
    final dash = Paint()
      ..color = Volt.line2
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 7) {
      canvas.drawLine(Offset(tx, y), Offset(tx, y + 3), dash);
    }
    final dot = Paint()..color = Volt.t4;
    for (final p in points) {
      canvas.drawCircle(at(xOf(p.$1), p.$2), 2.5, dot);
    }
    final line = Path();
    for (var i = 0; i < trend.length; i++) {
      final o = at(xOf(points[i].$1), trend[i]);
      i == 0 ? line.moveTo(o.dx, o.dy) : line.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = Volt.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final from = at(xOf(points.last.$1), last), to = at(1, projected);
    final proj = Paint()
      ..color = Volt.lime
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final len = (to - from).distance;
    for (var d = 0.0; d < len; d += 10) {
      final a = from + (to - from) * (d / len), b = from + (to - from) * (math.min(d + 5, len) / len);
      canvas.drawLine(a, b, proj);
    }
    canvas.drawCircle(from, 5, Paint()..color = Volt.lime);
  }

  @override
  bool shouldRepaint(_TrendChart old) => old.points != points || old.trend != trend;
}

class _WeightTiles extends ConsumerWidget {
  const _WeightTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ws = ref.watch(weightSummaryProvider).value;
    final waist = ref.watch(measurementsProvider('waist')).value ?? const [];
    final p = ref.watch(profileProvider);
    final now = ref.watch(clockProvider)();
    if (ws == null || p == null) return const SizedBox.shrink();
    final days = now.difference(DateTime(p.startedOn.year, p.startedOn.month, p.startedOn.day)).inDays + 1;
    final since = ws.sinceStart;
    final waistChange = waist.length < 2 ? null : waist.last.$2 - waist.first.$2;
    Widget tile(String k, String v) => Expanded(
      child: VCard(
        tight: true,
        child: GapCol(
          gap: 3,
          children: [
            Muted(k),
            Text(v, textDirection: TextDirection.ltr, style: numStyle(17)),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile(l.sinceStart, since == null ? '—' : '${_signed(context, since)} ${l.kgLbl}'),
        const SizedBox(width: 10),
        tile(l.waistLbl, waistChange == null ? '—' : '${_signed(context, waistChange)} ${l.cm}'),
        const SizedBox(width: 10),
        tile(l.weighInsLbl, '${ws.points.length} / $days'),
      ],
    );
  }
}

/// This week's hard sets for the muscles trained most, against 10–20.
class _WeekSets extends ConsumerWidget {
  const _WeekSets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sets = ref.watch(weekGroupSetsProvider).value ?? const <MuscleGroup, double>{};
    final rows = sets.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = rows.take(4).toList();
    final low = top.where((e) => e.value < volumeLow).map((e) => e.key).firstOrNull;
    return VCard(
      child: GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l.weeklyHardSets,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                ),
              ),
              Muted(l.indirectHalf),
            ],
          ),
          if (top.isEmpty) Muted(l.noSetsThisWeek),
          for (final e in top)
            Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(groupName(l, e.key), style: TextStyle(fontSize: 12, color: Volt.t2)),
                ),
                Expanded(
                  child: VolumeBar(
                    total: e.value.round(),
                    color: e.value < volumeLow ? Volt.orange : Volt.ok,
                    height: 10,
                    scale: 30,
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    fmtDec(context, e.value, digits: e.value % 1 == 0 ? 0 : 1),
                    textAlign: TextAlign.end,
                    style: numStyle(12),
                  ),
                ),
              ],
            ),
          if (top.isNotEmpty) Muted(low == null ? l.allInRange : l.underTen(groupName(l, low))),
        ],
      ),
    );
  }
}

class _Waist extends ConsumerWidget {
  const _Waist();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(measurementsProvider('waist')).value ?? const [];
    final loc = Localizations.localeOf(context).toString();
    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        VCard(
          child: GapCol(
            gap: 10,
            cross: CrossAxisAlignment.stretch,
            children: [
              Muted(l.waistLbl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(all.isEmpty ? '—' : fmtDec(context, all.last.$2), style: numStyle(30)),
                  const SizedBox(width: 8),
                  Text(l.cm, style: TextStyle(fontSize: 14, color: Volt.t2)),
                  const Spacer(),
                  if (all.length >= 2)
                    Text(
                      '${_signed(context, all.last.$2 - all.first.$2)} ${l.cm}',
                      textDirection: TextDirection.ltr,
                      style: numStyle(15, color: Volt.ok),
                    ),
                ],
              ),
              Muted(l.waistWhy),
              VBtn(
                label: l.addMeasurement,
                kind: BtnKind.ghost,
                icon: 'plus',
                expand: true,
                onTap: () => addWaist(context, ref),
              ),
            ],
          ),
        ),
        if (all.isNotEmpty)
          VList(
            children: [
              for (final (d, v) in all.reversed.take(20))
                VItem(
                  children: [
                    ItemText(DateFormat.MMMEd(loc).format(parseDay(d))),
                    Text(
                      '${fmtDec(context, v)} ${l.cm}',
                      style: numStyle(14, weight: FontWeight.w500, color: Volt.t2),
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

class _Strength extends ConsumerWidget {
  const _Strength();

  /// The headline: on a cut, did strength hold; otherwise, did it climb.
  Widget? _insight(BuildContext context, WidgetRef ref, List<LiftTrend> lifts) {
    final l = AppLocalizations.of(context);
    final measured = [for (final t in lifts) ?t.changePct];
    if (measured.length < 2) return null;
    final cut = ref.watch(profileProvider)?.goal == Goal.cut;
    // Within 2.5% is noise from one session to the next.
    final held = measured.where((c) => c >= -2.5).length;
    final up = measured.where((c) => c >= 2.5).length;
    final good = cut ? held : up;
    final title = cut ? l.strengthHeldEm : l.strengthUpEm;
    final body = cut ? l.strengthHeldBody(held, measured.length) : l.strengthUpBody(up, measured.length);
    return VCard(
      color: good * 2 >= measured.length ? Volt.brandWash : Volt.card,
      border: Border.all(color: good * 2 >= measured.length ? Volt.brandEdge : Volt.line),
      child: GapCol(
        gap: 6,
        children: [
          Eyebrow(l.strengthInsightLbl, color: Volt.brandInk),
          EmTitle(title, size: 24),
          Muted(body, color: Volt.t2),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lifts = ref.watch(liftTrendsProvider).value;
    if (lifts == null) return const SizedBox.shrink();
    if (lifts.isEmpty) return VCard(child: Muted(l.strengthEmpty));
    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        ?_insight(context, ref, lifts),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.strengthNote)),
        VList(
          children: [
            for (final t in lifts.take(12))
              VItem(
                onTap: () => context.push('/exercise/${Uri.encodeComponent(t.exercise.id)}'),
                children: [
                  ExAv(t.exercise.badge),
                  ItemText(t.exercise.name, sub: l.e1rmLine(fmtKg(context, (t.now * 2).round() / 2))),
                  if (t.changePct != null)
                    Text(
                      '${_signed(context, t.changePct!)}%',
                      textDirection: TextDirection.ltr,
                      style: numStyle(13, color: t.changePct! >= 0 ? Volt.ok : Volt.warn),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
