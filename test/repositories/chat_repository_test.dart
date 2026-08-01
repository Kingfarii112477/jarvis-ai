import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jarvis_app/features/chat/data/chat_repository.dart';
import 'package:jarvis_app/features/chat/domain/chat_message.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late ChatRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jarvis_chat_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('chat_test');
    repo = ChatRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('createSession persists and is retrievable', () async {
    final session = await repo.createSession(title: 'Test chat');
    final sessions = repo.getSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.id, session.id);
    expect(sessions.single.title, 'Test chat');
  });

  test('saveMessage stores messages scoped to their chatId and updates the session preview', () async {
    final session = await repo.createSession();
    await repo.saveMessage(ChatMessage(
      id: 'm1',
      chatId: session.id,
      text: 'Hello JARVIS',
      isUser: true,
      timestamp: DateTime(2026, 1, 1, 9),
    ));

    final messages = repo.getMessages(session.id);
    expect(messages, hasLength(1));
    expect(messages.single.text, 'Hello JARVIS');

    final updatedSession = repo.getSessions().single;
    expect(updatedSession.lastMessagePreview, 'Hello JARVIS');
  });

  test('messages from other sessions are not mixed in', () async {
    final sessionA = await repo.createSession(title: 'A');
    final sessionB = await repo.createSession(title: 'B');
    await repo.saveMessage(ChatMessage(id: 'a1', chatId: sessionA.id, text: 'in A', isUser: true, timestamp: DateTime.now()));
    await repo.saveMessage(ChatMessage(id: 'b1', chatId: sessionB.id, text: 'in B', isUser: true, timestamp: DateTime.now()));

    expect(repo.getMessages(sessionA.id).map((m) => m.text), ['in A']);
    expect(repo.getMessages(sessionB.id).map((m) => m.text), ['in B']);
  });

  test('deleteSession removes the session and its messages', () async {
    final session = await repo.createSession();
    await repo.saveMessage(ChatMessage(id: 'm1', chatId: session.id, text: 'hi', isUser: true, timestamp: DateTime.now()));

    await repo.deleteSession(session.id);

    expect(repo.getSessions(), isEmpty);
    expect(repo.getMessages(session.id), isEmpty);
  });

  test('searchAllMessages is case-insensitive across sessions', () async {
    final session = await repo.createSession();
    await repo.saveMessage(ChatMessage(id: 'm1', chatId: session.id, text: 'Tell me about Flutter', isUser: true, timestamp: DateTime.now()));

    expect(repo.searchAllMessages('flutter'), hasLength(1));
    expect(repo.searchAllMessages('nonexistent'), isEmpty);
  });
}
