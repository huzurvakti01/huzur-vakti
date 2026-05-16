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
  String toString() => 'AppException($code): $message';
}

class NetworkAppException extends AppException {
  const NetworkAppException({
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          'Bağlantı koptu, lütfen internetinizi kontrol edin.',
          cause: cause,
          stackTrace: stackTrace,
          code: 'network_error',
        );
}

class PermissionAppException extends AppException {
  const PermissionAppException(
    super.message, {
    super.cause,
    super.stackTrace,
  }) : super(code: 'permission_error');
}

class StoreAppException extends AppException {
  const StoreAppException(
    super.message, {
    super.cause,
    super.stackTrace,
  }) : super(code: 'store_error');
}
