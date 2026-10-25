import 'package:flutter/material.dart';

import '../../theme/volt.dart';
import 'kit.dart';

/// The AI's own colours, the same in both looks: violet into teal into lime.
const aiGradient = [Color(0xFF8B7CF6), Color(0xFF2EC4B6), Color(0xFFC6F432)];

/// Iron's colours: hot pink-red into coral into orange, with white on top.
const ironGradient = [Color(0xFFFF3D71), Color(0xFFFF5E62), Color(0xFFFF8A4C)];

/// The button for anything the AI does: a pill in the AI gradient with
/// sparkles and a light sweeping across it, so AI actions read as one family
/// and apart from the app's own buttons. [busy] shows a spinner in place of
/// the sparkles and keeps it from being tapped twice.
class AiBtn extends StatefulWidget {
  const AiBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.expand = true,
    this.small = false,
    this.compact = false,
    this.colors = aiGradient,
    this.foreground = const Color(0xFF0B0F14),
  });
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final bool expand;
  final bool small;

  /// Inline in a row, beside other small buttons.
  final bool compact;

  /// Iron passes its own: [ironGradient] with white.
  final List<Color> colors;
  final Color foreground;

  @override
  State<AiBtn> createState() => _AiBtnState();
}

class _AiBtnState extends State<AiBtn> with SingleTickerProviderStateMixin {
  // Twice when it appears, then it rests: a light that never stops gets tiring.
  late final _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(count: 2);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.busy;
    final fg = widget.foreground;
    final h = widget.compact ? 34.0 : (widget.small ? 44.0 : 54.0);
    return Pressable(
      onTap: enabled ? widget.onTap : null,
      label: widget.label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: widget.onTap == null ? 0.45 : 1,
        child: Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : (widget.small ? 18 : 22)),
          decoration: smooth(
            BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(colors: widget.colors),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: widget.colors.first.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                        spreadRadius: -10,
                      ),
                    ]
                  : null,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The light that sweeps across while it waits to be tapped.
              Positioned.fill(
                child: ClipSmooth(
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (_, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-2.2 + _sweep.value * 4.4, 0),
                          end: Alignment(-1.2 + _sweep.value * 4.4, 0),
                          colors: const [Color(0x00FFFFFF), Color(0x55FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: widget.expand && !widget.compact ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.busy)
                    SizedBox.square(
                      dimension: widget.compact ? 12 : 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  else
                    VIcon('sparkles', size: widget.compact ? 14 : 18, color: fg, strokeWidth: 1.8),
                  SizedBox(width: widget.compact ? 5 : 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.compact ? 13 : (widget.small ? 14 : 15),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.075,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round sparkle mark in the AI gradient, for list rows and cards that
/// lead to an AI feature.
class AiMark extends StatelessWidget {
  const AiMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: aiGradient),
    ),
    child: VIcon('sparkles', size: size * 0.5, color: const Color(0xFF0B0F14), strokeWidth: 1.8),
  );
}

/// Text in the AI gradient, for a feature's name.
class AiText extends StatelessWidget {
  const AiText(this.text, {super.key, this.style, this.colors = aiGradient});
  final String text;
  final TextStyle? style;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) => LinearGradient(colors: colors).createShader(r),
    child: Text(text, style: (style ?? const TextStyle()).copyWith(color: Volt.t1)),
  );
}
