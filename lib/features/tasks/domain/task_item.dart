import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_item.freezed.dart';
part 'task_item.g.dart';

enum TaskPriority { low, medium, high }

@freezed
class TaskItem with _$TaskItem {
  const factory TaskItem({
    required String id,
    required String title,
    @Default('') String notes,
    DateTime? dueDate,
    @Default(TaskPriority.medium) TaskPriority priority,
    @Default(false) bool completed,
    required DateTime createdAt,
  }) = _TaskItem;

  factory TaskItem.fromJson(Map<String, dynamic> json) => _$TaskItemFromJson(json);
}
