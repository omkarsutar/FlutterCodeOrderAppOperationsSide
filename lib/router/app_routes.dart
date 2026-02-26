/// AppRoute class-based constants system for managing all routes in the application.
///
/// This provides a single source of truth for all routes, supporting:
/// - Route names (for GoRouter named navigation)
/// - Route URLs/paths (for GoRouter configuration)
/// - Path parameter building (e.g., /shops/:id → /shops/123)
/// - Type-safe route definitions

class AppRoute {
  /// Auth & Root Routes
  static const String welcome = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profile = '/profile';
  static const String loading = '/loading';
  static const String cart = '/cart';
  static const String unauthorized = '/unauthorized';

  // Route names for GoRouter named navigation
  static const String welcomeName = 'welcome';
  static const String loginName = 'login';
  static const String signupName = 'signup';
  static const String profileName = 'profile';
  static const String loadingName = 'loading';
  static const String cartName = 'cart';
  static const String unauthorizedName = 'unauthorized';

  /// ============================================================================
  /// Notes Routes
  /// ============================================================================

  /// ============================================================================
  /// Routes Management Routes
  /// ============================================================================

  /// ============================================================================
  /// Shops Routes
  /// ============================================================================

  /// ============================================================================
  /// Route-Shop Links Routes
  /// ============================================================================

  /// ============================================================================
  /// Roles Routes
  /// ============================================================================

  /// ============================================================================
  /// RBAC Modules Routes
  /// ============================================================================

  /// ============================================================================
  /// Users Routes
  /// ============================================================================

  /// ============================================================================
  /// Purchase Orders Routes
  /// ============================================================================

  /// ============================================================================
  /// PO Items Routes
  /// ============================================================================

  /// ============================================================================
  /// Products Routes
  /// ============================================================================
}
