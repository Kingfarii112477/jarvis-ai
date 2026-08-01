import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dto/n8n_request.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_exception.dart';
import '../../analytics/data/analytics_repository.dart';
import '../../analytics/domain/usage_event.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_message.dart';
import '../../chat/presentation/chat_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/jarvis_tts.dart';
import '../data/record_service.dart';
import '../data/speech_to_text_service.dart';
import 'package:uuid/uuid.dart';

const _voiceSessionTitle = 'Voice Assistant';

class VoiceState {
  const VoiceState({
    this.mood = AssistantMood.idle,
    this.isListening = false,
    this.isContinuous = false,
    this.liveTranscript = '',
    this.lastReply = '',
    this.amplitude,
    this.error,
  });

  final AssistantMood mood;
  final bool isListening;
  final bool isContinuous;
  final String liveTranscript;
  final String lastReply;
  final double? amplitude;
  final String? error;

  VoiceState copyWith({
    AssistantMood? mood,
    bool? isListening,
    bool? isContinuous,
    String? liveTranscript,
    String? lastReply,
    double? amplitude,
    bool clearAmplitude = false,
    String? error,
    bool clearError = false,
  }) {
    return VoiceState(
      mood: mood ?? this.mood,
      isListening: isListening ?? this.isListening,
      isContinuous: isContinuous ?? this.isContinuous,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      lastReply: lastReply ?? this.lastReply,
      amplitude: clearAmplitude ? null : (amplitude ?? this.amplitude),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final voiceControllerProvider = StateNotifierProvider<VoiceController, VoiceState>((ref) {
  return VoiceController(ref);
});

class VoiceController extends StateNotifier<VoiceState> {
  VoiceController(this._ref) : super(const VoiceState()) {
    _init();
  }

  final Ref _ref;
  static const _uuid = Uuid();
  StreamSubscription<double>? _amplitudeSub;
  String? _voiceChatId;

  RecordService get _record => _ref.read(recordServiceProvider);
  SpeechToTextService get _stt => _ref.read(speechToTextServiceProvider);
  JarvisTts get _tts => _ref.read(jarvisTtsProvider);
  ApiClient get _api => _ref.read(apiClientProvider);
  ChatRepository get _chatRepo => _ref.read(chatRepositoryProvider);
  SecureStorageService get _secureStorage => _ref.read(secureStorageProvider);
  AnalyticsRepository get _analytics => _ref.read(analyticsRepositoryProvider);

  Future<void> _init() async {
    try {
      await _stt.init();
    } catch (e) {
      state = state.copyWith(error: describeException(e is Exception ? e : UnknownException(e.toString())));
    }
    // The orb's SPEAKING state is driven by the TTS engine's own callbacks
    // (surfaced as this ValueNotifier) rather than by guessing at timing
    // around the speak() call, so it stays in sync if speech is cut short.
    _tts.isSpeaking.addListener(_onSpeakingChanged);
  }

  void _onSpeakingChanged() {
    if (!mounted) return;
    if (_tts.isSpeaking.value) {
      state = state.copyWith(mood: AssistantMood.speaking, clearAmplitude: true);
    } else if (state.mood == AssistantMood.speaking) {
      state = state.copyWith(mood: AssistantMood.idle, clearAmplitude: true);
    }
  }

  Future<String> _ensureVoiceChatId() async {
    if (_voiceChatId != null) return _voiceChatId!;
    final existing = _chatRepo.getSessions().where((s) => s.title == _voiceSessionTitle).firstOrNull;
    final session = existing ?? await _chatRepo.createSession(title: _voiceSessionTitle);
    _voiceChatId = session.id;
    return session.id;
  }

  Future<void> startPushToTalk() async {
    try {
      // Barge-in: pressing the mic cuts JARVIS off mid-sentence.
      await _tts.stop();
      await _record.start();
      state = state.copyWith(mood: AssistantMood.listening, isListening: true, liveTranscript: '', clearError: true);
      await _amplitudeSub?.cancel();
      _amplitudeSub = _record.amplitudeStream().listen((level) {
        state = state.copyWith(amplitude: level);
      });
      unawaited(_stt.listen(
        onResult: (text, isFinal) => state = state.copyWith(liveTranscript: text),
      ));
    } catch (e) {
      state = state.copyWith(mood: AssistantMood.error, isListening: false, error: describeException(_asAppException(e)));
    }
  }

  Future<void> stopPushToTalk() async {
    if (!state.isListening) return;
    await _amplitudeSub?.cancel();
    final path = await _record.stop();
    await _stt.stop();
    state = state.copyWith(isListening: false, mood: AssistantMood.processing, clearAmplitude: true);

    final transcript = state.liveTranscript.trim();
    if (transcript.isEmpty && path == null) {
      state = state.copyWith(mood: AssistantMood.idle);
      return;
    }
    await _sendTurn(transcript.isNotEmpty ? transcript : '(voice message)', audioPath: path);
  }

  Future<void> _sendTurn(String text, {String? audioPath}) async {
    final chatId = await _ensureVoiceChatId();
    final userId = await _secureStorage.userId ?? 'usr_jarvis_mobile';

    await _chatRepo.saveMessage(ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      isVoice: true,
    ));

    final request = N8nRequest(
      userId: userId,
      chatId: chatId,
      messageType: 'voice',
      text: text,
      device: const {'platform': 'android', 'app': 'jarvis'},
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );

    final result = await _api.postToWebhook(request);
    await result.when(
      ok: (response) async {
        await _chatRepo.saveMessage(ChatMessage(
          id: _uuid.v4(),
          chatId: chatId,
          text: response.text,
          isUser: false,
          toolUsed: response.toolUsed,
          timestamp: DateTime.now(),
          isVoice: true,
        ));
        state = state.copyWith(lastReply: response.text);
        // Speech is always synthesized on-device now. Any `audio_base64` the
        // backend still returns is deliberately ignored, so the app no longer
        // depends on a remote TTS service (or its tunnel) being reachable.
        await _tts.speak(response.text);
      },
      err: (error) async {
        state = state.copyWith(mood: AssistantMood.error, error: describeException(error));
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) state = state.copyWith(mood: AssistantMood.idle, clearError: true);
      },
    );

    await _analytics.logEvent(UsageEventType.voiceInteraction);
  }

  Future<void> toggleContinuous() async {
    final next = !state.isContinuous;
    state = state.copyWith(isContinuous: next);
    await _ref.read(appSettingsProvider.notifier).setContinuousListening(next);
    if (next) {
      await startPushToTalk();
    } else if (state.isListening) {
      await stopPushToTalk();
    }
  }

  AppException _asAppException(Object e) => e is AppException ? e : UnknownException(e.toString(), cause: e);

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _tts.isSpeaking.removeListener(_onSpeakingChanged);
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
