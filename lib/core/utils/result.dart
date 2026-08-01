import 'app_exception.dart';

/// A minimal `Result<T>` so repositories return typed success/failure
/// instead of throwing across architectural layers. UI code pattern-matches
/// with `switch` instead of wrapping every call in try/catch.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppException error) = Err<T>;

  R when<R>({
    required R Function(T value) ok,
    required R Function(AppException error) err,
  }) {
    final self = this;
    if (self is Ok<T>) return ok(self.value);
    return err((self as Err<T>).error);
  }

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final AppException error;
}
