class AppException implements Exception {
  final String message;
  final Object? originalException;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    if (originalException != null) {
      return '$message (${originalException.toString()})';
    }
    return message;
  }
}

class ValidationException extends AppException {
  const ValidationException(
    String message, {
    Object? originalException,
    StackTrace? stackTrace,
  }) : super(
          message,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

class AuthenticationException extends AppException {
  const AuthenticationException(
    String message, {
    Object? originalException,
    StackTrace? stackTrace,
  }) : super(
          message,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

class SyncException extends AppException {
  const SyncException(
    String message, {
    Object? originalException,
    StackTrace? stackTrace,
  }) : super(
          message,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

class CacheException extends AppException {
  const CacheException(
    String message, {
    Object? originalException,
    StackTrace? stackTrace,
  }) : super(
          message,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}
