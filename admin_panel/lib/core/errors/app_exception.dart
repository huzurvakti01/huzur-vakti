class AppException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  final String code;

  const AppException(
    this.message, {
    this.cause,
    this.stackTrace,
    this.code = 'app_error',
  });

  @override
  String toString() => message;
}
