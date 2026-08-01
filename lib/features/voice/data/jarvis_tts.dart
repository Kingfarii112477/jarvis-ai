import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// On-device text-to-speech for JARVIS.
///
/// Replaces the remote Edge-TTS server entirely: no ngrok tunnel, no
/// `audio_url`/`audio_base64`, no network round-trip. The backend only has
/// to return reply text and this speaks it.
///
/// Usage:
///   await JarvisTts.instance.init();          // once, at app start
///   await JarvisTts.instance.speak(replyText);
///   await JarvisTts.instance.stop();          // e.g. when mic is pressed
class JarvisTts {
  JarvisTts._();
  static final JarvisTts instance = JarvisTts._();

  final FlutterTts _tts = FlutterTts();

  bool _ready = false;
  bool _speaking = false;

  bool get isReady => _ready;

  /// Emits true while speaking — wire this to the orb's SPEAKING state.
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  /// Voices we prefer, best first. Deep, calm, British reads closest to JARVIS.
  static const List<String> _preferredVoiceHints = <String>[
    'en-gb-x-gbb', // Google UK English Male (network + local variants)
    'en-gb-x-rjs', // Google UK English Male, alternate
    'en-gb', // any UK English
    'en-au', // Australian male is a decent fallback
    'en-us-x-iom', // US male
    'en-us',
  ];

  Future<void> init() async {
    if (_ready) return;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-GB');

    // Slightly below default pitch and pace: measured, not chirpy.
    await _tts.setPitch(0.85);
    await _tts.setSpeechRate(Platform.isAndroid ? 0.48 : 0.46);
    await _tts.setVolume(1.0);

    await _selectBestVoice();

    _tts.setStartHandler(() {
      _speaking = true;
      isSpeaking.value = true;
    });
    _tts.setCompletionHandler(() {
      _speaking = false;
      isSpeaking.value = false;
    });
    _tts.setCancelHandler(() {
      _speaking = false;
      isSpeaking.value = false;
    });
    _tts.setErrorHandler((dynamic message) {
      debugPrint('JarvisTts error: $message');
      _speaking = false;
      isSpeaking.value = false;
    });

    _ready = true;
  }

  /// Walks the installed voices and picks the closest match to a JARVIS voice.
  Future<void> _selectBestVoice() async {
    try {
      final dynamic raw = await _tts.getVoices;
      if (raw is! List) return;

      final List<Map<String, String>> voices = raw
          .whereType<Map>()
          .map((Map<dynamic, dynamic> v) => v.map(
                (dynamic k, dynamic value) =>
                    MapEntry<String, String>(k.toString(), value.toString()),
              ))
          .where((Map<String, String> v) =>
              (v['locale'] ?? '').toLowerCase().startsWith('en'))
          .toList();

      if (voices.isEmpty) return;

      for (final String hint in _preferredVoiceHints) {
        for (final Map<String, String> v in voices) {
          final String haystack =
              '${v['name'] ?? ''} ${v['locale'] ?? ''}'.toLowerCase();
          if (haystack.contains(hint)) {
            // Android needs both name and locale to resolve the voice.
            await _tts.setVoice(<String, String>{
              'name': v['name'] ?? '',
              'locale': v['locale'] ?? 'en-GB',
            });
            debugPrint('JarvisTts voice: ${v['name']} (${v['locale']})');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('JarvisTts voice selection failed, using default: $e');
    }
  }

  /// Speaks [text]. Interrupts anything already playing.
  Future<void> speak(String? text) async {
    final String clean = sanitizeForSpeech(text ?? '');
    if (clean.isEmpty) return;

    if (!_ready) await init();
    if (_speaking) await stop();

    await _tts.speak(clean);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
    isSpeaking.value = false;
  }

  Future<void> pause() async => _tts.pause();

  /// Strips anything that would be read aloud as literal junk.
  /// The backend prompt already forbids markdown, but belt and braces.
  ///
  /// Exposed (rather than private) so it can be unit-tested directly — it is
  /// the one piece of this class with real logic and no platform channel.
  @visibleForTesting
  static String sanitizeForSpeech(String input) {
    return input
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'[*_`#>]'), '')
        // NOTE: must be replaceAllMapped, not replaceAll. Dart's replaceAll
        // treats "$1" as a literal string rather than a capture-group
        // reference, so a markdown link would be spoken as "dollar one".
        .replaceAllMapped(
          RegExp(r'\[([^\]]*)\]\([^)]*\)'),
          (Match m) => m.group(1) ?? '',
        )
        .replaceAll(RegExp(r'https?://\S+'), 'a link')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Returns installed English voices — used by the picker in Settings.
  Future<List<String>> availableVoiceNames() async {
    final dynamic raw = await _tts.getVoices;
    if (raw is! List) return <String>[];
    return raw
        .whereType<Map>()
        .where((Map<dynamic, dynamic> v) =>
            (v['locale']?.toString() ?? '').toLowerCase().startsWith('en'))
        .map((Map<dynamic, dynamic> v) => v['name']?.toString() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
  }

  /// Applies a voice chosen from [availableVoiceNames].
  Future<void> setVoiceByName(String name, {String locale = 'en-GB'}) async {
    await _tts.setVoice(<String, String>{'name': name, 'locale': locale});
  }

  /// Deliberately not called from a Riverpod `onDispose`: this is an
  /// app-lifetime singleton, and disposing [isSpeaking] would leave the
  /// notifier unusable if a provider were ever rebuilt.
  void dispose() {
    _tts.stop();
    isSpeaking.dispose();
  }
}

/// DI handle for the singleton, so the rest of the app keeps resolving
/// services through Riverpod rather than reaching for a global.
final jarvisTtsProvider = Provider<JarvisTts>((ref) => JarvisTts.instance);
