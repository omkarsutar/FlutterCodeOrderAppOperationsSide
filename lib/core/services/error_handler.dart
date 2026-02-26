import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/snackbar_utils.dart';
import 'logger_service.dart';

/// Centralized error handler for the application.
///
/// Provides consistent error handling across the app with:
/// - Structured logging
/// - User-friendly error messages
/// - Context-aware error reporting
/// - Production-ready error tracking
class ErrorHandler {
  static final _logger = LoggerServiceImpl();

  /// Handles an error with optional user notification and logging.
  ///
  /// **Parameters:**
  /// - [error]: The error object
  /// - [stackTrace]: Stack trace for debugging
  /// - [context]: Description of where the error occurred (e.g., 'Loading shops')
  /// - [showToUser]: Whether to show a snackbar to the user
  /// - [userMessage]: Custom message to show user (if null, generates one)
  /// - [logLevel]: Severity level (error, warning, info)
  ///
  /// **Example:**
  /// ```dart
  /// try {
  ///   await fetchShops();
  /// } catch (e, stackTrace) {
  ///   ErrorHandler.handle(
  ///     e,
  ///     stackTrace,
  ///     context: 'Fetching shops for route',
  ///     showToUser: true,
  ///   );
  /// }
  /// ```
  static void handle(
    Object error,
    StackTrace? stackTrace, {
    required String context,
    bool showToUser = true,
    String? userMessage,
    ErrorLogLevel logLevel = ErrorLogLevel.error,
  }) {
    // Log the error
    final logMessage = 'Error in $context: ${error.toString()}';

    switch (logLevel) {
      case ErrorLogLevel.error:
        _logger.error(logMessage, stackTrace);
        break;
      case ErrorLogLevel.warning:
        _logger.warning(logMessage, stackTrace);
        break;
      case ErrorLogLevel.info:
        _logger.info(logMessage);
        break;
    }

    // Show user-friendly message if requested
    if (showToUser) {
      final message = userMessage ?? _getUserFriendlyMessage(error, context);
      SnackbarUtils.showError(message);
    }

    // In debug mode, print detailed error info
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔴 ERROR in: $context');
      debugPrint('Type: ${error.runtimeType}');
      debugPrint('Message: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Generates a user-friendly error message based on the error type.
  static String _getUserFriendlyMessage(Object error, String context) {
    // Supabase/PostgreSQL errors
    if (error is PostgrestException) {
      return _handlePostgrestException(error);
    }

    // Authentication errors
    if (error is AuthException) {
      return _handleAuthException(error);
    }

    // Storage errors
    if (error is StorageException) {
      return 'File operation failed. Please try again.';
    }

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'No internet connection. Please check your network.';
    }

    // Timeout errors
    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    // Format errors (parsing, etc.)
    if (error is FormatException) {
      return 'Invalid data format. Please contact support.';
    }

    // Type errors
    if (error is TypeError) {
      return 'Data processing error. Please try again.';
    }

    // Generic fallback
    return 'Something went wrong in $context. Please try again.';
  }

  /// Handles PostgreSQL/Supabase database errors.
  static String _handlePostgrestException(PostgrestException error) {
    final code = error.code;
    final message = error.message.toLowerCase();

    // Unique constraint violations
    if (code == '23505' ||
        message.contains('duplicate') ||
        message.contains('unique')) {
      return 'This record already exists. Please use a different value.';
    }

    // Foreign key violations
    if (code == '23503' || message.contains('foreign key')) {
      return 'Cannot perform this action. Related records exist.';
    }

    // Not null violations
    if (code == '23502' || message.contains('not null')) {
      return 'Required field is missing. Please fill all required fields.';
    }

    // Permission denied
    if (code == '42501' || message.contains('permission denied')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Row level security
    if (message.contains('row level security') || message.contains('rls')) {
      return 'Access denied. Please check your permissions.';
    }

    // Connection errors
    if (message.contains('connection') || message.contains('timeout')) {
      return 'Database connection failed. Please try again.';
    }

    // Generic database error
    return 'Database error occurred. Please try again later.';
  }

  /// Handles Supabase authentication errors.
  static String _handleAuthException(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }

    if (message.contains('user already registered') ||
        message.contains('email already exists')) {
      return 'An account with this email already exists.';
    }

    if (message.contains('invalid token') || message.contains('jwt expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (message.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (message.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    }

    return 'Authentication failed. Please try again.';
  }

  /// Handles errors silently (logs but doesn't show to user).
  static void handleSilent(
    Object error,
    StackTrace? stackTrace, {
    required String context,
  }) {
    handle(error, stackTrace, context: context, showToUser: false);
  }

  /// Handles errors with a custom user message.
  static void handleWithMessage(
    Object error,
    StackTrace? stackTrace, {
    required String context,
    required String userMessage,
  }) {
    handle(
      error,
      stackTrace,
      context: context,
      showToUser: true,
      userMessage: userMessage,
    );
  }

  /// Wraps an async operation with error handling.
  ///
  /// **Example:**
  /// ```dart
  /// final shops = await ErrorHandler.wrapAsync(
  ///   () => shopService.fetchAll(),
  ///   context: 'Loading shops',
  ///   onError: () => <ModelShop>[], // Fallback value
  /// );
  /// ```
  static Future<T> wrapAsync<T>(
    Future<T> Function() operation, {
    required String context,
    bool showToUser = true,
    T Function()? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      handle(e, stackTrace, context: context, showToUser: showToUser);

      if (onError != null) {
        return onError();
      }
      rethrow;
    }
  }

  /// Wraps a synchronous operation with error handling.
  static T wrapSync<T>(
    T Function() operation, {
    required String context,
    bool showToUser = true,
    T Function()? onError,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      handle(e, stackTrace, context: context, showToUser: showToUser);

      if (onError != null) {
        return onError();
      }
      rethrow;
    }
  }
}

/// Error severity levels for logging.
enum ErrorLogLevel {
  /// Critical errors that need immediate attention
  error,

  /// Warnings that should be investigated
  warning,

  /// Informational messages
  info,
}
