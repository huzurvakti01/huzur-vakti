import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger instance = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 90,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String message, {Map<String, Object?> context = const {}}) {
    instance.d(_format(message, context));
  }

  static void info(String message, {Map<String, Object?> context = const {}}) {
    instance.i(_format(message, context));
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    instance.w(_format(message, context), error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    instance.e(_format(message, context), error: error, stackTrace: stackTrace);
  }

  static String _format(String message, Map<String, Object?> context) {
    if (context.isEmpty) return message;
    final data = context.entries.map((e) => '${e.key}=${e.value}').join(' ');
    return '$message | $data';
  }
}
