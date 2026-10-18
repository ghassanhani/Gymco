import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// The app's one easing: quick out of the gate, soft landing.
const voltEase = Cubic(0.22, 1, 0.36, 1);

/// Pushed screens: on iPhone the native slide (it keeps swipe-back) with
/// the new screen fading in over it; elsewhere a short rise and fade.
class VoltPageTransitions extends PageTransitionsBuilder {
  const VoltPageTransitions();

  static const _cupertino = CupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _cupertino.buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.6, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    }
    final inT = CurvedAnimation(parent: animation, curve: voltEase, reverseCurve: Curves.easeInCubic);
    final outT = CurvedAnimation(parent: secondaryAnimation, curve: voltEase);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(outT),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.97).animate(outT),
        child: FadeTransition(
          opacity: inT,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(inT),
            child: child,
          ),
        ),
      ),
    );
  }
}
