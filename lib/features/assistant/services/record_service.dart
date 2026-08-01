import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final recordServiceProvider = Provider((ref) => RecordService());

class RecordService {
  final _audioRecorder = AudioRecorder();

  Future<void> start() async {
    if (await Permission.microphone.request().isGranted) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/audio_input.m4a';
      
      const config = RecordConfig();
      await _audioRecorder.start(config, path: path);
    } else {
      throw Exception('Microphone permission denied');
    }
  }

  Future<String?> stop() async {
    return await _audioRecorder.stop();
  }

  Future<List<int>> getAudioBytes(String path) async {
    return await File(path).readAsBytes();
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
