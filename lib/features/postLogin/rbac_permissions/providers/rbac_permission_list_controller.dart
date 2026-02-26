import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../rbac_modules/rbac_module_barrel.dart';
import '../../roles/role_barrel.dart';
import '../model/rbac_permission_model.dart';
import '../providers/rbac_permission_providers.dart';

class RbacPermissionListState {
  final bool isLoading;
  final String? error;
  final Map<String, List<ModelRbacPermission>> permissionsByRole;
  final Map<String, String> roleNames;
  final Map<String, String> moduleNames;

  const RbacPermissionListState({
    this.isLoading = true,
    this.error,
    this.permissionsByRole = const {},
    this.roleNames = const {},
    this.moduleNames = const {},
  });

  RbacPermissionListState copyWith({
    bool? isLoading,
    String? error,
    Map<String, List<ModelRbacPermission>>? permissionsByRole,
    Map<String, String>? roleNames,
    Map<String, String>? moduleNames,
  }) {
    return RbacPermissionListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionsByRole: permissionsByRole ?? this.permissionsByRole,
      roleNames: roleNames ?? this.roleNames,
      moduleNames: moduleNames ?? this.moduleNames,
    );
  }
}

class RbacPermissionListController
    extends AutoDisposeNotifier<RbacPermissionListState> {
  @override
  RbacPermissionListState build() {
    final permissionsAsync = ref.watch(rbacPermissionsStreamProvider);
    final rolesAsync = ref.watch(rolesStreamProvider);
    final modulesAsync = ref.watch(rbacModulesStreamProvider);

    if (permissionsAsync.isLoading ||
        rolesAsync.isLoading ||
        modulesAsync.isLoading) {
      return const RbacPermissionListState(isLoading: true);
    }

    if (permissionsAsync.hasError ||
        rolesAsync.hasError ||
        modulesAsync.hasError) {
      return RbacPermissionListState(
        isLoading: false,
        error: 'Error loading RBAC data',
      );
    }

    final permissions = permissionsAsync.value ?? [];
    final roles = rolesAsync.value ?? [];
    final modules = modulesAsync.value ?? [];

    final Map<String, String> rNames = {};
    for (var r in roles) {
      if (r.roleId != null) rNames[r.roleId!] = r.roleName;
    }

    final Map<String, String> mNames = {};
    for (var m in modules) {
      if (m.moduleId != null) mNames[m.moduleId!] = m.moduleName;
    }

    final Map<String, List<ModelRbacPermission>> grouped = {};
    for (final role in roles) {
      if (role.roleId == null) continue;
      final roleId = role.roleId!;
      final List<ModelRbacPermission> rolePermissions = [];

      for (final module in modules) {
        if (module.moduleId == null) continue;
        final moduleId = module.moduleId!;

        final existing = permissions.firstWhere(
          (p) => p.roleId == roleId && p.moduleId == moduleId,
          orElse: () => ModelRbacPermission(
            roleId: roleId,
            moduleId: moduleId,
            canRead: false,
            canCreate: false,
            canUpdate: false,
            canDelete: false,
          ),
        );
        rolePermissions.add(existing);
      }
      grouped[roleId] = rolePermissions;
    }

    return RbacPermissionListState(
      isLoading: false,
      permissionsByRole: grouped,
      roleNames: rNames,
      moduleNames: mNames,
      error: null,
    );
  }

  Future<bool> updatePermission(
    ModelRbacPermission permission,
    String field,
    bool value,
  ) async {
    try {
      final service = ref.read(rbacPermissionServiceProvider);

      final updated = permission.copyWith(
        canRead: field == 'can_read' ? value : permission.canRead,
        canCreate: field == 'can_create' ? value : permission.canCreate,
        canUpdate: field == 'can_update' ? value : permission.canUpdate,
        canDelete: field == 'can_delete' ? value : permission.canDelete,
      );

      if (permission.permissionId == null) {
        await service.create(updated);
      } else {
        await service.update(permission.permissionId!, updated);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final rbacPermissionListControllerProvider =
    NotifierProvider.autoDispose<
      RbacPermissionListController,
      RbacPermissionListState
    >(() => RbacPermissionListController());
