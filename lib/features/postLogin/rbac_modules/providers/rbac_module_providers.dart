import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/rbac_module_adapter.dart';
import '../model/rbac_module_model.dart';
import '../service/rbac_module_service_impl.dart';

/// Mapper provider
final rbacModuleMapperProvider = Provider<EntityMapper<ModelRbacModule>>((ref) {
  return ModelRbacModuleMapper();
});

/// Service provider
final rbacModuleServiceProvider = Provider<RbacModuleServiceImpl>((ref) {
  return RbacModuleServiceImpl(
    ref.watch(rbacModuleMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final rbacModuleAdapterProvider = Provider<RbacModuleAdapter>((ref) {
  return RbacModuleAdapter();
});

/// Fetches all RBAC modules with automatic disposal
/// Uses StreamProvider for real-time updates
final rbacModulesStreamProvider =
    StreamProvider.autoDispose<List<ModelRbacModule>>((ref) {
      final service = ref.read(rbacModuleServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single RBAC module by ID
final rbacModuleByIdProvider = FutureProvider.autoDispose
    .family<ModelRbacModule?, String>((ref, moduleId) async {
      final service = ref.read(rbacModuleServiceProvider);
      return await service.fetchById(moduleId);
    });

/// State provider for managing RBAC module creation/editing
final rbacModuleFormProvider =
    StateNotifierProvider.autoDispose<
      RbacModuleFormNotifier,
      RbacModuleFormState
    >((ref) => RbacModuleFormNotifier(ref));

/// Form state for RBAC module
class RbacModuleFormState {
  final String moduleName;
  final String moduleDescription;
  final bool isActive;
  final bool isLoading;
  final String? error;

  RbacModuleFormState({
    this.moduleName = '',
    this.moduleDescription = '',
    this.isActive = true,
    this.isLoading = false,
    this.error,
  });

  RbacModuleFormState copyWith({
    String? moduleName,
    String? moduleDescription,
    bool? isActive,
    bool? isLoading,
    String? error,
  }) {
    return RbacModuleFormState(
      moduleName: moduleName ?? this.moduleName,
      moduleDescription: moduleDescription ?? this.moduleDescription,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing RBAC module form state
class RbacModuleFormNotifier extends StateNotifier<RbacModuleFormState> {
  final Ref ref;

  RbacModuleFormNotifier(this.ref) : super(RbacModuleFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateModuleName(String name) {
    if (!_mounted) return;
    state = state.copyWith(moduleName: name, error: null);
  }

  void updateModuleDescription(String description) {
    if (!_mounted) return;
    state = state.copyWith(moduleDescription: description, error: null);
  }

  void updateIsActive(bool isActive) {
    if (!_mounted) return;
    state = state.copyWith(isActive: isActive, error: null);
  }

  void loadEntity(ModelRbacModule entity) {
    if (!_mounted) return;
    state = RbacModuleFormState(
      moduleName: entity.moduleName,
      moduleDescription: entity.moduleDescription ?? '',
      isActive: entity.isActive,
    );
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(rbacModuleServiceProvider);

      final entity = ModelRbacModule(
        moduleId: entityId,
        moduleName: state.moduleName,
        moduleDescription: state.moduleDescription.isEmpty
            ? null
            : state.moduleDescription,
        isActive: state.isActive,
      );

      if (entityId == null) {
        // Create new
        await service.create(entity);
      } else {
        // Update existing
        await service.update(entityId, entity);
      }

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(rbacModuleServiceProvider);
      await service.deleteEntityById(entityId);

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelRbacModuleFields.moduleName:
        updateModuleName(value as String);
        break;
      case ModelRbacModuleFields.moduleDescription:
        updateModuleDescription(value as String);
        break;
      case ModelRbacModuleFields.isActive:
        updateIsActive(value as bool);
        break;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}
