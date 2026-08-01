import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> postToWebhook({
    required String message,
    String? audioBase64,
    required String messageType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('n8n_webhook_url') ?? '';
    final userId = prefs.getString('user_id') ?? 'usr_jarvis_mobile';

    if (url.isEmpty) {
      throw Exception('Webhook URL not configured');
    }

    try {
      final response = await _dio.post(
        url,
        data: {
          "user_id": userId,
          "chat_id": "session_default",
          "message_type": messageType,
          "text": message,
          "audio_base64": audioBase64,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to connect to backend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }
}
