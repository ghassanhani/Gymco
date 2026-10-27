import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'cloud.dart';
import 'dictation.dart';

/// A voice note: recording with live loudness, then the words it said.
abstract class Voice {
  /// How loud it is right now, 0 to 1, while it records.
  Stream<double> get level;

  /// False when the microphone is refused or there is nothing to hear with.
  Future<bool> start({required String languageCode});

  /// Stops and gives what was said; empty when nothing was heard. Throws a
  /// [CloudException] when the words could not be fetched.
  Future<String> finish();

  /// Stops and throws the recording away.
  Future<void> cancel();
}

/// Records the note on the phone and has it written down on our server
/// (OpenAI's transcription, which follows Arabic and English, even mixed).
/// The recording is deleted once it is sent.
class CloudVoice implements Voice {
  CloudVoice(this._cloud, {this.bucket});
  final Cloud _cloud;
  final int? bucket;
  final _rec = AudioRecorder();
  final _level = StreamController<double>.broadcast();
  StreamSubscription<Amplitude>? _amp;
  String? _path;
  String _lang = 'en';
  DateTime? _started;

  @override
  Stream<double> get level => _level.stream;

  @override
  Future<bool> start({required String languageCode}) async {
    if (!await _rec.hasPermission()) return false;
    _lang = languageCode;
    final dir = await getTemporaryDirectory();
    _path = p.join(dir.path, 'voice-${DateTime.now().millisecondsSinceEpoch}.m4a');
    await _rec.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1, bitRate: 32000),
      path: _path!,
    );
    _started = DateTime.now();
    // dBFS from about -60 (quiet room) to 0 (shouting), as 0 to 1.
    _amp = _rec
        .onAmplitudeChanged(const Duration(milliseconds: 70))
        .listen((a) => _level.add(((a.current + 60) / 60).clamp(0, 1).toDouble()));
    return true;
  }

  @override
  Future<String> finish() async {
    await _amp?.cancel();
    final path = await _rec.stop() ?? _path;
    final seconds = _started == null ? 0.0 : DateTime.now().difference(_started!).inMilliseconds / 1000;
    if (path == null) return '';
    final file = File(path);
    try {
      final Uint8List audio = await file.readAsBytes();
      // Too short to hold a word: nothing to send.
      if (seconds < 0.6 || audio.length < 2000) return '';
      return await _cloud.transcribe(audio, languageCode: _lang, seconds: seconds, bucket: bucket);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<void> cancel() async {
    await _amp?.cancel();
    await _rec.cancel();
  }
}

/// The phone's own recogniser, for when there is no account to send the
/// recording to.
class DeviceVoice implements Voice {
  DeviceVoice(this._dictation);
  final Dictation _dictation;
  var _words = '';

  @override
  Stream<double> get level => _dictation.level;

  @override
  Future<bool> start({required String languageCode}) {
    _words = '';
    return _dictation.start(languageCode: languageCode, onWords: (w) => _words = w);
  }

  @override
  Future<String> finish() async {
    await _dictation.stop();
    // The last words can land just after stopping.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _words.trim();
  }

  @override
  Future<void> cancel() => _dictation.stop();
}
