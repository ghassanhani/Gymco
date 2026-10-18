import 'package:flutter/material.dart';

import '../../theme/transitions.dart';

export '../../theme/transitions.dart' show voltEase;

/// Fades and lifts [child] in once, when it first appears. [delay] staggers
/// a list so it arrives a card at a time.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.delay = Duration.zero, this.offset = 14, this.play = true});
  final Widget child;
  final Duration delay;

  /// Read once: false shows it in place. The wrapper stays either way, so
  /// the child keeps its state whatever later builds pass.
  final bool play;

  /// How far below its place it starts, in px.
  final double offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 420);

  // The delay is the front of one animation, so there is no timer to cancel.
  late final _c = AnimationController(vsync: this, duration: widget.delay + _run, value: widget.play ? 0 : 1)
    ..forward();
  late final _t = CurvedAnimation(
    parent: _c,
    curve: Interval(widget.delay.inMicroseconds / (widget.delay + _run).inMicroseconds, 1, curve: voltEase),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, (1 - _t.value) * widget.offset), child: child),
      ),
      child: widget.child,
    );
  }
}

/// A number that rolls to its new value instead of jumping, and counts up
/// from zero the first time it shows.
class AnimatedNum extends StatelessWidget {
  const AnimatedNum(this.value, {super.key, required this.format, this.style, this.from = 0});
  final double value;
  final String Function(BuildContext, double) format;
  final TextStyle? style;
  final double from;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: from, end: value),
    duration: const Duration(milliseconds: 700),
    curve: voltEase,
    builder: (context, v, _) => Text(format(context, v), style: style),
  );
}

/// A small pop when [trigger] changes: for ticks, badges and counts.
class Pop extends StatelessWidget {
  const Pop({super.key, required this.trigger, required this.child});
  final Object? trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(trigger),
    tween: Tween(begin: 0.6, end: 1),
    duration: const Duration(milliseconds: 380),
    curve: Curves.elasticOut,
    builder: (_, s, child) => Transform.scale(scale: s, child: child),
    child: child,
  );
}
