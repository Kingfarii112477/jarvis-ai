// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'n8n_response.freezed.dart';
part 'n8n_response.g.dart';

/// Exact payload contract every JARVIS n8n webhook workflow must return.
@freezed
class N8nResponse with _$N8nResponse {
  const factory N8nResponse({
    @JsonKey(name: 'request_id') required String requestId,
    @Default('') String text,
    @JsonKey(name: 'audio_base64') String? audioBase64,
    @JsonKey(name: 'tool_used') String? toolUsed,
    @Default(0) int latency,
    @Default({}) Map<String, dynamic> metadata,
  }) = _N8nResponse;

  factory N8nResponse.fromJson(Map<String, dynamic> json) => _$N8nResponseFromJson(json);
}
