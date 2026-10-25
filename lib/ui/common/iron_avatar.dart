import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'celebrations.dart' show CelebrationSound;
import 'iron_art.g.dart';

/// How Iron feels, and so how it moves.
enum IronMood {
  /// Bobs, blinks, glances around.
  idle,

  /// Sparkle eyes, a quick little bounce: a tip, a good day.
  happy,

  /// Arms up, jumping with squash and stretch: a program ready, a big win.
  cheer,

  /// Worried brows and a shake, an exclamation over its head: a warning sign.
  alert,

  /// Looks up while dots fill in: Iron is working something out.
  thinking,

  /// Eyes shut, breathing slowly, a z above: a rest day, a short night.
  sleepy,
}

/// Iron, the kettlebell coach, drawn from its pixel art (tool/iron/art.json)
/// and moved in code, so each mood has its own motion. With [announce],
/// becoming [IronMood.cheer] or [IronMood.alert] also plays its sound: keep
/// that for the moments that matter. Still in widget tests, so they settle.
class IronAvatar extends StatefulWidget {
  const IronAvatar({super.key, this.mood = IronMood.idle, this.size = 44, this.announce = false});
  final IronMood mood;
  final double size;
  final bool announce;

  static final still = Platform.environment.containsKey('FLUTTER_TEST');

  @override
  State<IronAvatar> createState() => _IronAvatarState();
}

class _IronAvatarState extends State<IronAvatar> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  var _ms = 0;

  /// When the current mood began, so a jump starts from the ground.
  var _since = 0;

  @override
  void initState() {
    super.initState();
    if (!IronAvatar.still) {
      _ticker = createTicker((elapsed) {
        // Pixel art moves in steps: about 16 a second is plenty.
        final ms = elapsed.inMilliseconds;
        if (ms ~/ 60 != _ms ~/ 60) setState(() => _ms = ms);
      })..start();
    }
    _sound();
  }

  @override
  void didUpdateWidget(IronAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _since = _ms;
      _sound();
    }
  }

  void _sound() {
    if (!widget.announce) return;
    switch (widget.mood) {
      case IronMood.cheer:
        CelebrationSound.play('iron_cheer');
      case IronMood.alert:
        CelebrationSound.play('iron_alert');
      default:
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: IronFrame(ironPose(widget.mood, _ms, _ms - _since), size: widget.size));
  }
}

/// Iron drawn in one [pose].
class IronFrame extends StatelessWidget {
  const IronFrame(this.pose, {super.key, this.size = 44});
  final IronPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    final px = size / ironSize;
    return SizedBox.square(
      dimension: size,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..translateByDouble(pose.dx * px, pose.dy * px, 0, 1)
          ..scaleByDouble(pose.sx, pose.sy, 1, 1),
        child: CustomPaint(painter: _IronPainter(pose)),
      ),
    );
  }
}

/// One frame of Iron: which body, face and extras, and how it is moved, in
/// art pixels.
class IronPose {
  const IronPose({
    required this.body,
    this.face,
    this.extras = const [],
    this.dx = 0,
    this.dy = 0,
    this.sx = 1,
    this.sy = 1,
    this.extraDy = 0,
  });
  final String body;
  final String? face;
  final List<String> extras;
  final double dx, dy, sx, sy;

  /// The extras drift on their own: rising z, a bouncing exclamation.
  final int extraDy;
}

/// Iron at [ms], [inMood] milliseconds into its mood. Pure, so tests and the
/// SVG export can ask for any frame.
IronPose ironPose(IronMood mood, int ms, int inMood) {
  final beat = ms ~/ 520 % 2 == 1;
  final body = beat ? 'hop' : 'stand';
  switch (mood) {
    case IronMood.idle:
      final t = ms % 9000;
      final blink = ms % 4200 < 160;
      final face = blink
          ? 'blink'
          : t > 5200 && t < 6000
          ? 'look_left'
          : t > 6000 && t < 6800
          ? 'look_right'
          : 'open';
      return IronPose(body: body, face: face);
    case IronMood.happy:
      // A small hop every second and a half, sparkle twinkling.
      final p = ms % 1500 / 1500;
      final hop = p < 0.3 ? -math.sin(p / 0.3 * math.pi) * 2.5 : 0.0;
      return IronPose(
        body: p < 0.3 ? 'hop' : 'stand',
        face: 'happy',
        extras: [if (ms ~/ 300 % 2 == 0) 'sparkle'],
        dy: hop.roundToDouble(),
      );
    case IronMood.cheer:
      // Crouch, spring up, land with a squash, again.
      final p = inMood % 900 / 900;
      if (p < 0.14) return IronPose(body: 'cheer_b', sx: 1.1, sy: 0.86, extras: const ['sparkle']);
      if (p < 0.78) {
        final air = (p - 0.14) / 0.64;
        return IronPose(
          body: 'cheer_a',
          dy: (-math.sin(air * math.pi) * 6).roundToDouble(),
          sx: 0.95,
          sy: 1.06,
          extras: [if (ms ~/ 200 % 2 == 0) 'sparkle'],
        );
      }
      return IronPose(body: 'cheer_b', sx: 1.08, sy: 0.9, extras: const ['sparkle']);
    case IronMood.alert:
      // A shake when it starts and every few seconds, the "!" bouncing.
      final t = inMood % 2600;
      final shake = t < 560 ? (t ~/ 70 % 2 == 0 ? 1.0 : -1.0) : 0.0;
      return IronPose(body: 'stand', face: 'worried', extras: const ['alert'], dx: shake, extraDy: ms ~/ 400 % 2);
    case IronMood.thinking:
      final dots = ms ~/ 380 % 4;
      return IronPose(
        body: body,
        face: ms % 3000 < 1500 ? 'look_up' : 'look_right',
        extras: [if (dots > 0) 'dot1', if (dots > 1) 'dot2', if (dots > 2) 'dot3'],
      );
    case IronMood.sleepy:
      final breathe = math.sin(ms / 2600 * 2 * math.pi);
      return IronPose(
        body: 'stand',
        face: 'blink',
        extras: const ['zz'],
        sy: 1 + 0.03 * breathe,
        sx: 1 - 0.015 * breathe,
        extraDy: -(ms ~/ 700 % 3),
      );
  }
}

class _IronPainter extends CustomPainter {
  _IronPainter(this.pose);
  final IronPose pose;

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / ironSize;
    final paint = Paint()..isAntiAlias = false;
    void cell(int x, int y, String c) {
      final color = ironPalette[c];
      if (color == null) return;
      paint.color = Color(color);
      // A hair over a pixel so neighbours never show a seam.
      canvas.drawRect(Rect.fromLTWH(x * px, y * px, px + 0.5, px + 0.5), paint);
    }

    final rows = ironBodies[pose.body]!;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] != '.') cell(x, y, rows[y][x]);
      }
    }
    final faceDy = pose.body == 'hop' ? ironHopDy : 0;
    for (final (x, y, c) in ironFaces[pose.face] ?? const <(int, int, String)>[]) {
      cell(x, y + faceDy, c);
    }
    for (final e in pose.extras) {
      for (final (x, y, c) in ironExtras[e]!) {
        cell(x, y + pose.extraDy + (e == 'sparkle' ? faceDy : 0), c);
      }
    }
  }

  @override
  bool shouldRepaint(_IronPainter old) =>
      old.pose.body != pose.body ||
      old.pose.face != pose.face ||
      old.pose.extraDy != pose.extraDy ||
      old.pose.extras.join() != pose.extras.join();
}
