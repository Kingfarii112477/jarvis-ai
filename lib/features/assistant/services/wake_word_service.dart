import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final wakeWordServiceProvider = Provider<WakeWordService>((ref) => WakeWordService());

class WakeWordService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isListening = false;
  String? _currentFilePath;

  bool get isListening => _isListening;

  Future<void> startContinuousListening() async {
    if (_isListening) return;

    try {
      if (await _recorder.hasPermission()) {
        _isListening = true;
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/continuous_audio.m4a';
        _currentFilePath = filePath;

        await _recorder.start(
          const RecordConfig(),
          path: filePath,
        );
      }
    } catch (e) {
      _isListening = false;
      rethrow;
    }
  }

  Future<void> stopContinuousListening() async {
    if (!_isListening) return;

    try {
      await _recorder.stop();
      _isListening = false;
    } catch (e) {
      _isListening = false;
      rethrow;
    }
  }

  Future<String?> pauseAndGetAudio() async {
    if (!_isListening) return null;

    try {
      final path = await _recorder.stop();
      _isListening = false;

      // Restart recording for continuous listening
      await Future.delayed(const Duration(milliseconds: 100));
      await startContinuousListening();

      return path;
    } catch (e) {
      _isListening = false;
      rethrow;
    }
  }

  Future<List<int>> getAudioBytes(String path) async {
    final file = File(path);
    return await file.readAsBytes();
  }

  /// Simple wake word detection based on audio energy
  /// In production, use a proper wake word detection library
  Future<bool> detectWakeWord(
    String audioPath,
    String wakeWord,
    double sensitivity,
  ) async {
    try {
      final file = File(audioPath);
      final bytes = await file.readAsBytes();

      // Simple energy-based detection
      // In production, integrate with a proper wake word model
      int totalEnergy = 0;
      for (int i = 0; i < bytes.length - 1; i += 2) {
        final sample = (bytes[i] | (bytes[i + 1] << 8)).toSigned(16);
        totalEnergy += (sample * sample).toInt();
      }

      final averageEnergy = totalEnergy ~/ (bytes.length ~/ 2);
      final threshold = (32768 * 32768 * sensitivity).toInt();

      return averageEnergy > threshold;
    } catch (e) {
      return false;
    }
  }

  Future<void> dispose() async {
    if (_isListening) {
      await stopContinuousListening();
    }
    await _recorder.dispose();
  }
}
