import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Plays base64-encoded audio returned by the n8n webhook (TTS output).
class AudioPlayerService {
  final _player = AudioPlayer();

  Stream<PlayerState> get playerState => _player.playerStateStream;

  Future<void> playBase64(String base64String) async {
    final bytes = base64Decode(base64String);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/jarvis_reply_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);
    await _player.setFilePath(file.path);
    await _player.play();
  }

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});
