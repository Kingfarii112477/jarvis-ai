import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_service.dart';
import '../domain/automation_workflow.dart';

/// Manages n8n automation workflows the user has registered — each is
/// just its own webhook URL, run manually or (in a full deployment) by an
/// n8n-side trigger. Execution history is real: every [run] call records
/// actual latency and HTTP outcome, not synthetic data.
class AutomationRepository {
  AutomationRepository(this._box) : _dio = Dio();

  final Box _box;
  final Dio _dio;
  static const _uuid = Uuid();
  static const _workflowsKey = 'workflows';
  static const _executionsKey = 'executions';

  List<AutomationWorkflow> getWorkflows() {
    final raw = _box.get(_workflowsKey) as List?;
    if (raw == null) return [];
    return raw.map((e) => AutomationWorkflow.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  List<WorkflowExecution> getExecutions({String? workflowId}) {
    final raw = _box.get(_executionsKey) as List?;
    if (raw == null) return [];
    final all = raw.map((e) => WorkflowExecution.fromJson(Map<String, dynamic>.from(e as Map))).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (workflowId == null) return all;
    return all.where((e) => e.workflowId == workflowId).toList();
  }

  Future<AutomationWorkflow> addWorkflow({required String name, required String webhookUrl, String description = ''}) async {
    final workflow = AutomationWorkflow(id: _uuid.v4(), name: name, description: description, webhookUrl: webhookUrl);
    final workflows = getWorkflows()..add(workflow);
    await _box.put(_workflowsKey, workflows.map((w) => w.toJson()).toList());
    return workflow;
  }

  Future<void> deleteWorkflow(String id) async {
    final workflows = getWorkflows().where((w) => w.id != id).toList();
    await _box.put(_workflowsKey, workflows.map((w) => w.toJson()).toList());
  }

  Future<void> setActive(String id, bool active) async {
    final workflows = getWorkflows().map((w) => w.id == id ? w.copyWith(active: active) : w).toList();
    await _box.put(_workflowsKey, workflows.map((w) => w.toJson()).toList());
  }

  Future<WorkflowExecution> run(AutomationWorkflow workflow) async {
    final stopwatch = Stopwatch()..start();
    ExecutionStatus status;
    String message;
    try {
      final response = await _dio.post(workflow.webhookUrl, data: {'triggered_by': 'manual', 'workflow': workflow.name});
      status = (response.statusCode ?? 500) < 400 ? ExecutionStatus.success : ExecutionStatus.failure;
      message = 'HTTP ${response.statusCode}';
    } on DioException catch (e) {
      status = ExecutionStatus.failure;
      message = e.message ?? 'Request failed';
    } finally {
      stopwatch.stop();
    }

    final execution = WorkflowExecution(
      id: _uuid.v4(),
      workflowId: workflow.id,
      startedAt: DateTime.now(),
      durationMs: stopwatch.elapsedMilliseconds,
      status: status,
      message: message,
    );
    await _saveExecution(execution);

    final workflows = getWorkflows()
        .map((w) => w.id == workflow.id ? w.copyWith(lastRunAt: execution.startedAt, lastStatus: status) : w)
        .toList();
    await _box.put(_workflowsKey, workflows.map((w) => w.toJson()).toList());

    return execution;
  }

  /// Lightweight reachability probe, used for the "webhook health" badge
  /// on each workflow card.
  Future<bool> checkHealth(String url) async {
    try {
      final response = await _dio.head(url, options: Options(sendTimeout: const Duration(seconds: 5)));
      return (response.statusCode ?? 500) < 500;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveExecution(WorkflowExecution execution) async {
    final executions = getExecutions()..insert(0, execution);
    final trimmed = executions.length > 500 ? executions.sublist(0, 500) : executions;
    await _box.put(_executionsKey, trimmed.map((e) => e.toJson()).toList());
  }
}

final automationRepositoryProvider = Provider<AutomationRepository>((ref) {
  return AutomationRepository(ref.watch(hiveServiceProvider).automationBox);
});
