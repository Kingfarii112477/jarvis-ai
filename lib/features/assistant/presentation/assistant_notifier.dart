import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/chat_message.dart';
import 'widgets/animated_orb.dart';
import '../services/record_service.dart';
import '../services/audio_player_service.dart';
import '../services/wake_word_service.dart';
import '../../../core/network/api_client.dart';
import '../../settings/presentation/settings_provider.dart';

class AssistantState {
  final List<ChatMessage> messages;
  final OrbState orbState;
  final bool isRecording;
  final bool isContinuousListening;
  final String? error;

  AssistantState({
    required this.messages,
    required this.orbState,
    required this.isRecording,
    required this.isContinuousListening,
    this.error,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    OrbState? orbState,
    bool? isRecording,
    bool? isContinuousListening,
    String? error,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      orbState: orbState ?? this.orbState,
      isRecording: isRecording ?? this.isRecording,
      isContinuousListening: isContinuousListening ?? this.isContinuousListening,
      error: error,
    );
  }
}

final assistantProvider = StateNotifierProvider<AssistantNotifier, AssistantState>((ref) {
  return AssistantNotifier(
    ref.read(apiClientProvider),
    ref.read(recordServiceProvider),
    ref.read(audioPlayerServiceProvider),
    ref.read(wakeWordServiceProvider),
    ref.read(settingsProvider),
  );
});

class AssistantNotifier extends StateNotifier<AssistantState> {
  final ApiClient _apiClient;
  final RecordService _recordService;
  final AudioPlayerService _audioPlayerService;
  final WakeWordService _wakeWordService;
  final SettingsState _settings;
  final _uuid = const Uuid();
  Timer? _continuousListeningTimer;

  AssistantNotifier(
    this._apiClient,
    this._recordService,
    this._audioPlayerService,
    this._wakeWordService,
    this._settings,
  ) : super(
    AssistantState(
      messages: [],
      orbState: OrbState.idle,
      isRecording: false,
      isContinuousListening: false,
    ),
  ) {
    _initializeContinuousListening();
  }

  void _initializeContinuousListening() {
    if (_settings.continuousListening) {
      startContinuousListening();
    }
  }

  Future<void> startRecording() async {
    try {
      await _recordService.start();
      state = state.copyWith(isRecording: true, orbState: OrbState.listening);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _recordService.stop();
      state = state.copyWith(isRecording: false, orbState: OrbState.processing);

      if (path != null) {
        final bytes = await _recordService.getAudioBytes(path);
        final base64Audio = base64Encode(bytes);
        await _sendMessage(audioBase64: base64Audio, messageType: 'voice');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), orbState: OrbState.idle);
    }
  }

  Future<void> startContinuousListening() async {
    if (state.isContinuousListening) return;

    try {
      await _wakeWordService.startContinuousListening();
      state = state.copyWith(isContinuousListening: true);

      // Start a timer to periodically check for audio chunks
      _continuousListeningTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _processContinuousAudio(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopContinuousListening() async {
    if (!state.isContinuousListening) return;

    try {
      _continuousListeningTimer?.cancel();
      await _wakeWordService.stopContinuousListening();
      state = state.copyWith(isContinuousListening: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _processContinuousAudio() async {
    try {
      final audioPath = await _wakeWordService.pauseAndGetAudio();
      if (audioPath == null) return;

      // Check for wake word if enabled
      if (_settings.wakeWordEnabled) {
        final wakeWordDetected = await _wakeWordService.detectWakeWord(
          audioPath,
          _settings.wakeWord,
          _settings.wakeWordSensitivity,
        );

        if (!wakeWordDetected) {
          // Continue listening without processing
          return;
        }
      }

      // Process the audio
      state = state.copyWith(orbState: OrbState.listening);
      final bytes = await _recordService.getAudioBytes(audioPath);
      final base64Audio = base64Encode(bytes);
      await _sendMessage(audioBase64: base64Audio, messageType: 'voice');
    } catch (e) {
      // Silently continue listening on error
    }
  }

  Future<void> sendTextMessage(String text) async {
    state = state.copyWith(orbState: OrbState.processing);
    await _sendMessage(message: text, messageType: 'text');
  }

  Future<void> _sendMessage({
    String? message,
    String? audioBase64,
    required String messageType,
  }) async {
    if (message != null && message.isNotEmpty) {
      final userMsg = ChatMessage(
        id: _uuid.v4(),
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, userMsg]);
    }

    try {
      final response = await _apiClient.postToWebhook(
        message: message ?? '',
        audioBase64: audioBase64,
        messageType: messageType,
      );

      final jarvisMsg = ChatMessage(
        id: response['request_id'] ?? _uuid.v4(),
        text: response['text'] ?? '',
        isUser: false,
        toolUsed: response['tool_used'],
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, jarvisMsg],
        orbState: OrbState.speaking,
      );

      if (response['audio_base64'] != null) {
        await _audioPlayerService.playBase64(response['audio_base64']);
      }

      state = state.copyWith(orbState: OrbState.idle);
    } catch (e) {
      state = state.copyWith(error: e.toString(), orbState: OrbState.idle);
    }
  }

  @override
  void dispose() {
    _continuousListeningTimer?.cancel();
    super.dispose();
  }
}
