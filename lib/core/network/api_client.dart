import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../config/app_config.dart';
import '../storage/hive_service.dart';
import '../storage/secure_storage_service.dart';
import '../utils/app_exception.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import 'connectivity_service.dart';
import 'dto/n8n_request.dart';
import 'dto/n8n_response.dart';
import 'retry_interceptor.dart';

/// The single gateway between the app and the n8n backend. Every AI
/// interaction — text, voice, tool calls — funnels through
/// [postToWebhook] using the fixed request/response contract defined in
/// [N8nRequest]/[N8nResponse]. When the device is offline the request is
/// persisted to the outbox and replayed by [flushOutbox] once connectivity
/// returns, instead of being silently dropped.
class ApiClient {
  ApiClient({
    required SecureStorageService secureStorage,
    required Connectivity connectivity,
    required Box outboxBox,
  })  : _secureStorage = secureStorage,
        _connectivity = connectivity,
        _outboxBox = outboxBox {
    _dio.options.connectTimeout = AppConfig.networkTimeout;
    _dio.options.receiveTimeout = AppConfig.networkTimeout;
    _dio.options.sendTimeout = AppConfig.networkTimeout;
    _dio.interceptors.add(RetryInterceptor(_dio));
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => AppLogger.debug(obj.toString()),
      ),
    );
  }

  final Dio _dio = Dio();
  final SecureStorageService _secureStorage;
  final Connectivity _connectivity;
  final Box _outboxBox;

  /// Payloads above this size get gzip-compressed with a
  /// `Content-Encoding: gzip` header — mainly matters for base64 audio.
  static const int _compressionThresholdBytes = 32 * 1024;

  Future<String> _requireWebhookUrl() async {
    final url = await _secureStorage.webhookUrl;
    if (url == null || url.isEmpty) {
      throw const ConfigurationException(
        'No n8n webhook URL configured. Add one in Settings → Backend.',
      );
    }
    return url;
  }

  Future<Result<N8nResponse>> postToWebhook(N8nRequest request) async {
    try {
      final url = await _requireWebhookUrl();
      final status = await currentNetworkStatus(_connectivity);

      if (status == NetworkStatus.offline) {
        await _enqueueOffline(request);
        return const Result.err(
          NetworkException('You are offline. Message queued and will send automatically.'),
        );
      }

      final apiKey = await _secureStorage.apiKey;
      final body = jsonEncode(request.toJson());
      final compress = utf8.encode(body).length > _compressionThresholdBytes;

      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: compress ? gzip.encode(utf8.encode(body)) : body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (compress) 'Content-Encoding': 'gzip',
            if (apiKey != null && apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
            'X-Jarvis-Contract-Version': AppConfig.apiContractVersion,
          },
        ),
      );

      final data = response.data;
      if (response.statusCode != 200 || data == null) {
        return Result.err(
          NetworkException('Backend returned ${response.statusCode}', statusCode: response.statusCode),
        );
      }
      return Result.ok(N8nResponse.fromJson(data));
    } on ConfigurationException catch (e) {
      return Result.err(e);
    } on DioException catch (e) {
      return Result.err(_mapDioError(e));
    } catch (e, st) {
      AppLogger.error('postToWebhook failed', e, st);
      return Result.err(UnknownException(e.toString(), cause: e));
    }
  }

  /// Streams incrementally-decoded text chunks from a webhook that returns
  /// a chunked/streaming HTTP response — used by the chat feature to render
  /// tokens as they arrive instead of waiting for the full reply.
  Stream<String> streamMessage(N8nRequest request) async* {
    final url = await _requireWebhookUrl();
    final apiKey = await _secureStorage.apiKey;

    final response = await _dio.post<ResponseBody>(
      url,
      data: jsonEncode(request.toJson()),
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          if (apiKey != null && apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    final stream = response.data?.stream;
    if (stream == null) return;

    await for (final chunk in stream.cast<List<int>>().transform(utf8.decoder)) {
      for (final line in const LineSplitter().convert(chunk)) {
        final payload = line.startsWith('data:') ? line.substring(5).trim() : line.trim();
        if (payload.isEmpty) continue;
        yield payload;
      }
    }
  }

  /// Multipart upload for knowledge-base documents.
  Future<Result<Map<String, dynamic>>> uploadFile({
    required String filePath,
    required String fileName,
    Map<String, dynamic>? fields,
  }) async {
    try {
      final url = await _requireWebhookUrl();
      final formData = FormData.fromMap({
        ...?fields,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post<Map<String, dynamic>>(url, data: formData);
      return Result.ok(response.data ?? const {});
    } on DioException catch (e) {
      return Result.err(_mapDioError(e));
    } catch (e) {
      return Result.err(UnknownException(e.toString(), cause: e));
    }
  }

  Future<void> _enqueueOffline(N8nRequest request) async {
    await _outboxBox.add(request.toJson());
    AppLogger.info('Queued offline request for chat ${request.chatId}');
  }

  /// Replays every queued request in FIFO order. Stops (keeping the
  /// remainder queued) on the first failure so a still-flaky connection
  /// doesn't drop messages.
  Future<List<N8nResponse>> flushOutbox() async {
    final sent = <N8nResponse>[];
    final keys = _outboxBox.keys.toList();
    for (final key in keys) {
      final raw = _outboxBox.get(key);
      if (raw == null) continue;
      final request = N8nRequest.fromJson(Map<String, dynamic>.from(raw as Map));
      final result = await postToWebhook(request);
      final response = result.when(ok: (v) => v, err: (_) => null);
      if (response == null) break;
      sent.add(response);
      await _outboxBox.delete(key);
    }
    return sent;
  }

  int get pendingOutboxCount => _outboxBox.length;

  AppException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const NetworkException('Could not reach the backend. Check your connection.');
      case DioExceptionType.badResponse:
        return NetworkException(
          'Backend error (${e.response?.statusCode}).',
          statusCode: e.response?.statusCode,
        );
      default:
        return NetworkException(e.message ?? 'Network request failed.');
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    secureStorage: ref.watch(secureStorageProvider),
    connectivity: ref.watch(connectivityProvider),
    outboxBox: ref.watch(hiveServiceProvider).outboxBox,
  );
});
