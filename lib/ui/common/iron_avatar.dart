import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How Iron looks: calm, pleased with you, or cheering.
enum IronMood { idle, happy, cheer }

/// Iron, the kettlebell coach, as a small pixel-art character. It bobs
/// between its two frames and blinks now and then while idle; happy shows
/// the sparkle eyes, cheer puts its arms up. Still in widget tests, so a
/// test can settle.
class IronAvatar extends StatefulWidget {
  const IronAvatar({super.key, this.mood = IronMood.idle, this.size = 44});
  final IronMood mood;
  final double size;

  static final _still = Platform.environment.containsKey('FLUTTER_TEST');

  @override
  State<IronAvatar> createState() => _IronAvatarState();
}

class _IronAvatarState extends State<IronAvatar> {
  Timer? _timer;
  var _frame = 0;
  var _blink = false;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    if (!IronAvatar._still) _timer = Timer.periodic(const Duration(milliseconds: 520), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _frame = 1 - _frame;
      // A blink lasts one beat, about once every four seconds.
      _blink = widget.mood == IronMood.idle && !_blink && _random.nextInt(8) == 0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final m in ['idle', 'blink', 'happy', 'cheer']) {
      for (final f in ['a', 'b']) {
        precacheImage(AssetImage('assets/iron/iron_${m}_$f.png'), context);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pose = switch (widget.mood) {
      IronMood.idle => _blink ? 'blink' : 'idle',
      IronMood.happy => 'happy',
      IronMood.cheer => 'cheer',
    };
    return ExcludeSemantics(
      child: Image.asset(
        'assets/iron/iron_${pose}_${_frame == 0 ? 'a' : 'b'}.png',
        width: widget.size,
        height: widget.size,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      ),
    );
  }
}
