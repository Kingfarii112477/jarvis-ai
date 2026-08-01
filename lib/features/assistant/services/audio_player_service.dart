import 'dart:convert';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioPlayerServiceProvider = Provider((ref) => AudioPlayerService());

class AudioPlayerService {
  final _player = AudioPlayer();

  Future<void> playBase64(String base64String) async {
    final bytes = base64Decode(base64String);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/audio_output.mp3');
    await file.writeAsBytes(bytes);
    
    await _player.setFilePath(file.path);
    await _player.play();
  }

  void dispose() {
    _player.dispose();
  }
}
