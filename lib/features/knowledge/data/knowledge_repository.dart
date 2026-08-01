import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_service.dart';
import '../domain/knowledge_document.dart';

const _textExtensions = {'.txt', '.md', '.csv', '.json', '.log'};

class KnowledgeRepository {
  KnowledgeRepository(this._box);

  final Box _box;
  static const _uuid = Uuid();
  static const _key = 'documents';

  List<KnowledgeDocument> getAll() {
    final raw = _box.get(_key) as List?;
    if (raw == null) return [];
    return raw
        .map((e) => KnowledgeDocument.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Opens the system file picker, copies the chosen file into app
  /// storage (so it survives the source being deleted), and indexes it.
  Future<KnowledgeDocument?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'md', 'txt', 'csv', 'png', 'jpg', 'jpeg', 'mp3', 'wav', 'mp4'],
    );
    final picked = result?.files.single;
    if (picked?.path == null) return null;

    final sourceFile = File(picked!.path!);
    final docsDir = await getApplicationDocumentsDirectory();
    final knowledgeDir = Directory(p.join(docsDir.path, 'knowledge'));
    if (!knowledgeDir.existsSync()) knowledgeDir.createSync(recursive: true);

    final id = _uuid.v4();
    final extension = p.extension(picked.name).toLowerCase();
    final storedPath = p.join(knowledgeDir.path, '$id$extension');
    await sourceFile.copy(storedPath);

    String? indexedText;
    if (_textExtensions.contains(extension)) {
      try {
        indexedText = await File(storedPath).readAsString();
      } catch (_) {
        indexedText = null;
      }
    }

    final document = KnowledgeDocument(
      id: id,
      fileName: picked.name,
      filePath: storedPath,
      extension: extension,
      sizeBytes: picked.size,
      createdAt: DateTime.now(),
      indexedText: indexedText,
    );

    final documents = getAll()..insert(0, document);
    await _box.put(_key, documents.map((d) => d.toJson()).toList());
    return document;
  }

  Future<void> delete(String id) async {
    final doc = getAll().firstWhere((d) => d.id == id);
    final file = File(doc.filePath);
    if (file.existsSync()) await file.delete();
    final documents = getAll().where((d) => d.id != id).toList();
    await _box.put(_key, documents.map((d) => d.toJson()).toList());
  }

  List<KnowledgeDocument> search(String query) {
    if (query.trim().isEmpty) return getAll();
    final lower = query.toLowerCase();
    return getAll()
        .where((d) => d.fileName.toLowerCase().contains(lower) || (d.indexedText?.toLowerCase().contains(lower) ?? false))
        .toList();
  }
}

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>((ref) {
  return KnowledgeRepository(ref.watch(hiveServiceProvider).knowledgeBox);
});
