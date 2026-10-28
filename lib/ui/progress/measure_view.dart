import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/body_fat.dart';
import '../../domain/energy.dart';
import '../../l10n/app_localizations.dart';
import '../../state/progress_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'body_svg.dart';
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

/// Where each part sits on the body artwork (998 × 3142), and which side
/// its label goes.
const _spots = <BodyMeasure, (double, double, bool)>{
  BodyMeasure.neck: (490, 420, true),
  BodyMeasure.chest: (495, 790, true),
  BodyMeasure.arm: (132, 950, false),
  BodyMeasure.waist: (495, 1180, true),
  BodyMeasure.hips: (500, 1560, true),
  BodyMeasure.thigh: (350, 1800, false),
};

/// How far across the body each tape runs, on the same grid.
const _tapes = <BodyMeasure, (double, double)>{
  BodyMeasure.neck: (385, 595),
  BodyMeasure.chest: (200, 790),
  BodyMeasure.arm: (55, 215),
  BodyMeasure.waist: (255, 735),
  BodyMeasure.hips: (210, 790),
  BodyMeasure.thigh: (215, 485),
};

/// The artwork's greys, as the dark theme draws them.
class _DarkBody extends ColorMapper {
  const _DarkBody();

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) => switch (color.toARGB32()) {
    0xFFF9F9F9 => const Color(0xFF3A3E45),
    0xFFC5C5C5 || 0xFFC8C4C5 => const Color(0xFF2A2D33),
    _ => const Color(0xFF4C5058),
  };
}

/// A front view of a body with a tape at each part: tap a part, or its
/// label, to measure it.
class BodyMap extends StatelessWidget {
  const BodyMap({super.key, required this.latest, required this.picked, required this.onTap});

  final Map<BodyMeasure, double?> latest;
  final BodyMeasure picked;
  final ValueChanged<BodyMeasure> onTap;

  static const _height = 430.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        const scale = _height / 3142;
        const figW = 998 * scale;
        final left = (box.maxWidth - figW) / 2;
        Offset at(double x, double y) => Offset(left + x * scale, y * scale);
        return SizedBox(
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: left,
                top: 0,
                width: figW,
                height: _height,
                child: SvgPicture.string(
                  bodySvg,
                  colorMapper: Volt.isLight ? null : const _DarkBody(),
                  excludeFromSemantics: true,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _TapePainter(
                    left: left,
                    figW: figW,
                    scale: scale,
                    picked: picked,
                    tape: Volt.isLight ? const Color(0xFF888888) : Volt.t3,
                    accent: Volt.lime,
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

class _TapePainter extends CustomPainter {
  _TapePainter({
    required this.left,
    required this.figW,
    required this.scale,
    required this.picked,
    required this.tape,
    required this.accent,
  });

  final double left, figW, scale;
  final BodyMeasure picked;
  final Color tape, accent;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(left + x * scale, y * scale);
    // A tape around each part, and a leader out to its label.
    for (final MapEntry(key: m, value: (x1, x2)) in _tapes.entries) {
      final (_, y, right) = _spots[m]!;
      final on = m == picked;
      canvas.drawLine(
        p(x1, y),
        p(x2, y),
        Paint()
          ..color = on ? accent : tape.withValues(alpha: 0.8)
          ..strokeWidth = on ? 3 : 1.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        right ? p(x2, y) : p(x1, y),
        right ? Offset(left + figW + 6, y * scale) : Offset(left - 6, y * scale),
        Paint()
          ..color = on ? accent : tape.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_TapePainter old) =>
      old.picked != picked || old.left != left || old.tape != tape || old.accent != accent;
}
