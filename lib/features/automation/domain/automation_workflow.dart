import 'package:freezed_annotation/freezed_annotation.dart';

part 'automation_workflow.freezed.dart';
part 'automation_workflow.g.dart';

enum ExecutionStatus { success, failure, running }

@freezed
class AutomationWorkflow with _$AutomationWorkflow {
  const factory AutomationWorkflow({
    required String id,
    required String name,
    @Default('') String description,
    required String webhookUrl,
    @Default(true) bool active,
    DateTime? lastRunAt,
    ExecutionStatus? lastStatus,
  }) = _AutomationWorkflow;

  factory AutomationWorkflow.fromJson(Map<String, dynamic> json) => _$AutomationWorkflowFromJson(json);
}

@freezed
class WorkflowExecution with _$WorkflowExecution {
  const factory WorkflowExecution({
    required String id,
    required String workflowId,
    required DateTime startedAt,
    required int durationMs,
    required ExecutionStatus status,
    @Default('') String message,
  }) = _WorkflowExecution;

  factory WorkflowExecution.fromJson(Map<String, dynamic> json) => _$WorkflowExecutionFromJson(json);
}
