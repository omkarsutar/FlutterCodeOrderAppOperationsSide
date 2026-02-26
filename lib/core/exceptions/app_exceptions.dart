/// Base exception class for all app-specific exceptions
/// Captures message and stack trace for proper error handling and logging
abstract class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AppException(this.message, [this.stackTrace]);

  @override
  String toString() => message;
}

/// Network-related exceptions
/// Use when there are issues with API calls or internet connectivity
class NetworkException extends AppException {
  NetworkException(String message, [StackTrace? stackTrace])
    : super('Network Error: $message', stackTrace);
}

/// Database-related exceptions
/// Use when Supabase operations fail (insert, update, delete, select)
class DatabaseException extends AppException {
  DatabaseException(String message, [StackTrace? stackTrace])
    : super('Database Error: $message', stackTrace);
}

/// Validation-related exceptions
/// Use when user input or data validation fails
class ValidationException extends AppException {
  ValidationException(String message, [StackTrace? stackTrace])
    : super('Validation Error: $message', stackTrace);
}

/// Authentication/Authorization exceptions
/// Use when user is not authenticated or doesn't have permission
class UnauthorizedException extends AppException {
  UnauthorizedException(String message, [StackTrace? stackTrace])
    : super('Authorization Error: $message', stackTrace);
}

/// Parse/Deserialization exceptions
/// Use when JSON parsing or model conversion fails
class ParseException extends AppException {
  ParseException(String message, [StackTrace? stackTrace])
    : super('Parse Error: $message', stackTrace);
}

/// Operation timeout exceptions
/// Use when async operations take too long
class TimeoutException extends AppException {
  TimeoutException(String message, [StackTrace? stackTrace])
    : super('Timeout Error: $message', stackTrace);
}

/// Unexpected/Unknown exceptions
/// Use as fallback for uncategorized errors
class UnknownException extends AppException {
  UnknownException(String message, [StackTrace? stackTrace])
    : super('Unknown Error: $message', stackTrace);
}
