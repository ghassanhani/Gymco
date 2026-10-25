import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// How smooth every corner in the app is, as in Figma's corner smoothing:
/// 0 is a plain circular corner, 1 is the smoothest squircle.
const cornerSmoothing = 0.85;

SmoothBorderRadius _smoothRadius(BorderRadius r) {
  SmoothRadius s(Radius x) => SmoothRadius(cornerRadius: x.x, cornerSmoothing: cornerSmoothing);
  return SmoothBorderRadius.only(
    topLeft: s(r.topLeft),
    topRight: s(r.topRight),
    bottomLeft: s(r.bottomLeft),
    bottomRight: s(r.bottomRight),
  );
}

/// A rounded rectangle with smooth corners. It takes the same radii as a
/// [RoundedRectangleBorder], directional ones included, so right-to-left
/// layouts mirror correctly.
class SmoothBorder extends OutlinedBorder {
  const SmoothBorder({this.borderRadius = BorderRadius.zero, super.side});

  final BorderRadiusGeometry borderRadius;

  SmoothRectangleBorder _resolve(TextDirection? d) =>
      SmoothRectangleBorder(side: side, borderRadius: _smoothRadius(borderRadius.resolve(d)));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _resolve(textDirection).getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _resolve(textDirection).getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      _resolve(textDirection).paint(canvas, rect, textDirection: textDirection);

  @override
  SmoothBorder copyWith({BorderSide? side, BorderRadiusGeometry? borderRadius}) =>
      SmoothBorder(side: side ?? this.side, borderRadius: borderRadius ?? this.borderRadius);

  @override
  ShapeBorder scale(double t) => SmoothBorder(side: side.scale(t), borderRadius: borderRadius * t);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SmoothBorder) {
      return SmoothBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SmoothBorder) {
      return SmoothBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: BorderRadiusGeometry.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) => other is SmoothBorder && other.side == side && other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(side, borderRadius);
}

/// [d] with smooth corners: the same colour, gradient, image, shadows and a
/// uniform border, drawn on a [SmoothBorder]. Boxes without a radius, and
/// the rare one with a border on some sides only, stay as they are.
Decoration smooth(BoxDecoration d) {
  final r = d.borderRadius;
  if (r == null || d.shape != BoxShape.rectangle) return d;
  var side = BorderSide.none;
  if (d.border case final b?) {
    if (b is! Border || !b.isUniform) return d;
    side = b.top;
  }
  return ShapeDecoration(
    color: d.color,
    gradient: d.gradient,
    image: d.image,
    shadows: d.boxShadow,
    shape: SmoothBorder(borderRadius: r, side: side),
  );
}

/// Clips [child] to a rectangle with smooth corners, in place of [ClipRRect].
class ClipSmooth extends StatelessWidget {
  const ClipSmooth({super.key, this.borderRadius = BorderRadius.zero, this.clipBehavior = Clip.antiAlias, this.child});
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final Widget? child;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: ShapeBorderClipper(
      shape: SmoothBorder(borderRadius: borderRadius),
      textDirection: Directionality.maybeOf(context),
    ),
    clipBehavior: clipBehavior,
    child: child,
  );
}

/// A text field's outline with smooth corners, in place of
/// [OutlineInputBorder]. The fill follows the same shape.
class SmoothInputBorder extends InputBorder {
  const SmoothInputBorder({super.borderSide = const BorderSide(), this.borderRadius = BorderRadius.zero});

  final BorderRadiusGeometry borderRadius;

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  SmoothBorder get _shape => SmoothBorder(borderRadius: borderRadius);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect.deflate(borderSide.width), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;
    canvas.drawPath(
      _shape.getOuterPath(rect.deflate(borderSide.width / 2), textDirection: textDirection),
      borderSide.toPaint(),
    );
  }

  @override
  SmoothInputBorder copyWith({BorderSide? borderSide, BorderRadiusGeometry? borderRadius}) =>
      SmoothInputBorder(borderSide: borderSide ?? this.borderSide, borderRadius: borderRadius ?? this.borderRadius);

  @override
  ShapeBorder scale(double t) => SmoothInputBorder(borderSide: borderSide.scale(t), borderRadius: borderRadius * t);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SmoothInputBorder) {
      return SmoothInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SmoothInputBorder) {
      return SmoothInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadiusGeometry.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is SmoothInputBorder && other.borderSide == borderSide && other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(borderSide, borderRadius);
}
