import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/utils/app_exception.dart';

/// Thin wrapper around `package:record` for capturing raw microphone audio
/// to send to the n8n backend as base64.
class RecordService {
  final _recorder = AudioRecorder();

  Future<void> start() async {
    if (!await Permission.microphone.request().isGranted) {
      throw const PermissionDeniedException('Microphone permission denied.');
    }
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/jarvis_input_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
  }

  Future<String?> stop() => _recorder.stop();

  Future<bool> isRecording() => _recorder.isRecording();

  Future<List<int>> readBytes(String path) => File(path).readAsBytes();

  /// Real-time amplitude stream (dBFS-normalized to 0..1) used to drive
  /// the orb's waveform while listening.
  Stream<double> amplitudeStream() {
    return _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .map((amp) => ((amp.current + 45) / 45).clamp(0.0, 1.0));
  }

  void dispose() => _recorder.dispose();
}

final recordServiceProvider = Provider<RecordService>((ref) {
  final service = RecordService();
  ref.onDispose(service.dispose);
  return service;
});
