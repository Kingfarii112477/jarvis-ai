import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_app/core/utils/app_exception.dart';
import 'package:jarvis_app/core/utils/result.dart';

void main() {
  test('Ok carries the success value through when()', () {
    const result = Result<int>.ok(42);
    final mapped = result.when(ok: (v) => 'value=$v', err: (e) => 'error=${e.message}');
    expect(mapped, 'value=42');
    expect(result.isOk, isTrue);
  });

  test('Err carries the AppException through when()', () {
    const result = Result<int>.err(NetworkException('offline'));
    final mapped = result.when(ok: (v) => 'value=$v', err: (e) => 'error=${e.message}');
    expect(mapped, 'error=offline');
    expect(result.isOk, isFalse);
  });
}
