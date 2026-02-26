import 'package:flutter/foundation.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_permissions/rbac_permission_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'error_handler.dart';

/// Enum representing the 4 permission actions in RBAC
enum RbacAction { read, create, update, delete }

extension RbacActionExt on RbacAction {
  String get name {
    switch (this) {
      case RbacAction.read:
        return 'can_read';
      case RbacAction.create:
        return 'can_create';
      case RbacAction.update:
        return 'can_update';
      case RbacAction.delete:
        return 'can_delete';
    }
  }
}

/// Service to manage RBAC permission checks
class RbacService {
  final SupabaseClient _client;

  RbacService(this._client);

  // Cache for current user's permissions
  // Format: {moduleId: {action: hasPermission}}
  Map<String, Map<RbacAction, bool>> _permissionCache = {};
  String? _cachedRoleId;
  String? _cachedRoleName; // NEW

  /// Notifier for initialization state
  final ValueNotifier<bool> initializationNotifier = ValueNotifier<bool>(false);

  /// Get current initialization state
  bool get isInitialized => initializationNotifier.value;

  /// Initialize the RBAC system by loading user's role and permissions
  /// Should be called when user is authenticated
  Future<void> initializeRbac(String userId) async {
    try {
      // Get user's role
      final userData = await _client
          .from(ModelUserFields.table)
          .select('${ModelUserFields.roleId}, rbac_roles(role_name)')
          .eq(ModelUserFields.userId, userId)
          .single();

      _cachedRoleId = userData[ModelUserFields.roleId] as String?;
      _cachedRoleName = userData['rbac_roles']?['role_name'] as String?;

      if (_cachedRoleId == null) {
        throw Exception('User has no assigned role');
      }

      // Load all permissions for this role
      await _loadUserPermissions(_cachedRoleId!);

      // Notify listeners that RBAC is ready
      initializationNotifier.value = true;
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        context: 'Initializing RBAC for user $userId',
        showToUser: true,
      );
      // Ensure we don't leave it in a "loading" state forever if it fails,
      // though false is the default.
      initializationNotifier.value = false;
      rethrow;
    }
  }

  /// Load all permissions for a specific role
  Future<void> _loadUserPermissions(String roleId) async {
    try {
      final permissions = await _client
          .from(ModelRbacPermissionFields.table)
          .select('*, rbac_modules(module_name)')
          // .select('*')
          .eq(ModelRbacPermissionFields.roleId, roleId);

      _permissionCache.clear();

      for (final permData in permissions) {
        final permission = ModelRbacPermission.fromMap(permData);
        final moduleName = permData['rbac_modules']['module_name'] as String;

        _permissionCache[moduleName] = {
          RbacAction.read: permission.canRead,
          RbacAction.create: permission.canCreate,
          RbacAction.update: permission.canUpdate,
          RbacAction.delete: permission.canDelete,
        };
      }
      /* for (final permData in permissions) {
        final permission = ModelRbacPermission.fromMap(permData);
        final moduleId = permission.moduleId;

        _permissionCache[moduleId] = {
          RbacAction.read: permission.canRead,
          RbacAction.create: permission.canCreate,
          RbacAction.update: permission.canUpdate,
          RbacAction.delete: permission.canDelete,
        };
      } */
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        context: 'Loading user permissions for role $roleId',
        showToUser: false,
        logLevel: ErrorLogLevel.error,
      );
      rethrow;
    }
  }

  /// Check if current user has permission for a specific action on a module
  /// Returns true if permission exists and is granted, false otherwise
  bool hasPermission(String moduleId, RbacAction action) {
    // If we haven't identified the user's role yet, RBAC isn't initialized
    if (_cachedRoleId == null) {
      // Don't log warning here anymore as we handle it in UI now
      return false;
    }

    // If cache is empty but we have a role, it means user has NO permissions
    // (or permissions failed to load, which should have been logged in initializeRbac)
    if (_permissionCache.isEmpty) {
      return false;
    }

    return _permissionCache[moduleId]?[action] ?? false;
  }

  /// Check multiple permissions (AND logic - all must be true)
  bool hasAllPermissions(String moduleId, List<RbacAction> actions) {
    return actions.every((action) => hasPermission(moduleId, action));
  }

  /// Check multiple permissions (OR logic - at least one must be true)
  bool hasAnyPermission(String moduleId, List<RbacAction> actions) {
    return actions.any((action) => hasPermission(moduleId, action));
  }

  /// Convenience methods for common checks
  bool canRead(String moduleId) => hasPermission(moduleId, RbacAction.read);
  bool canCreate(String moduleId) => hasPermission(moduleId, RbacAction.create);
  bool canUpdate(String moduleId) => hasPermission(moduleId, RbacAction.update);
  bool canDelete(String moduleId) => hasPermission(moduleId, RbacAction.delete);

  /// Get current user's role ID
  String? get roleId => _cachedRoleId;
  String? get roleName => _cachedRoleName; // NEW

  /// Refresh permissions from server (use when permissions might have changed)
  Future<void> refreshPermissions() async {
    if (_cachedRoleId == null) {
      throw Exception('No role ID cached. Initialize RBAC first.');
    }
    await _loadUserPermissions(_cachedRoleId!);
  }

  /// Clear all cached data (call on logout)
  void clearCache() {
    _permissionCache.clear();
    _cachedRoleId = null;
    _cachedRoleName = null;
    initializationNotifier.value = false;
  }

  /// Get all cached permissions (useful for debugging)
  Map<String, Map<RbacAction, bool>> get cachedPermissions =>
      Map.unmodifiable(_permissionCache);
}
