import 'package:freezed_annotation/freezed_annotation.dart';

part 'memory_item.freezed.dart';
part 'memory_item.g.dart';

enum MemoryCategory { preference, project, goal, context, general }

extension MemoryCategoryLabel on MemoryCategory {
  String get label => switch (this) {
        MemoryCategory.preference => 'Preference',
        MemoryCategory.project => 'Project',
        MemoryCategory.goal => 'Goal',
        MemoryCategory.context => 'Context',
        MemoryCategory.general => 'General',
      };
}

@freezed
class MemoryItem with _$MemoryItem {
  const factory MemoryItem({
    required String id,
    required String content,
    @Default(MemoryCategory.general) MemoryCategory category,
    @Default([]) List<String> tags,
    required DateTime createdAt,
  }) = _MemoryItem;

  factory MemoryItem.fromJson(Map<String, dynamic> json) => _$MemoryItemFromJson(json);
}
