import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/utils/app_exception.dart';

/// On-device speech recognition (Android's `SpeechRecognizer` /
/// iOS `SFSpeechRecognizer` under the hood via `speech_to_text`). Used for
/// live captions while the user talks — independent of whatever ASR the
/// n8n backend itself performs on the uploaded audio.
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;

  Future<bool> init() async {
    if (!await Permission.microphone.request().isGranted) {
      throw const PermissionDeniedException('Microphone permission denied.');
    }
    _available = await _speech.initialize(finalTimeout: const Duration(seconds: 3));
    return _available;
  }

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_available) return;
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        localeId: localeId,
      ),
    );
  }

  Future<void> stop() => _speech.stop();
  Future<void> cancel() => _speech.cancel();
}

final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) => SpeechToTextService());
