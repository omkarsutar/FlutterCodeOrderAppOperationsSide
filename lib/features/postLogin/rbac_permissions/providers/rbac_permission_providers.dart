import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/rbac_permission_adapter.dart';
import '../model/rbac_permission_model.dart';
import '../service/rbac_permission_service_impl.dart';

/// Mapper provider
final rbacPermissionMapperProvider =
    Provider<EntityMapper<ModelRbacPermission>>((ref) {
      return ModelRbacPermissionMapper();
    });

/// Service provider
final rbacPermissionServiceProvider = Provider<RbacPermissionServiceImpl>((
  ref,
) {
  return RbacPermissionServiceImpl(
    ref.watch(rbacPermissionMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final rbacPermissionAdapterProvider = Provider<RbacPermissionAdapter>((ref) {
  return RbacPermissionAdapter();
});

/// Fetches all permissions with automatic disposal
/// Uses StreamProvider for real-time updates from view_rbac_permissions
final rbacPermissionsStreamProvider =
    StreamProvider.autoDispose<List<ModelRbacPermission>>((ref) {
      final service = ref.read(rbacPermissionServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single permission by ID
final rbacPermissionByIdProvider = FutureProvider.autoDispose
    .family<ModelRbacPermission?, String>((ref, permissionId) async {
      final service = ref.read(rbacPermissionServiceProvider);
      return await service.fetchById(permissionId);
    });

/// State provider for managing permission creation/editing
final rbacPermissionFormProvider =
    StateNotifierProvider.autoDispose<
      RbacPermissionFormNotifier,
      RbacPermissionFormState
    >((ref) => RbacPermissionFormNotifier(ref));

/// Form state for RBAC permission
class RbacPermissionFormState {
  final String roleId;
  final String moduleId;
  final bool canRead;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;
  final bool isLoading;
  final String? error;

  RbacPermissionFormState({
    this.roleId = '',
    this.moduleId = '',
    this.canRead = false,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
    this.isLoading = false,
    this.error,
  });

  RbacPermissionFormState copyWith({
    String? roleId,
    String? moduleId,
    bool? canRead,
    bool? canCreate,
    bool? canUpdate,
    bool? canDelete,
    bool? isLoading,
    String? error,
  }) {
    return RbacPermissionFormState(
      roleId: roleId ?? this.roleId,
      moduleId: moduleId ?? this.moduleId,
      canRead: canRead ?? this.canRead,
      canCreate: canCreate ?? this.canCreate,
      canUpdate: canUpdate ?? this.canUpdate,
      canDelete: canDelete ?? this.canDelete,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing RBAC permission form state
class RbacPermissionFormNotifier
    extends StateNotifier<RbacPermissionFormState> {
  final Ref ref;
  bool _mounted = true;

  RbacPermissionFormNotifier(this.ref) : super(RbacPermissionFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateField(String fieldName, dynamic value) {
    if (!_mounted) return;

    switch (fieldName) {
      case ModelRbacPermissionFields.roleId:
        state = state.copyWith(roleId: value as String, error: null);
        break;
      case ModelRbacPermissionFields.moduleId:
        state = state.copyWith(moduleId: value as String, error: null);
        break;
      case ModelRbacPermissionFields.canRead:
        state = state.copyWith(canRead: value as bool, error: null);
        break;
      case ModelRbacPermissionFields.canCreate:
        state = state.copyWith(canCreate: value as bool, error: null);
        break;
      case ModelRbacPermissionFields.canUpdate:
        state = state.copyWith(canUpdate: value as bool, error: null);
        break;
      case ModelRbacPermissionFields.canDelete:
        state = state.copyWith(canDelete: value as bool, error: null);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    // Validation
    if (state.roleId.trim().isEmpty) {
      state = state.copyWith(error: 'Role is required');
      return false;
    }
    if (state.moduleId.trim().isEmpty) {
      state = state.copyWith(error: 'Module is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(rbacPermissionServiceProvider);
      final entity = ModelRbacPermission(
        permissionId: entityId,
        roleId: state.roleId.trim(),
        moduleId: state.moduleId.trim(),
        canRead: state.canRead,
        canCreate: state.canCreate,
        canUpdate: state.canUpdate,
        canDelete: state.canDelete,
      );

      if (entityId == null) {
        // Create new permission
        await service.create(entity);
      } else {
        // Update existing permission
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save permission: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(rbacPermissionServiceProvider);
      await service.deleteEntityById(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete permission: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelRbacPermission entity) {
    if (!_mounted) return;
    state = RbacPermissionFormState(
      roleId: entity.roleId,
      moduleId: entity.moduleId,
      canRead: entity.canRead,
      canCreate: entity.canCreate,
      canUpdate: entity.canUpdate,
      canDelete: entity.canDelete,
    );
  }

  void reset() {
    if (!_mounted) return;
    state = RbacPermissionFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}
