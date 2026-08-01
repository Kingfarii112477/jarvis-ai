import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/task_item.dart';
import 'tasks_providers.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final pending = tasks.where((t) => !t.completed).toList();
    final completed = tasks.where((t) => t.completed).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGlow,
        foregroundColor: Colors.black,
        onPressed: () => _showTaskEditor(context, ref),
        child: const Icon(Icons.add),
      ),
      body: tasks.isEmpty
          ? const _EmptyTasksState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
              children: [
                SectionHeader(title: 'Pending (${pending.length})', icon: Icons.radio_button_unchecked),
                const SizedBox(height: AppSpacing.sm),
                ...pending.map((t) => _TaskCard(task: t, onEdit: () => _showTaskEditor(context, ref, task: t))),
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(title: 'Completed (${completed.length})', icon: Icons.check_circle_outline),
                  const SizedBox(height: AppSpacing.sm),
                  ...completed.map((t) => _TaskCard(task: t, onEdit: () => _showTaskEditor(context, ref, task: t))),
                ],
              ],
            ),
    );
  }

  void _showTaskEditor(BuildContext context, WidgetRef ref, {TaskItem? task}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TaskEditorSheet(task: task),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.onEdit});
  final TaskItem task;
  final VoidCallback onEdit;

  Color get _priorityColor => switch (task.priority) {
        TaskPriority.high => AppColors.error,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.low => AppColors.success,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        onDismissed: (_) => ref.read(tasksProvider.notifier).delete(task.id),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: InkWell(
            onTap: onEdit,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(tasksProvider.notifier).toggleCompleted(task.id),
                  child: Icon(
                    task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: task.completed ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            DateFormat.MMMd().add_jm().format(task.dueDate!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: _priorityColor, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.checklist_rounded, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No tasks yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Tap + to create your first task', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TaskEditorSheet extends ConsumerStatefulWidget {
  const _TaskEditorSheet({this.task});
  final TaskItem? task;

  @override
  ConsumerState<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<_TaskEditorSheet> {
  late final _titleController = TextEditingController(text: widget.task?.title ?? '');
  late final _notesController = TextEditingController(text: widget.task?.notes ?? '');
  DateTime? _dueDate;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              Text(widget.task == null ? 'New task' : 'Edit task', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Title'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: _notesController, decoration: const InputDecoration(hintText: 'Notes'), style: const TextStyle(color: Colors.white), maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: TaskPriority.values.map((p) {
                        return ChoiceChip(
                          label: Text(p.name),
                          selected: _priority == p,
                          onSelected: (_) => setState(() => _priority = p),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(_dueDate == null ? 'Set due date' : DateFormat.yMMMd().format(_dueDate!)),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: GlowButton(
                  onPressed: _titleController.text.trim().isEmpty && widget.task == null
                      ? null
                      : () async {
                          final notifier = ref.read(tasksProvider.notifier);
                          if (widget.task == null) {
                            await notifier.add(
                              title: _titleController.text.trim(),
                              notes: _notesController.text.trim(),
                              dueDate: _dueDate,
                              priority: _priority,
                            );
                          } else {
                            await notifier.update(widget.task!.copyWith(
                              title: _titleController.text.trim(),
                              notes: _notesController.text.trim(),
                              dueDate: _dueDate,
                              priority: _priority,
                            ));
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
