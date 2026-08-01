import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_app/core/network/dto/n8n_request.dart';
import 'package:jarvis_app/core/network/dto/n8n_response.dart';

void main() {
  test('N8nRequest serializes to the documented snake_case webhook contract', () {
    const request = N8nRequest(
      userId: 'usr_1',
      chatId: 'chat_1',
      messageType: 'text',
      text: 'hello',
      timestamp: '2026-01-01T00:00:00Z',
    );

    final json = request.toJson();
    expect(json.keys, containsAll(['user_id', 'chat_id', 'message_type', 'text', 'timestamp']));
    expect(json['user_id'], 'usr_1');
    expect(json['chat_id'], 'chat_1');
    expect(json['message_type'], 'text');
  });

  test('N8nResponse deserializes the documented snake_case webhook response', () {
    final response = N8nResponse.fromJson(const {
      'request_id': 'req_1',
      'text': 'hi there',
      'tool_used': 'search',
      'audio_base64': null,
      'latency': 120,
      'metadata': {'model': 'jarvis-1'},
    });

    expect(response.requestId, 'req_1');
    expect(response.toolUsed, 'search');
    expect(response.latency, 120);
    expect(response.metadata['model'], 'jarvis-1');
  });
}
