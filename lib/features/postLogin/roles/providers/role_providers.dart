import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/role_adapter.dart';
import '../model/role_model.dart';
import '../service/role_service_impl.dart';

/// Mapper provider
final roleMapperProvider = Provider<EntityMapper<ModelRole>>((ref) {
  return ModelRoleMapper();
});

/// Service provider
final roleServiceProvider = Provider<RoleServiceImpl>((ref) {
  return RoleServiceImpl(
    ref.watch(roleMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final roleAdapterProvider = Provider<RoleAdapter>((ref) {
  return RoleAdapter();
});

/// Fetches all roles with automatic disposal
/// Uses StreamProvider for real-time updates
final rolesStreamProvider = StreamProvider.autoDispose<List<ModelRole>>((ref) {
  final service = ref.read(roleServiceProvider);
  return service.streamEntities();
});

/// Fetches a single role by ID
final roleByIdProvider = FutureProvider.autoDispose.family<ModelRole?, String>((
  ref,
  roleId,
) async {
  final service = ref.read(roleServiceProvider);
  return await service.fetchById(roleId);
});

/// State provider for managing role creation/editing
final roleFormProvider =
    StateNotifierProvider.autoDispose<RoleFormNotifier, RoleFormState>(
      (ref) => RoleFormNotifier(ref),
    );

/// Form state for role
class RoleFormState {
  final String roleName;
  final String roleDescription;
  final bool isActive;
  final bool isLoading;
  final String? error;

  RoleFormState({
    this.roleName = '',
    this.roleDescription = '',
    this.isActive = true,
    this.isLoading = false,
    this.error,
  });

  RoleFormState copyWith({
    String? roleName,
    String? roleDescription,
    bool? isActive,
    bool? isLoading,
    String? error,
  }) {
    return RoleFormState(
      roleName: roleName ?? this.roleName,
      roleDescription: roleDescription ?? this.roleDescription,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing role form state
class RoleFormNotifier extends StateNotifier<RoleFormState> {
  final Ref ref;

  RoleFormNotifier(this.ref) : super(RoleFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateRoleName(String name) {
    if (!_mounted) return;
    state = state.copyWith(roleName: name, error: null);
  }

  void updateRoleDescription(String description) {
    if (!_mounted) return;
    state = state.copyWith(roleDescription: description, error: null);
  }

  void updateIsActive(bool isActive) {
    if (!_mounted) return;
    state = state.copyWith(isActive: isActive, error: null);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    switch (field) {
      case ModelRoleFields.roleName:
        updateRoleName(value as String);
        break;
      case ModelRoleFields.roleDescription:
        updateRoleDescription(value as String);
        break;
      case ModelRoleFields.isActive:
        updateIsActive(value as bool);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;
    if (state.roleName.trim().isEmpty) {
      state = state.copyWith(
        error: '${roleEntityMeta.entityName} name cannot be empty',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(roleServiceProvider);
      final entity = ModelRole(
        roleId: entityId,
        roleName: state.roleName.trim(),
        roleDescription: state.roleDescription.trim(),
        isActive: state.isActive,
      );

      if (entityId == null) {
        // Create new role
        await service.create(entity);
      } else {
        // Update existing role
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save ${roleEntityMeta.entityNameLower}: $e',
      );
      return false;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(roleServiceProvider);
      await service.deleteEntityById(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete ${roleEntityMeta.entityNameLower}: $e',
      );
      return false;
    }
  }

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);

  void loadEntity(ModelRole entity) {
    if (!_mounted) return;
    state = state.copyWith(
      roleName: entity.roleName,
      roleDescription: entity.roleDescription ?? '',
      isActive: entity.isActive,
    );
  }

  void reset() {
    if (!_mounted) return;
    state = RoleFormState();
  }
}
