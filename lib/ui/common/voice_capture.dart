import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud.dart';
import '../../data/voice.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import '../me/account_screen.dart' show cloudMessage;

/// The longest note, so one can't run on by accident.
const voiceMaxSeconds = 60;

/// A voice note being taken: it starts as soon as it shows, with a red dot,
/// the time and a wave that moves with the voice, so it's plain the mic is
/// open. Done sends it to be written down; the words go to [onText], never
/// into a box. [onClose] when it ends with nothing (cancelled, nothing heard,
/// or it failed, which it says).
class VoiceCapture extends ConsumerStatefulWidget {
  const VoiceCapture({
    super.key,
    required this.onText,
    required this.onClose,
    this.doneLabel,
    this.colors,
    this.height = 44,
  });

  final ValueChanged<String> onText;
  final VoidCallback onClose;

  /// What finishing does, for its tooltip.
  final String? doneLabel;

  /// The done button's gradient; the app's lime by default.
  final List<Color>? colors;
  final double height;

  @override
  ConsumerState<VoiceCapture> createState() => _VoiceCaptureState();
}

enum _Phase { starting, recording, writing }

class _VoiceCaptureState extends ConsumerState<VoiceCapture> with SingleTickerProviderStateMixin {
  late final Voice _voice = ref.read(voiceProvider)();
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  final _levels = List<double>.filled(32, 0, growable: true);
  StreamSubscription<double>? _sub;
  Timer? _clock;
  var _phase = _Phase.starting;
  var _seconds = 0;
  var _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _sub?.cancel();
    _pulse.dispose();
    if (!_done) _voice.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    _sub = _voice.level.listen((v) {
      if (!mounted || _phase != _Phase.recording) return;
      setState(() {
        _levels.removeAt(0);
        _levels.add(v);
      });
    });
    final ok = await _voice.start(languageCode: Localizations.localeOf(context).languageCode);
    if (!mounted) return;
    if (!ok) {
      _done = true;
      showVToast(context, l.voiceUnavailable, info: true);
      widget.onClose();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.recording);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= voiceMaxSeconds) _finish();
    });
  }

  Future<void> _finish() async {
    if (_phase != _Phase.recording) return;
    final l = AppLocalizations.of(context);
    _clock?.cancel();
    HapticFeedback.lightImpact();
    setState(() => _phase = _Phase.writing);
    _done = true;
    try {
      final text = await _voice.finish();
      if (!mounted) return;
      if (text.isEmpty) {
        showVToast(context, l.voiceNothing, info: true);
        widget.onClose();
      } else {
        widget.onText(text);
      }
    } on CloudException catch (e) {
      if (!mounted) return;
      showVToast(context, cloudMessage(l, e.failure), info: true);
      widget.onClose();
    }
  }

  Future<void> _cancel() async {
    _done = true;
    _clock?.cancel();
    await _voice.cancel();
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = widget.height;
    if (_phase == _Phase.writing) {
      return SizedBox(
        height: h,
        child: Row(
          children: [
            const SizedBox(width: 12),
            SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Volt.t3)),
            const SizedBox(width: 12),
            Expanded(child: Muted(l.voiceWriting, size: 14.5)),
          ],
        ),
      );
    }
    const red = Color(0xFFFF453A);
    final time = '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      liveRegion: true,
      label: l.voiceRecording(time),
      child: SizedBox(
        height: h,
        child: Row(
          children: [
            IconBtn('close', label: l.voiceCancel, size: h - 8, iconSize: 14, color: Volt.t2, onTap: _cancel),
            const SizedBox(width: 8),
            FadeTransition(
              opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(color: red, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Volt.t1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExcludeSemantics(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _Wave(levels: _levels, color: _phase == _Phase.recording ? Volt.t1 : Volt.t4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: widget.doneLabel ?? l.voiceDone,
              child: Semantics(
                button: true,
                label: widget.doneLabel ?? l.voiceDone,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: _finish,
                  child: Container(
                    width: h,
                    height: h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.colors ?? [Volt.lime, Volt.lime],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: VIcon('up', size: 18, color: widget.colors == null ? Volt.ink : Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bars for the last moments of sound, newest on the end, centred on a line.
class _Wave extends CustomPainter {
  _Wave({required this.levels, required this.color});
  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final n = levels.length;
    final step = size.width / n;
    final bar = math.max(2.0, step * 0.5);
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bar;
    final mid = size.height / 2;
    for (var i = 0; i < n; i++) {
      // A floor so silence still shows a line of dots.
      final v = 0.08 + 0.92 * levels[i];
      final half = math.max(1.0, v * (size.height / 2 - 2));
      final x = step * i + step / 2;
      canvas.drawLine(Offset(x, mid - half), Offset(x, mid + half), paint);
    }
  }

  @override
  bool shouldRepaint(_Wave old) => true;
}
