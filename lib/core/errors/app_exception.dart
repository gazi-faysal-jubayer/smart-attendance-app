sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error. Please check your connection.']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error.']);
}

class SyncException extends AppException {
  const SyncException([super.message = 'Sync failed.']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation error.']);
}

class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Database error.']);
}
