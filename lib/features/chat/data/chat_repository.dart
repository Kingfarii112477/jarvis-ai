import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../domain/chat_message.dart';

/// Local persistence for chat sessions and their messages. Sessions are
/// stored as a single indexed list under `sessions`; each session's
/// messages live under `messages_<chatId>` so opening one conversation
/// never has to deserialize every other one.
class ChatRepository {
  ChatRepository(this._box);

  final Box _box;
  static const _uuid = Uuid();

  List<ChatSession> getSessions() {
    final raw = _box.get('sessions') as List?;
    if (raw == null) return [];
    return raw
        .map((e) => ChatSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<ChatSession> createSession({String title = 'New chat'}) async {
    final now = DateTime.now();
    final session = ChatSession(id: _uuid.v4(), title: title, createdAt: now, updatedAt: now);
    final sessions = getSessions()..insert(0, session);
    await _persistSessions(sessions);
    return session;
  }

  Future<void> deleteSession(String chatId) async {
    final sessions = getSessions().where((s) => s.id != chatId).toList();
    await _persistSessions(sessions);
    await _box.delete('messages_$chatId');
  }

  Future<void> togglePinned(String chatId) async {
    final sessions = getSessions()
        .map((s) => s.id == chatId ? s.copyWith(pinned: !s.pinned) : s)
        .toList();
    await _persistSessions(sessions);
  }

  Future<void> renameSession(String chatId, String title) async {
    final sessions = getSessions().map((s) => s.id == chatId ? s.copyWith(title: title) : s).toList();
    await _persistSessions(sessions);
  }

  List<ChatMessage> getMessages(String chatId) {
    final raw = _box.get('messages_$chatId') as List?;
    if (raw == null) return [];
    return raw
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> saveMessage(ChatMessage message) async {
    final messages = getMessages(message.chatId);
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
    await _box.put('messages_${message.chatId}', messages.map((m) => m.toJson()).toList());
    await _touchSession(message.chatId, preview: message.text);
  }

  Future<void> _touchSession(String chatId, {required String preview}) async {
    final sessions = getSessions();
    final index = sessions.indexWhere((s) => s.id == chatId);
    if (index == -1) return;
    sessions[index] = sessions[index].copyWith(
      updatedAt: DateTime.now(),
      lastMessagePreview: preview.length > 80 ? '${preview.substring(0, 80)}…' : preview,
    );
    await _persistSessions(sessions);
  }

  /// Case-insensitive full text search across every session's messages.
  List<ChatMessage> searchAllMessages(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    final results = <ChatMessage>[];
    for (final session in getSessions()) {
      results.addAll(getMessages(session.id).where((m) => m.text.toLowerCase().contains(lower)));
    }
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  Future<void> _persistSessions(List<ChatSession> sessions) async {
    await _box.put('sessions', sessions.map((s) => s.toJson()).toList());
  }

  int get totalMessageCount {
    var count = 0;
    for (final session in getSessions()) {
      count += getMessages(session.id).length;
    }
    return count;
  }
}
