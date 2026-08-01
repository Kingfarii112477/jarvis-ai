import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jarvis_app/features/tasks/data/task_repository.dart';
import 'package:jarvis_app/features/tasks/domain/task_item.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late TaskRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jarvis_tasks_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('tasks_test');
    repo = TaskRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('starts empty', () {
    expect(repo.getAll(), isEmpty);
  });

  test('upsert adds a new task and round-trips through JSON', () async {
    final task = TaskItem(
      id: 't1',
      title: 'Ship JARVIS',
      priority: TaskPriority.high,
      createdAt: DateTime(2026, 1, 1),
    );
    await repo.upsert(task);

    final all = repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.title, 'Ship JARVIS');
    expect(all.single.priority, TaskPriority.high);
  });

  test('upsert with an existing id updates in place instead of duplicating', () async {
    final task = TaskItem(id: 't1', title: 'Draft', createdAt: DateTime(2026, 1, 1));
    await repo.upsert(task);
    await repo.upsert(task.copyWith(title: 'Final'));

    final all = repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.title, 'Final');
  });

  test('toggleCompleted flips the completed flag', () async {
    final task = TaskItem(id: 't1', title: 'Draft', createdAt: DateTime(2026, 1, 1));
    await repo.upsert(task);

    await repo.toggleCompleted('t1');
    expect(repo.getAll().single.completed, isTrue);

    await repo.toggleCompleted('t1');
    expect(repo.getAll().single.completed, isFalse);
  });

  test('delete removes the task', () async {
    await repo.upsert(TaskItem(id: 't1', title: 'Draft', createdAt: DateTime(2026, 1, 1)));
    await repo.delete('t1');
    expect(repo.getAll(), isEmpty);
  });
}
