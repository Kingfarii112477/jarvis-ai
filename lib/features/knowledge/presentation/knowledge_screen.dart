import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/knowledge_document.dart';
import 'knowledge_providers.dart';

IconData _iconFor(String extension) {
  switch (extension) {
    case '.pdf':
      return Icons.picture_as_pdf_outlined;
    case '.doc':
    case '.docx':
      return Icons.description_outlined;
    case '.xls':
    case '.xlsx':
      return Icons.table_chart_outlined;
    case '.png':
    case '.jpg':
    case '.jpeg':
      return Icons.image_outlined;
    case '.mp3':
    case '.wav':
      return Icons.audiotrack_outlined;
    case '.mp4':
      return Icons.videocam_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  String _query = '';
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(knowledgeDocumentsProvider);
    final results = ref.read(knowledgeDocumentsProvider.notifier).search(_query);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Knowledge Base')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importing
            ? null
            : () async {
                setState(() => _importing = true);
                await ref.read(knowledgeDocumentsProvider.notifier).import();
                if (mounted) setState(() => _importing = false);
              },
        backgroundColor: AppColors.primaryGlow,
        foregroundColor: Colors.black,
        icon: _importing
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload_file_rounded),
        label: Text(_importing ? 'Importing…' : 'Upload'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search documents…'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: AppSpacing.md),
                          Text('No documents indexed', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('PDF, Word, Excel, Markdown, images, audio, video', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: results.length,
                      itemBuilder: (context, index) => _DocumentCard(document: results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  const _DocumentCard({required this.document});
  final KnowledgeDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primaryGlow.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(_iconFor(document.extension), color: AppColors.primaryGlow, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatSize(document.sizeBytes)} · indexed ${document.indexedText != null ? "text" : "filename"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textTertiary),
              onPressed: () => ref.read(knowledgeDocumentsProvider.notifier).delete(document.id),
            ),
          ],
        ),
      ),
    );
  }
}
