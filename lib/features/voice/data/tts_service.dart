import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// On-device text-to-speech, used as the fallback voice when the n8n
/// response doesn't include synthesized `audio_base64` (or the device is
/// offline and replaying a locally-generated reply).
class TtsService {
  TtsService() {
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0);
  }

  final FlutterTts _tts = FlutterTts();

  Future<void> setLanguage(String languageCode) => _tts.setLanguage(languageCode);

  Future<void> speak(String text) => _tts.speak(text);

  Future<void> stop() => _tts.stop();

  void onStart(VoidCallback callback) => _tts.setStartHandler(callback);
  void onComplete(VoidCallback callback) => _tts.setCompletionHandler(callback);
  void onCancel(VoidCallback callback) => _tts.setCancelHandler(callback);
}

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
