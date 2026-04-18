class AppException implements Exception {
  final String message;
  final Object? originalException;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.originalException, this.stackTrace});

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
    super.message, {
    super.originalException,
    super.stackTrace,
  });
}

class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });
}

class SyncException extends AppException {
  const SyncException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });
}

class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });
}
