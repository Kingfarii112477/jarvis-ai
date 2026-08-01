import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/data/analytics_repository.dart';
import '../../analytics/domain/usage_event.dart';
import '../data/automation_repository.dart';
import '../domain/automation_workflow.dart';

final workflowsProvider = StateNotifierProvider<WorkflowsNotifier, List<AutomationWorkflow>>((ref) {
  return WorkflowsNotifier(ref.watch(automationRepositoryProvider), ref.watch(analyticsRepositoryProvider));
});

class WorkflowsNotifier extends StateNotifier<List<AutomationWorkflow>> {
  WorkflowsNotifier(this._repo, this._analytics) : super(_repo.getWorkflows());

  final AutomationRepository _repo;
  final AnalyticsRepository _analytics;

  Future<void> add(String name, String webhookUrl, {String description = ''}) async {
    await _repo.addWorkflow(name: name, webhookUrl: webhookUrl, description: description);
    state = _repo.getWorkflows();
  }

  Future<void> delete(String id) async {
    await _repo.deleteWorkflow(id);
    state = _repo.getWorkflows();
  }

  Future<void> setActive(String id, bool active) async {
    await _repo.setActive(id, active);
    state = _repo.getWorkflows();
  }

  Future<WorkflowExecution> run(AutomationWorkflow workflow) async {
    final execution = await _repo.run(workflow);
    state = _repo.getWorkflows();
    await _analytics.logEvent(UsageEventType.automationRun);
    return execution;
  }

  List<WorkflowExecution> executionsFor(String workflowId) => _repo.getExecutions(workflowId: workflowId);
}
