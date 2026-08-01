import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/notification_service.dart';
import '../../analytics/data/analytics_repository.dart';
import '../../analytics/domain/usage_event.dart';
import '../data/task_repository.dart';
import '../domain/task_item.dart';

final tasksProvider = StateNotifierProvider<TasksNotifier, List<TaskItem>>((ref) {
  return TasksNotifier(
    ref.watch(taskRepositoryProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(analyticsRepositoryProvider),
  );
});

class TasksNotifier extends StateNotifier<List<TaskItem>> {
  TasksNotifier(this._repo, this._notifications, this._analytics) : super(_sorted(_repo.getAll()));

  final TaskRepository _repo;
  final NotificationService _notifications;
  final AnalyticsRepository _analytics;
  static const _uuid = Uuid();

  static List<TaskItem> _sorted(List<TaskItem> tasks) {
    return tasks
      ..sort((a, b) {
        if (a.completed != b.completed) return a.completed ? 1 : -1;
        final aDate = a.dueDate ?? DateTime(9999);
        final bDate = b.dueDate ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
  }

  Future<void> add({
    required String title,
    String notes = '',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final task = TaskItem(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      dueDate: dueDate,
      priority: priority,
      createdAt: DateTime.now(),
    );
    await _repo.upsert(task);
    state = _sorted(_repo.getAll());
    if (dueDate != null) {
      await _notifications.scheduleTaskReminder(
        id: task.id.hashCode,
        title: 'Task due: ${task.title}',
        body: task.notes.isEmpty ? 'This task is due now.' : task.notes,
        scheduledFor: dueDate,
      );
    }
  }

  Future<void> update(TaskItem task) async {
    await _repo.upsert(task);
    state = _sorted(_repo.getAll());
  }

  Future<void> toggleCompleted(String id) async {
    await _repo.toggleCompleted(id);
    state = _sorted(_repo.getAll());
    final task = state.firstWhere((t) => t.id == id);
    if (task.completed) {
      await _analytics.logEvent(UsageEventType.taskCompleted);
      await _notifications.cancel(id.hashCode);
    }
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _sorted(_repo.getAll());
    await _notifications.cancel(id.hashCode);
  }
}
