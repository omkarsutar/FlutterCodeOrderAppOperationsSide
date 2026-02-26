import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/shared_widget_barrel.dart';
import '../rbac_permission_barrel.dart';

class RbacPermissionListPageRiverpod extends ConsumerWidget {
  final String entityLabel;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;

  const RbacPermissionListPageRiverpod({
    super.key,
    required this.entityLabel,
    required this.viewRouteName,
    required this.newRouteName,
    required this.rbacModule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rbacPermissionListControllerProvider);
    final controller = ref.read(rbacPermissionListControllerProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(title: '${entityLabel}s', showBack: false),
      drawer: const CustomDrawer(),
      body: _buildBody(state, controller, context),
      floatingActionButton: CreateEntityButton(
        moduleName: rbacModule,
        newRouteName:
            newRouteName, // This allows adding a fresh permission if needed
        entityLabel: entityLabel,
      ),
    );
  }

  Widget _buildBody(
    RbacPermissionListState state,
    RbacPermissionListController controller,
    BuildContext context,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (state.permissionsByRole.isEmpty) {
      return const Center(child: Text('No permissions found.'));
    }

    final roleIds = state.permissionsByRole.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: roleIds.length,
      itemBuilder: (context, index) {
        final roleId = roleIds[index];
        final roleName = state.roleNames[roleId] ?? 'Unknown Role ($roleId)';
        final permissions = state.permissionsByRole[roleId] ?? [];

        return _RolePermissionCard(
          roleId: roleId,
          roleName: roleName,
          permissions: permissions,
          moduleNames: state.moduleNames,
          controller: controller,
        );
      },
    );
  }
}

class _RolePermissionCard extends StatelessWidget {
  final String roleId;
  final String roleName;
  final List<ModelRbacPermission> permissions;
  final Map<String, String> moduleNames;
  final RbacPermissionListController controller;

  const _RolePermissionCard({
    required this.roleId,
    required this.roleName,
    required this.permissions,
    required this.moduleNames,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role Header
            Text(
              roleName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            _buildHeaderRow(context),
            const Divider(height: 8),

            // Permission Rows
            ...permissions.map((permission) {
              final moduleName =
                  moduleNames[permission.moduleId] ??
                  'Unknown Module (${permission.moduleId})';

              return _PermissionRow(
                permission: permission,
                moduleName: moduleName,
                controller: controller,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.grey[700],
    );

    return Row(
      children: [
        Expanded(flex: 2, child: Text('Module', style: labelStyle)),
        // R C U D
        ...['Read', 'Create', 'Update', 'Delete'].map(
          (label) => Expanded(
            flex: 1,
            child: Center(child: Text(label, style: labelStyle)),
          ),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final ModelRbacPermission permission;
  final String moduleName;
  final RbacPermissionListController controller;

  const _PermissionRow({
    required this.permission,
    required this.moduleName,
    required this.controller,
  });

  Future<void> _update(BuildContext context, String field, bool value) async {
    final success = await controller.updatePermission(permission, field, value);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update permission')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Module
          Expanded(
            flex: 2,
            child: Text(
              moduleName,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Switches
          Expanded(
            flex: 1,
            child: _buildSwitch(context, 'can_read', permission.canRead),
          ),
          Expanded(
            flex: 1,
            child: _buildSwitch(context, 'can_create', permission.canCreate),
          ),
          Expanded(
            flex: 1,
            child: _buildSwitch(context, 'can_update', permission.canUpdate),
          ),
          Expanded(
            flex: 1,
            child: _buildSwitch(context, 'can_delete', permission.canDelete),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(BuildContext context, String field, bool value) {
    return Center(
      child: Transform.scale(
        scale: 0.7,
        child: Switch(
          value: value,
          onChanged: (newValue) => _update(context, field, newValue),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
