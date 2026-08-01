import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum MessageStatus { sending, sent, failed, queued }

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String chatId,
    required String text,
    required bool isUser,
    required DateTime timestamp,
    String? toolUsed,
    @Default(MessageStatus.sent) MessageStatus status,
    @Default(false) bool isVoice,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

@freezed
class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool pinned,
    String? folder,
    @Default('') String lastMessagePreview,
  }) = _ChatSession;

  factory ChatSession.fromJson(Map<String, dynamic> json) => _$ChatSessionFromJson(json);
}
