import 'package:freezed_annotation/freezed_annotation.dart';

part 'knowledge_document.freezed.dart';
part 'knowledge_document.g.dart';

@freezed
class KnowledgeDocument with _$KnowledgeDocument {
  const factory KnowledgeDocument({
    required String id,
    required String fileName,
    required String filePath,
    required String extension,
    required int sizeBytes,
    required DateTime createdAt,

    /// Extracted plain text, populated for text-like formats (txt/md/csv)
    /// that can be parsed without a dedicated PDF/DOCX library. Binary
    /// formats are indexed by filename only — see the knowledge feature
    /// README note for wiring a real document-extraction backend.
    String? indexedText,
  }) = _KnowledgeDocument;

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) => _$KnowledgeDocumentFromJson(json);
}
