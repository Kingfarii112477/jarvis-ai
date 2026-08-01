import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../domain/automation_workflow.dart';
import 'automation_providers.dart';

class AutomationScreen extends ConsumerWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflows = ref.watch(workflowsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Automation')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondaryGlow,
        foregroundColor: Colors.black,
        onPressed: () => _showAddWorkflowSheet(context),
        child: const Icon(Icons.add),
      ),
      body: workflows.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text('No workflows yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Register an n8n webhook to trigger workflows manually', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
              itemCount: workflows.length,
              itemBuilder: (context, index) => _WorkflowCard(workflow: workflows[index]),
            ),
    );
  }

  void _showAddWorkflowSheet(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
              top: AppSpacing.md,
            ),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Register workflow', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Workflow name'), style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(controller: urlController, decoration: const InputDecoration(hintText: 'n8n webhook URL'), style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GlowButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty || urlController.text.trim().isEmpty) return;
                        await ref.read(workflowsProvider.notifier).add(nameController.text.trim(), urlController.text.trim());
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkflowCard extends ConsumerStatefulWidget {
  const _WorkflowCard({required this.workflow});
  final AutomationWorkflow workflow;

  @override
  ConsumerState<_WorkflowCard> createState() => _WorkflowCardState();
}

class _WorkflowCardState extends ConsumerState<_WorkflowCard> {
  bool _running = false;

  Color _statusColor(ExecutionStatus? status) => switch (status) {
        ExecutionStatus.success => AppColors.success,
        ExecutionStatus.failure => AppColors.error,
        ExecutionStatus.running => AppColors.warning,
        null => AppColors.textTertiary,
      };

  @override
  Widget build(BuildContext context) {
    final workflow = widget.workflow;
    final executions = ref.watch(workflowsProvider.notifier).executionsFor(workflow.id).take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(workflow.lastStatus), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(workflow.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
                Switch(
                  value: workflow.active,
                  onChanged: (v) => ref.read(workflowsProvider.notifier).setActive(workflow.id, v),
                ),
              ],
            ),
            if (workflow.lastRunAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Last run ${DateFormat.MMMd().add_jm().format(workflow.lastRunAt!)}', style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: AppSpacing.sm),
            if (executions.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              ...executions.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(e.status == ExecutionStatus.success ? Icons.check_circle : Icons.error, size: 12, color: _statusColor(e.status)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(e.message, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                        Text('${e.durationMs}ms', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  )),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _running
                        ? null
                        : () async {
                            setState(() => _running = true);
                            await ref.read(workflowsProvider.notifier).run(workflow);
                            if (mounted) setState(() => _running = false);
                          },
                    icon: _running
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(_running ? 'Running…' : 'Run now'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textTertiary, size: 18),
                  onPressed: () => ref.read(workflowsProvider.notifier).delete(workflow.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
