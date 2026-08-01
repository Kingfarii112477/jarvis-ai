// ignore_for_file: invalid_annotation_target
// `@JsonKey` on a freezed constructor parameter (rather than a field) is
// the documented pattern for per-field JSON renaming; the analyzer just
// can't see that freezed rewrites parameters into fields.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'n8n_request.freezed.dart';
part 'n8n_request.g.dart';

/// Exact payload contract every JARVIS n8n webhook workflow must accept.
@freezed
class N8nRequest with _$N8nRequest {
  const factory N8nRequest({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'chat_id') required String chatId,
    @JsonKey(name: 'message_type') required String messageType,
    required String text,
    @JsonKey(name: 'audio_base64') String? audioBase64,
    @Default('en') String language,
    @JsonKey(name: 'conversation_history') @Default([]) List<Map<String, dynamic>> conversationHistory,
    @Default({}) Map<String, dynamic> device,
    required String timestamp,
  }) = _N8nRequest;

  factory N8nRequest.fromJson(Map<String, dynamic> json) => _$N8nRequestFromJson(json);
}
