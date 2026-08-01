import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../utils/app_logger.dart';

/// Retries idempotent-enough failures (timeouts, connection errors, 502/503/
/// 504) with exponential backoff, up to [AppConfig.maxRetries]. Anything
/// else (4xx, non-network exceptions) is passed straight through — retrying
/// a 400 or 401 would just hammer the server for a request that will never
/// succeed.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio);

  final Dio _dio;

  static const _retryCountKey = 'retry_count';
  static const _retryableStatusCodes = {502, 503, 504};

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final attempt = (requestOptions.extra[_retryCountKey] as int?) ?? 0;

    final shouldRetry = attempt < AppConfig.maxRetries && _isRetryable(err);
    if (!shouldRetry) {
      return handler.next(err);
    }

    final delay = AppConfig.retryBaseDelay * (1 << attempt);
    AppLogger.warning(
      'Request to ${requestOptions.path} failed (${err.type}); retry ${attempt + 1}/${AppConfig.maxRetries} in ${delay.inMilliseconds}ms',
    );
    await Future.delayed(delay);

    requestOptions.extra[_retryCountKey] = attempt + 1;
    try {
      final response = await _dio.fetch(requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = err.response?.statusCode;
    return status != null && _retryableStatusCodes.contains(status);
  }
}
