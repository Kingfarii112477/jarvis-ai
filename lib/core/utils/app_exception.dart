/// Typed exceptions replace bare `Exception('string')` throws across the
/// app so callers (UI, retry logic, crash reporting) can branch on `type`
/// instead of parsing message strings.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, this.statusCode});
  final int? statusCode;
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.cause});
}

class ConfigurationException extends AppException {
  const ConfigurationException(super.message, {super.cause});
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message, {super.cause});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause});
}

/// Maps any thrown object into a friendly, user-presentable string. Used at
/// the UI boundary (StateNotifiers / AsyncNotifiers) so raw stack traces
/// never leak into a SnackBar.
String describeException(Object error) {
  if (error is AppException) return error.message;
  return 'Something went wrong. Please try again.';
}
