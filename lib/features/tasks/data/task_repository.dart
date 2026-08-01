import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_service.dart';
import '../domain/task_item.dart';

class TaskRepository {
  TaskRepository(this._box);

  final Box _box;
  static const _key = 'tasks';

  List<TaskItem> getAll() {
    final raw = _box.get(_key) as List?;
    if (raw == null) return [];
    return raw.map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> upsert(TaskItem task) async {
    final tasks = getAll();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    await _persist(tasks);
  }

  Future<void> delete(String id) async {
    await _persist(getAll().where((t) => t.id != id).toList());
  }

  Future<void> toggleCompleted(String id) async {
    final tasks = getAll().map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t).toList();
    await _persist(tasks);
  }

  Future<void> _persist(List<TaskItem> tasks) => _box.put(_key, tasks.map((t) => t.toJson()).toList());
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(hiveServiceProvider).tasksBox);
});
