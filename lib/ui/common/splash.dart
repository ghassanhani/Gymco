import 'package:flutter/material.dart';

import '../../theme/volt.dart';

/// The launch screen, carried into the app's first frame: the same glowing G
/// at the same size on the same ink, so the hand-over from the phone's own
/// launch screen can't be seen. It then grows a little and fades into the app.
/// Once per launch: redraws (a change of appearance) don't replay it.
class SplashCover extends StatefulWidget {
  const SplashCover({super.key});

  /// Matches the launch images tool/make_splash.py draws (96 pt / dp).
  static const logoSize = 96.0;
  static bool _played = false;

  @override
  State<SplashCover> createState() => _SplashCoverState();
}

class _SplashCoverState extends State<SplashCover> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  bool _gone = SplashCover._played;

  @override
  void initState() {
    super.initState();
    if (_gone) return;
    SplashCover._played = true;
    _c.forward().whenComplete(() => mounted ? setState(() => _gone = true) : null);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // A beat on the logo (the first third), then it grows and fades out.
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.5, 1, curve: Curves.easeOut),
    );
    final grow = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 1, curve: Curves.easeInOutCubic),
    );
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Opacity(
          opacity: 1 - fade.value,
          child: ColoredBox(
            color: VoltPalette.dark.bg,
            child: Center(
              child: Transform.scale(
                scale: still ? 1 : 1 + 0.14 * grow.value,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (r) => Volt.glow.createShader(r),
                  child: Image.asset(
                    'assets/brand/logo-mask.png',
                    width: SplashCover.logoSize,
                    height: SplashCover.logoSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
