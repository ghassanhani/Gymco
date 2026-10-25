import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../domain/awards.dart';

/// Awards that have their own enamel-and-chrome artwork, by award id.
const badgeArt = {
  's7': 'assets/awards/s7.png',
  's14': 'assets/awards/s14.png',
  's30': 'assets/awards/s30.png',
  's66': 'assets/awards/s66.png',
  's90': 'assets/awards/s90.png',
  'back': 'assets/awards/back.png',
  'f1': 'assets/awards/f1.png',
  'f100': 'assets/awards/f100.png',
  'fp': 'assets/awards/fp.png',
  't1': 'assets/awards/t1.png',
  't25': 'assets/awards/t25.png',
  'tpr': 'assets/awards/tpr.png',
  'month': 'assets/awards/month.png',
};

const _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// The front of a badge: the artwork in colour once earned, a dim grey
/// pressing of it while locked. The challenge badge has the month written
/// into its calendar plate, so one picture serves every month.
class BadgeFace extends StatelessWidget {
  const BadgeFace({super.key, required this.award, required this.size, this.month, this.sheen = 0, this.dim});
  final Award award;
  final double size;
  final String? month;

  /// Grey it out; by default, while it is locked.
  final bool? dim;

  /// Where the light catches it, -1 to 1; 0 is no highlight.
  final double sheen;

  @override
  Widget build(BuildContext context) {
    final art = badgeArt[award.id]!;
    Widget face = Image.asset(art, width: size, height: size, filterQuality: FilterQuality.medium);
    if (month != null) {
      face = Stack(
        alignment: Alignment.center,
        children: [
          face,
          _MonthPlate(text: month!, size: size),
        ],
      );
    }
    if (sheen != 0) {
      // A soft band of light, only where the badge is.
      face = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment(-1 + sheen, -1),
          end: Alignment(1 + sheen, 1),
          colors: const [Color(0x00FFFFFF), Color(0x55FFFFFF), Color(0x00FFFFFF)],
          stops: const [0.35, 0.5, 0.65],
        ).createShader(r),
        child: face,
      );
    }
    if (dim ?? !award.earned) {
      face = Opacity(
        opacity: 0.38,
        child: ColorFiltered(colorFilter: _greyscale, child: face),
      );
    }
    return face;
  }
}

/// The month in the calendar badge's plate, drawn like its chrome letters.
class _MonthPlate extends StatelessWidget {
  const _MonthPlate({required this.text, required this.size});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    TextStyle stroke(double w, Color c) => TextStyle(
      fontSize: size * 0.17,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: size * 0.006,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeJoin = StrokeJoin.round
        ..color = c,
    );
    return SizedBox(
      width: size * 0.44,
      height: size * 0.2,
      child: FittedBox(
        child: Stack(
          children: [
            Text(text, style: stroke(size * 0.016, const Color(0xFF7D828A))),
            Text(text, style: stroke(size * 0.007, const Color(0xFFF4F5F7))),
          ],
        ),
      ),
    );
  }
}

/// The back: the badge's own outline in brushed steel, engraved with the
/// award and the day it was earned.
class BadgeBack extends StatelessWidget {
  const BadgeBack({super.key, required this.award, required this.size, required this.name, required this.date});
  final Award award;
  final double size;
  final String name;
  final String date;

  @override
  Widget build(BuildContext context) {
    final art = badgeArt[award.id]!;
    Widget steel(double scale, List<Color> colors) => Transform.scale(
      scale: scale,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) =>
            LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors).createShader(r),
        child: Image.asset(art, width: size, height: size),
      ),
    );
    const engraved = [
      Shadow(offset: Offset(0, 1), color: Color(0xCCFFFFFF)),
      Shadow(offset: Offset(0, -1), color: Color(0x66000000)),
    ];
    TextStyle cut(double fs, {FontWeight weight = FontWeight.w600, double spacing = 0}) => TextStyle(
      fontSize: fs,
      fontWeight: weight,
      color: const Color(0xFF5C6168),
      letterSpacing: spacing,
      height: 1.15,
      shadows: engraved,
    );
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          steel(1, const [Color(0xFFF2F3F5), Color(0xFF9AA0A8), Color(0xFFE3E5E8), Color(0xFF7F858D)]),
          // A raised lip around the edge, like the front's chrome frame.
          steel(0.9, const [Color(0xFFC9CDD2), Color(0xFFE9EBEE), Color(0xFFB7BCC2), Color(0xFFD9DCE0)]),
          SizedBox(
            width: size * 0.62,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GYMCO',
                  style: cut(size * 0.045, weight: FontWeight.w800, spacing: size * 0.012),
                ),
                SizedBox(height: size * 0.04),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: cut(size * 0.085, weight: FontWeight.w700),
                ),
                SizedBox(height: size * 0.035),
                Container(width: size * 0.18, height: 1.2, color: const Color(0x995C6168)),
                SizedBox(height: size * 0.035),
                Text(date, textAlign: TextAlign.center, style: cut(size * 0.055)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A badge you can pick up: drag to turn it, tap to flip it. It has a
/// chrome edge you see side-on, light that moves across it, and settles
/// face up or face down with a spring.
class Badge3D extends StatefulWidget {
  const Badge3D({
    super.key,
    required this.award,
    required this.size,
    required this.name,
    required this.date,
    this.month,
    this.backLabel,
    this.angle,
    this.spinIn = false,
  });
  final Award award;
  final double size;
  final String name;
  final String date;
  final String? month;
  final String? backLabel;

  /// Arrives spinning, a few turns that slow to face front: for an award just earned.
  final bool spinIn;

  /// Holds it at one angle, for previews and tests.
  @visibleForTesting
  final double? angle;

  @override
  State<Badge3D> createState() => _Badge3DState();
}

class _Badge3DState extends State<Badge3D> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController.unbounded(vsync: this);
  static const _spring = SpringDescription(mass: 1, stiffness: 120, damping: 14);

  bool get _canFlip => widget.award.earned;

  @override
  void initState() {
    super.initState();
    if (widget.spinIn) {
      _turn.value = -4 * math.pi;
      _turn.animateTo(0, duration: const Duration(milliseconds: 2600), curve: Curves.easeOutCubic);
    } else {
      // A small turn on arrival says it can be picked up.
      _turn.animateWith(SpringSimulation(_spring, 0.55, 0, 0));
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _settle(double velocity) {
    final step = _canFlip ? math.pi : 2 * math.pi;
    final target = (((_turn.value + velocity * 0.12) / step).round()) * step;
    _turn.animateWith(SpringSimulation(_spring, _turn.value, target, velocity));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onTap: _canFlip
          ? () => _turn.animateWith(
              SpringSimulation(_spring, _turn.value, ((_turn.value / math.pi).round() + 1) * math.pi, 0),
            )
          : null,
      onHorizontalDragUpdate: (d) {
        final v = _turn.value + d.delta.dx / s * math.pi;
        // A locked badge tilts but will not turn over.
        _turn.value = _canFlip ? v : v.clamp(-0.9, 0.9);
      },
      onHorizontalDragEnd: (d) => _settle(d.primaryVelocity! / s * math.pi),
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, _) {
          final a = widget.angle ?? _turn.value;
          final c = math.cos(a);
          final faceUp = c >= 0;
          final art = badgeArt[widget.award.id]!;
          final depth = s * 0.05;
          Matrix4 at(double z) => Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(a)
            ..translateByDouble(0, 0, z, 1);

          // The edge: slices of the outline in chrome, between the faces.
          const slices = 9;
          final edge = <(double, Widget)>[
            for (var i = 1; i < slices; i++)
              (
                depth * (i / slices - 0.5),
                Image.asset(
                  art,
                  width: s,
                  height: s,
                  color: Color.lerp(const Color(0xFF6E737B), const Color(0xFFC3C7CC), (i % 3) / 2)!,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
          ];
          final front = (
            depth / 2,
            BadgeFace(award: widget.award, size: s, month: widget.month, sheen: math.sin(a) * 0.9),
          );
          final back = (
            -depth / 2,
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: BadgeBack(award: widget.award, size: s, name: widget.name, date: widget.date),
            ),
          );
          // Paint far to near: the face toward the viewer goes on top.
          final layers = [back, ...edge, front]..sort((p, q) => (p.$1 * c).compareTo(q.$1 * c));
          return Semantics(
            label: faceUp ? null : widget.backLabel,
            child: SizedBox.square(
              dimension: s,
              child: Stack(
                children: [
                  for (final (z, w) in layers)
                    if (_canFlip || z >= 0) Transform(alignment: Alignment.center, transform: at(z), child: w),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
