import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Single logging entry point for the whole app. Wrapping `package:logger`
/// here means call sites never depend on the logging library directly, and
/// production log verbosity is controlled from one place.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    level: kReleaseMode ? Level.warning : Level.debug,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: !kReleaseMode,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  static void info(String message) => _logger.i(message);

  static void warning(String message, [Object? error]) => _logger.w(message, error: error);

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
