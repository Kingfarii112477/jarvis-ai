import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../analytics/data/analytics_repository.dart';
import '../../analytics/domain/usage_event.dart';
import '../data/memory_repository.dart';
import '../domain/memory_item.dart';

final memoriesProvider = StateNotifierProvider<MemoriesNotifier, List<MemoryItem>>((ref) {
  return MemoriesNotifier(ref.watch(memoryRepositoryProvider), ref.watch(analyticsRepositoryProvider));
});

class MemoriesNotifier extends StateNotifier<List<MemoryItem>> {
  MemoriesNotifier(this._repo, this._analytics) : super(_repo.getAll());

  final MemoryRepository _repo;
  final AnalyticsRepository _analytics;
  static const _uuid = Uuid();

  Future<void> add(String content, MemoryCategory category, {List<String> tags = const []}) async {
    await _repo.add(MemoryItem(id: _uuid.v4(), content: content, category: category, tags: tags, createdAt: DateTime.now()));
    state = _repo.getAll();
    await _analytics.logEvent(UsageEventType.memorySaved);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }

  List<MemoryItem> search(String query, {MemoryCategory? category}) => _repo.search(query, category: category);

  Map<MemoryCategory, int> get categoryCounts => _repo.categoryCounts();
}
