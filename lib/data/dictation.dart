import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

/// Speech to text through the phone's own recogniser (Siri dictation on iOS,
/// Google's on Android): nothing reaches our servers and nothing costs.
abstract class Dictation {
  /// False when the phone has no recogniser or the microphone was refused.
  Future<bool> start({required String languageCode, required void Function(String words) onWords});
  Future<void> stop();

  /// How loud it is while listening, 0 to 1.
  Stream<double> get level;
}

class DeviceDictation implements Dictation {
  final _stt = SpeechToText();
  final _level = StreamController<double>.broadcast();
  bool? _ready;

  // Platforms report loudness on different scales, so it is measured
  // against the quietest and loudest seen so far.
  double _low = 0, _high = 1;

  @override
  Stream<double> get level => _level.stream;

  void _onLevel(double v) {
    if (v < _low) _low = v;
    if (v > _high) _high = v;
    _level.add(((v - _low) / (_high - _low)).clamp(0, 1).toDouble());
  }

  @override
  Future<bool> start({required String languageCode, required void Function(String words) onWords}) async {
    _ready ??= await _stt.initialize();
    if (_ready != true) return false;
    final locales = await _stt.locales();
    final locale = locales.where((l) => l.localeId.toLowerCase().startsWith(languageCode)).firstOrNull;
    await _stt.listen(
      onResult: (r) => onWords(r.recognizedWords),
      onSoundLevelChange: _onLevel,
      listenOptions: SpeechListenOptions(
        localeId: locale?.localeId,
        partialResults: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
      ),
    );
    return true;
  }

  @override
  Future<void> stop() => _stt.stop();
}
