import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dto/n8n_request.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_exception.dart';
import '../../analytics/data/analytics_repository.dart';
import '../../analytics/domain/usage_event.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(hiveServiceProvider).chatBox);
});

final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, List<ChatSession>>((ref) {
  return ChatSessionsNotifier(ref.watch(chatRepositoryProvider));
});

class ChatSessionsNotifier extends StateNotifier<List<ChatSession>> {
  ChatSessionsNotifier(this._repo) : super(_repo.getSessions());

  final ChatRepository _repo;

  void refresh() => state = _repo.getSessions();

  Future<ChatSession> createSession() async {
    final session = await _repo.createSession();
    refresh();
    return session;
  }

  Future<void> delete(String chatId) async {
    await _repo.deleteSession(chatId);
    refresh();
  }

  Future<void> togglePinned(String chatId) async {
    await _repo.togglePinned(chatId);
    refresh();
  }

  Future<void> rename(String chatId, String title) async {
    await _repo.renameSession(chatId, title);
    refresh();
  }
}

class ChatState {
  const ChatState({
    required this.messages,
    this.isSending = false,
    this.streamingText,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isSending;

  /// Text currently being revealed with the typewriter effect for the
  /// in-flight assistant reply, or null when nothing is streaming.
  final String? streamingText;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? streamingText,
    bool clearStreaming = false,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      streamingText: clearStreaming ? null : (streamingText ?? this.streamingText),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final chatControllerProvider =
    StateNotifierProvider.family<ChatController, ChatState, String>((ref, chatId) {
  return ChatController(
    chatId: chatId,
    repo: ref.watch(chatRepositoryProvider),
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
    analyticsRepo: ref.watch(analyticsRepositoryProvider),
  );
});

class ChatController extends StateNotifier<ChatState> {
  ChatController({
    required this.chatId,
    required ChatRepository repo,
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
    required AnalyticsRepository analyticsRepo,
  })  : _repo = repo,
        _apiClient = apiClient,
        _secureStorage = secureStorage,
        _analyticsRepo = analyticsRepo,
        super(ChatState(messages: repo.getMessages(chatId)));

  final String chatId;
  final ChatRepository _repo;
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final AnalyticsRepository _analyticsRepo;
  static const _uuid = Uuid();

  Future<void> sendText(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      isVoice: isVoice,
    );
    await _repo.saveMessage(userMessage);
    state = state.copyWith(messages: _repo.getMessages(chatId), isSending: true, clearError: true);

    final userId = await _secureStorage.userId ?? 'usr_jarvis_mobile';
    final history = state.messages
        .take(20)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
        .toList();

    final request = N8nRequest(
      userId: userId,
      chatId: chatId,
      messageType: isVoice ? 'voice' : 'text',
      text: text,
      device: const {'platform': 'android', 'app': 'jarvis'},
      timestamp: DateTime.now().toUtc().toIso8601String(),
      conversationHistory: history,
    );

    final result = await _apiClient.postToWebhook(request);
    await result.when(
      ok: (response) => _revealReply(response.text, toolUsed: response.toolUsed),
      err: (error) async {
        state = state.copyWith(isSending: false, error: describeException(error));
      },
    );

    await _analyticsRepo.logEvent(UsageEventType.chatMessage);
  }

  /// Client-side typewriter reveal over the real response text — a
  /// genuine progressive-render effect, not a network stream, used when
  /// the configured webhook returns a single JSON payload rather than a
  /// chunked stream (see [ApiClient.streamMessage] for the true-streaming
  /// path).
  Future<void> _revealReply(String fullText, {String? toolUsed}) async {
    final buffer = StringBuffer();
    const chunkSize = 3;
    for (var i = 0; i < fullText.length; i += chunkSize) {
      buffer.write(fullText.substring(i, (i + chunkSize).clamp(0, fullText.length)));
      state = state.copyWith(streamingText: buffer.toString());
      await Future.delayed(const Duration(milliseconds: 12));
    }

    final assistantMessage = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      text: fullText,
      isUser: false,
      toolUsed: toolUsed,
      timestamp: DateTime.now(),
    );
    await _repo.saveMessage(assistantMessage);
    state = state.copyWith(
      messages: _repo.getMessages(chatId),
      isSending: false,
      clearStreaming: true,
    );
  }

  Future<void> regenerateLast() async {
    final lastUser = state.messages.lastWhereOrNull((m) => m.isUser);
    if (lastUser == null) return;
    await sendText(lastUser.text, isVoice: lastUser.isVoice);
  }
}

extension _LastWhereOrNull<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
