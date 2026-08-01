import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_app/core/utils/app_exception.dart';

void main() {
  group('AppException subtypes', () {
    test('toString() returns the message', () {
      const error = NetworkException('offline');
      expect(error.toString(), 'offline');
    });

    test('carry statusCode/cause through where applicable', () {
      final cause = Exception('root cause');
      final network = NetworkException('bad gateway', statusCode: 502, cause: cause);
      expect(network.statusCode, 502);
      expect(network.cause, cause);

      const timeout = TimeoutException('timed out');
      const config = ConfigurationException('missing webhook url');
      const permission = PermissionDeniedException('mic denied');
      const storage = StorageException('disk full');
      const unknown = UnknownException('mystery');

      expect(timeout.message, 'timed out');
      expect(config.message, 'missing webhook url');
      expect(permission.message, 'mic denied');
      expect(storage.message, 'disk full');
      expect(unknown.message, 'mystery');
    });
  });

  group('describeException', () {
    test('returns the AppException message verbatim', () {
      expect(describeException(const NetworkException('no signal')), 'no signal');
    });

    test('falls back to a friendly message for non-AppException errors', () {
      expect(describeException(Exception('raw stack trace leak')), 'Something went wrong. Please try again.');
      expect(describeException('a plain string'), 'Something went wrong. Please try again.');
    });
  });
}
