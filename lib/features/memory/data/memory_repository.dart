import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_service.dart';
import '../domain/memory_item.dart';

/// Persistent memory store. `embedding` is intentionally not modeled here:
/// real semantic search needs a vector index (e.g. pgvector/Pinecone via
/// the n8n backend) that this offline-first client doesn't own — keyword
/// search below is the honest on-device substitute until that lands.
class MemoryRepository {
  MemoryRepository(this._box);

  final Box _box;
  static const _key = 'memories';

  List<MemoryItem> getAll() {
    final raw = _box.get(_key) as List?;
    if (raw == null) return [];
    return raw
        .map((e) => MemoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> add(MemoryItem item) async {
    final items = getAll()..insert(0, item);
    await _persist(items);
  }

  Future<void> delete(String id) async {
    await _persist(getAll().where((m) => m.id != id).toList());
  }

  List<MemoryItem> search(String query, {MemoryCategory? category}) {
    final lower = query.toLowerCase();
    return getAll().where((m) {
      final matchesCategory = category == null || m.category == category;
      final matchesQuery = query.isEmpty ||
          m.content.toLowerCase().contains(lower) ||
          m.tags.any((t) => t.toLowerCase().contains(lower));
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Map<MemoryCategory, int> categoryCounts() {
    final counts = {for (final c in MemoryCategory.values) c: 0};
    for (final item in getAll()) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _persist(List<MemoryItem> items) => _box.put(_key, items.map((m) => m.toJson()).toList());
}

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository(ref.watch(hiveServiceProvider).memoryBox);
});
