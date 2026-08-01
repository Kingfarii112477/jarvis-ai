import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/data/analytics_repository.dart';
import '../../analytics/domain/usage_event.dart';
import '../data/knowledge_repository.dart';
import '../domain/knowledge_document.dart';

final knowledgeDocumentsProvider = StateNotifierProvider<KnowledgeNotifier, List<KnowledgeDocument>>((ref) {
  return KnowledgeNotifier(ref.watch(knowledgeRepositoryProvider), ref.watch(analyticsRepositoryProvider));
});

class KnowledgeNotifier extends StateNotifier<List<KnowledgeDocument>> {
  KnowledgeNotifier(this._repo, this._analytics) : super(_repo.getAll());

  final KnowledgeRepository _repo;
  final AnalyticsRepository _analytics;

  Future<void> import() async {
    final doc = await _repo.pickAndImport();
    if (doc != null) {
      state = _repo.getAll();
      await _analytics.logEvent(UsageEventType.knowledgeUpload);
    }
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }

  List<KnowledgeDocument> search(String query) => _repo.search(query);
}
