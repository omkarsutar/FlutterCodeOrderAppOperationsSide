/// Abstract logger service interface
/// Provides centralized logging for the application
/// Can be easily extended to integrate with Firebase Crashlytics, Sentry, etc.
abstract class LoggerService {
  /// Log informational message
  void info(String message);

  /// Log warning message with optional stack trace
  void warning(String message, [StackTrace? stackTrace]);

  /// Log error message with stack trace
  void error(String message, StackTrace? stackTrace);

  /// Flush logs (useful for persistence or sending to remote service)
  Future<void> flush();
}

/// Production implementation of LoggerService
/// TODO: Integrate with Firebase Crashlytics for production
/// TODO: Add analytics tracking for important events
class LoggerServiceImpl implements LoggerService {
  static const String _tag = 'OrderApp';

  @override
  void info(String message) {
    print('[$_tag] ℹ️  $message');
    // TODO: Send to Firebase Analytics in production
    // FirebaseAnalytics.instance.logEvent(name: 'info', parameters: {'message': message});
  }

  @override
  void warning(String message, [StackTrace? stackTrace]) {
    print('[$_tag] ⚠️  $message');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
    // TODO: Send to Firebase Crashlytics in production with non-fatal exception
    // FirebaseCrashlytics.instance.recordError(Exception(message), stackTrace, reason: 'warning');
  }

  @override
  void error(String message, StackTrace? stackTrace) {
    print('[$_tag] ❌ $message');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
    // TODO: Send to Firebase Crashlytics in production
    // FirebaseCrashlytics.instance.recordError(Exception(message), stackTrace);
  }

  @override
  Future<void> flush() async {
    // TODO: Implement flush for production logging service
    // This would send buffered logs to remote service if needed
  }
}
