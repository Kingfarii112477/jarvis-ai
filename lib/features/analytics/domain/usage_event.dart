import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_event.freezed.dart';
part 'usage_event.g.dart';

enum UsageEventType {
  chatMessage,
  voiceInteraction,
  automationRun,
  taskCompleted,
  knowledgeUpload,
  memorySaved,
}

@freezed
class UsageEvent with _$UsageEvent {
  const factory UsageEvent({
    required String id,
    required UsageEventType type,
    required DateTime timestamp,
    @Default(0) int estimatedTokens,
  }) = _UsageEvent;

  factory UsageEvent.fromJson(Map<String, dynamic> json) => _$UsageEventFromJson(json);
}
