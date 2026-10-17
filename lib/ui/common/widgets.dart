import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/volt.dart';

/// The lime glow that rises behind the top of every screen.
class VoltBackground extends StatelessWidget {
  const VoltBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Volt.bg,
        gradient: RadialGradient(
          center: Alignment(0.7, -1.1),
          radius: 1.1,
          colors: [Color(0x33C6F432), Color(0x00C6F432)],
          stops: [0, 0.7],
        ),
      ),
      child: child,
    );
  }
}

/// A title with one word set in the serif italic accent, e.g.
/// "Make it *count*". [template] holds `{accent}` where the word goes.
class AccentTitle extends StatelessWidget {
  const AccentTitle({super.key, required this.template, required this.accent, this.size = 27});
  final String template;
  final String accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: size, height: 1.08);
    final parts = template.split('{accent}');
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: accent,
            style: Localizations.localeOf(context).languageCode == 'ar'
                ? base.copyWith(color: Volt.brand)
                : Volt.accent(size),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}

class GymcoLogo extends StatelessWidget {
  const GymcoLogo({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Gymco',
    image: true,
    child: Image.asset(
      'assets/brand/logo-mask.png',
      width: size,
      height: size,
      color: Volt.brand,
      colorBlendMode: BlendMode.srcIn,
    ),
  );
}

/// The glowing lime pill. [onPressed] null disables it.
class GlowButton extends StatelessWidget {
  const GlowButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: Volt.glow,
          borderRadius: BorderRadius.circular(999),
          boxShadow: enabled
              ? const [BoxShadow(color: Color(0xBFB6F02A), blurRadius: 26, offset: Offset(0, 12), spreadRadius: -12)]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, color: Volt.ink, size: 20), const SizedBox(width: 8)],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Volt.ink, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
    label: Text(label),
    style: TextButton.styleFrom(
      backgroundColor: Volt.card2,
      foregroundColor: Volt.t1,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}

class VoltCard extends StatelessWidget {
  const VoltCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Volt.card,
    borderRadius: BorderRadius.circular(Volt.rCard),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Calorie ring. Over and under both read neutral: past the target the ring
/// is simply full, never red.
class KcalRing extends StatelessWidget {
  const KcalRing({super.key, required this.fraction, required this.child, this.size = 168});
  final double fraction;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingPainter(fraction.clamp(0, 1).toDouble()),
      child: Center(child: child),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.f);
  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = Volt.card2
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (f <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * f,
      false,
      Paint()
        ..shader = const SweepGradient(
          transform: GradientRotation(-math.pi / 2),
          colors: [Color(0xFFE4FF6A), Color(0xFFB6F02A), Color(0xFF5EE4A0)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.f != f;
}

class MacroBar extends StatelessWidget {
  const MacroBar({super.key, required this.label, required this.value, required this.color, required this.fraction});
  final String label;
  final String value;
  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: t.titleMedium?.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1).toDouble(),
            minHeight: 6,
            color: color,
            backgroundColor: Volt.card2,
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Row(
      children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
        ?trailing,
      ],
    ),
  );
}
