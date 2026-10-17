import 'package:speech_to_text/speech_to_text.dart';

/// Speech to text through the phone's own recogniser (Siri dictation on iOS,
/// Google's on Android): nothing reaches our servers and nothing costs.
abstract class Dictation {
  /// False when the phone has no recogniser or the microphone was refused.
  Future<bool> start({required String languageCode, required void Function(String words) onWords});
  Future<void> stop();
}

class DeviceDictation implements Dictation {
  final _stt = SpeechToText();
  bool? _ready;

  @override
  Future<bool> start({required String languageCode, required void Function(String words) onWords}) async {
    _ready ??= await _stt.initialize();
    if (_ready != true) return false;
    final locales = await _stt.locales();
    final locale = locales.where((l) => l.localeId.toLowerCase().startsWith(languageCode)).firstOrNull;
    await _stt.listen(
      onResult: (r) => onWords(r.recognizedWords),
      listenOptions: SpeechListenOptions(
        localeId: locale?.localeId,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
    return true;
  }

  @override
  Future<void> stop() => _stt.stop();
}
