import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/body_fat.dart';
import '../../domain/energy.dart';
import '../../l10n/app_localizations.dart';
import '../../state/progress_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'progress_screen.dart' show showNumberSheet;

String measureName(AppLocalizations l, BodyMeasure m) => switch (m) {
  BodyMeasure.waist => l.waistLbl,
  BodyMeasure.hips => l.hipsLbl,
  BodyMeasure.neck => l.neckLbl,
  BodyMeasure.chest => l.chestLbl,
  BodyMeasure.arm => l.armLbl,
  BodyMeasure.thigh => l.thighLbl,
};

String _howTo(AppLocalizations l, BodyMeasure m) => switch (m) {
  BodyMeasure.waist => l.waistNote,
  BodyMeasure.hips => l.hipsNote,
  BodyMeasure.neck => l.neckNote,
  BodyMeasure.chest => l.chestNote,
  BodyMeasure.arm => l.armNote,
  BodyMeasure.thigh => l.thighNote,
};

/// The part picked on the body, which the + button measures too.
final measurePickProvider = NotifierProvider<MeasurePick, BodyMeasure>(MeasurePick.new);

class MeasurePick extends Notifier<BodyMeasure> {
  @override
  BodyMeasure build() => BodyMeasure.waist;
  void pick(BodyMeasure m) => state = m;
}

Future<void> addMeasure(BuildContext context, WidgetRef ref, BodyMeasure m) async {
  final l = AppLocalizations.of(context);
  final all = await ref.read(measurementsProvider(m.name).future);
  if (!context.mounted) return;
  final name = measureName(l, m);
  return showNumberSheet(
    context,
    title: m == BodyMeasure.waist
        ? l.waistToday
        : l.measureToday(Localizations.localeOf(context).languageCode == 'en' ? name.toLowerCase() : name),
    unit: l.cm,
    initial: all.isEmpty ? null : all.last.$2,
    note: _howTo(l, m),
    max: 250,
    onSave: (cm) {
      ref.read(progressActionsProvider).measure(ref.read(clockProvider)(), m.name, cm);
      showVToast(context, l.measurementSaved);
    },
  );
}

String _signed(BuildContext context, double v) => '${v > 0 ? '+' : (v < 0 ? '−' : '')}${fmtDec(context, v.abs())}';

/// The Measure view: a body to tap, the body fat it adds up to, and the
/// history of the part picked.
class MeasureView extends ConsumerWidget {
  const MeasureView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final picked = ref.watch(measurePickProvider);
    final latest = {
      for (final m in BodyMeasure.values) m: ref.watch(measurementsProvider(m.name)).value?.lastOrNull?.$2,
    };
    final all = ref.watch(measurementsProvider(picked.name)).value ?? const [];
    final loc = Localizations.localeOf(context).toString();
    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        VCard(
          child: GapCol(
            gap: 6,
            cross: CrossAxisAlignment.stretch,
            children: [
              BodyMap(
                latest: latest,
                picked: picked,
                onTap: (m) {
                  HapticFeedback.selectionClick();
                  ref.read(measurePickProvider.notifier).pick(m);
                  addMeasure(context, ref, m);
                },
              ),
              Center(child: Muted(l.tapBodyHint, size: 12)),
            ],
          ),
        ),
        _BodyFat(latest: latest),
        VCard(
          child: GapCol(
            gap: 10,
            cross: CrossAxisAlignment.stretch,
            children: [
              Muted(measureName(l, picked)),
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
              Muted(picked == BodyMeasure.waist ? l.waistWhy : _howTo(l, picked)),
              VBtn(
                label: l.addMeasurement,
                kind: BtnKind.ghost,
                icon: 'plus',
                expand: true,
                onTap: () => addMeasure(context, ref, picked),
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

class _BodyFat extends ConsumerWidget {
  const _BodyFat({required this.latest});
  final Map<BodyMeasure, double?> latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(profileProvider);
    if (p == null) return const SizedBox.shrink();
    final pct = navyBodyFatPct(
      sex: p.sex,
      heightCm: p.heightCm,
      waistCm: latest[BodyMeasure.waist],
      neckCm: latest[BodyMeasure.neck],
      hipsCm: latest[BodyMeasure.hips],
    );
    return VCard(
      child: GapCol(
        gap: 8,
        cross: CrossAxisAlignment.stretch,
        children: [
          Muted(l.bodyFatLbl),
          if (pct != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(fmtDec(context, pct), style: numStyle(30)),
                const SizedBox(width: 6),
                Text('%', style: TextStyle(fontSize: 14, color: Volt.t2)),
              ],
            ),
            Muted(l.bodyFatNote, size: 12),
          ] else
            Muted(p.sex == Sex.female ? l.bodyFatNeedsFemale : l.bodyFatNeedsMale),
        ],
      ),
    );
  }
}

/// Where each part sits on the figure, on a 100 × 200 grid, and which side
/// its label goes.
const _spots = <BodyMeasure, (double, double, bool)>{
  BodyMeasure.neck: (50, 30, true),
  BodyMeasure.chest: (50, 50, true),
  BodyMeasure.arm: (21, 62, false),
  BodyMeasure.waist: (50, 80, true),
  BodyMeasure.hips: (50, 98, true),
  BodyMeasure.thigh: (40, 124, false),
};

/// How far across the figure each tape runs, on the same grid.
const _tapes = <BodyMeasure, (double, double)>{
  BodyMeasure.neck: (45, 55),
  BodyMeasure.chest: (30, 70),
  BodyMeasure.arm: (16, 27),
  BodyMeasure.waist: (36, 64),
  BodyMeasure.hips: (33, 67),
  BodyMeasure.thigh: (33, 47),
};

/// A front view of a body with a tape at each part: tap a part, or its
/// label, to measure it.
class BodyMap extends StatelessWidget {
  const BodyMap({super.key, required this.latest, required this.picked, required this.onTap});

  final Map<BodyMeasure, double?> latest;
  final BodyMeasure picked;
  final ValueChanged<BodyMeasure> onTap;

  static const _height = 340.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        const scale = _height / 200;
        const figW = 100 * scale;
        final left = (box.maxWidth - figW) / 2;
        Offset at(double x, double y) => Offset(left + x * scale, y * scale);
        return SizedBox(
          height: 182 * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BodyPainter(
                    left: left,
                    scale: scale,
                    picked: picked,
                    figure: Volt.card2,
                    edge: Volt.line2,
                    tape: Volt.t4,
                    accent: Volt.lime,
                    width: box.maxWidth,
                  ),
                ),
              ),
              for (final MapEntry(key: m, value: (x, y, right)) in _spots.entries) ...[
                // The spot on the body itself.
                Positioned(
                  left: at(x, y).dx - 20,
                  top: at(x, y).dy - 20,
                  width: 40,
                  height: 40,
                  child: Semantics(
                    button: true,
                    label: measureName(l, m),
                    child: GestureDetector(
                      key: Key('body-${m.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(m),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: m == picked ? 14 : 10,
                          height: m == picked ? 14 : 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: m == picked ? Volt.lime : Volt.card,
                            border: Border.all(color: m == picked ? Volt.lime : Volt.t3, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Its label at the side, with the latest number.
                Positioned(
                  left: right ? left + figW + 6 : 0,
                  right: right ? 0 : box.maxWidth - left + 6,
                  top: at(x, y).dy - 15,
                  height: 30,
                  child: Align(
                    alignment: right ? Alignment.centerLeft : Alignment.centerRight,
                    child: _Label(
                      name: measureName(l, m),
                      value: latest[m] == null ? '—' : fmtDec(context, latest[m]!),
                      on: m == picked,
                      onTap: () => onTap(m),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.name, required this.value, required this.on, required this.onTap});

  final String name, value;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: on ? Volt.brandWash : Volt.card,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: on ? Volt.lime : Volt.line2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: on ? Volt.t1 : Volt.t2),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                textDirection: TextDirection.ltr,
                style: numStyle(12, color: Volt.t1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.left,
    required this.scale,
    required this.picked,
    required this.figure,
    required this.edge,
    required this.tape,
    required this.accent,
    required this.width,
  });

  final double left, scale, width;
  final BodyMeasure picked;
  final Color figure, edge, tape, accent;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(left + x * scale, y * scale);
    final fill = Paint()..color = figure;
    final outline = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Arms and legs as thick rounded strokes, drawn under the torso.
    void limb(List<Offset> pts, double w) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        path,
        stroke
          ..color = edge
          ..strokeWidth = w * scale + 2.4,
      );
      canvas.drawPath(
        path,
        stroke
          ..color = figure
          ..strokeWidth = w * scale,
      );
    }

    limb([p(27, 41), p(21, 70), p(18, 101)], 9);
    limb([p(73, 41), p(79, 70), p(82, 101)], 9);
    limb([p(41, 100), p(40, 142), p(41, 174)], 13);
    limb([p(59, 100), p(60, 142), p(59, 174)], 13);

    final torso = Path()
      ..moveTo(p(30, 37).dx, p(30, 37).dy)
      ..quadraticBezierTo(p(50, 33).dx, p(50, 33).dy, p(70, 37).dx, p(70, 37).dy)
      ..quadraticBezierTo(p(74, 40).dx, p(74, 40).dy, p(72, 46).dx, p(72, 46).dy)
      ..quadraticBezierTo(p(66, 64).dx, p(66, 64).dy, p(64, 82).dx, p(64, 82).dy)
      ..quadraticBezierTo(p(68, 92).dx, p(68, 92).dy, p(67, 104).dx, p(67, 104).dy)
      ..lineTo(p(33, 104).dx, p(33, 104).dy)
      ..quadraticBezierTo(p(32, 92).dx, p(32, 92).dy, p(36, 82).dx, p(36, 82).dy)
      ..quadraticBezierTo(p(34, 64).dx, p(34, 64).dy, p(28, 46).dx, p(28, 46).dy)
      ..quadraticBezierTo(p(26, 40).dx, p(26, 40).dy, p(30, 37).dx, p(30, 37).dy)
      ..close();
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, outline);

    final neck = RRect.fromRectAndRadius(Rect.fromPoints(p(45, 25), p(55, 36)), Radius.circular(2 * scale));
    canvas.drawRRect(neck, fill);
    canvas.drawRRect(neck, outline);
    canvas.drawCircle(p(50, 15), 10.5 * scale, fill);
    canvas.drawCircle(p(50, 15), 10.5 * scale, outline);

    // A tape at each part, and a leader to its label.
    for (final MapEntry(key: m, value: (x1, x2)) in _tapes.entries) {
      final (_, y, right) = _spots[m]!;
      final on = m == picked;
      final line = Paint()
        ..color = on ? accent : tape.withValues(alpha: 0.7)
        ..strokeWidth = on ? 2.4 : 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p(x1, y), p(x2, y), line);
      final from = right ? p(x2, y) : p(x1, y);
      final to = right ? Offset(left + 100 * scale + 6, y * scale) : Offset(left - 6, y * scale);
      final leader = Paint()
        ..color = on ? accent : tape.withValues(alpha: 0.45)
        ..strokeWidth = 1;
      canvas.drawLine(from, to, leader);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.picked != picked || old.left != left || old.figure != figure || old.accent != accent;
}
