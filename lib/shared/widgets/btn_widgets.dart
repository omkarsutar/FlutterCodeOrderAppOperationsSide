import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/entity_service.dart';
import '../../core/utils/dialogs.dart';
import '../../core/utils/snackbar_utils.dart';

class CreateEntityButton extends ConsumerWidget {
  final String moduleName;
  final String newRouteName;
  final String entityLabel;
  final Map<String, String>? pathParameters;
  final Map<String, dynamic>? queryParameters;

  const CreateEntityButton({
    super.key,
    required this.moduleName,
    required this.newRouteName,
    required this.entityLabel,
    this.pathParameters,
    this.queryParameters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitialized = ref.watch(rbacInitializationProvider);
    if (!isInitialized) return const SizedBox.shrink();

    final rbacService = ref.watch(rbacServiceProvider);
    final canCreate = rbacService.canCreate(moduleName);

    if (!canCreate) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: () => context.pushNamed(
        newRouteName,
        pathParameters: pathParameters ?? {},
        queryParameters: queryParameters ?? {},
      ),
      tooltip: 'Add a ${entityLabel.toLowerCase()}',
      child: const Icon(Icons.add),
    );
  }
}

class DeleteEntityButton<T> extends ConsumerWidget {
  final String moduleName; // e.g. "orders", "routes"
  final String entityLabel; // e.g. "Order"
  final String entityLabelLower; // e.g. "order"
  final EntityService<T> entityService; // service to delete entity
  final EntityAdapter<T> adapter; // adapter to extract id
  final T entity; // the entity instance
  final String idField; // id field name

  const DeleteEntityButton({
    super.key,
    required this.moduleName,
    required this.entityLabel,
    required this.entityLabelLower,
    required this.entityService,
    required this.adapter,
    required this.entity,
    required this.idField,
  });

  Future<void> _deleteEntity(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete $entityLabel',
      content: 'Are you sure you want to delete this $entityLabel?',
      confirmLabel: 'Delete',
    );

    if (confirmed) {
      try {
        await entityService.deleteEntityById(adapter.getId(entity, idField));
        SnackbarUtils.showSuccess('$entityLabel deleted!');
      } catch (e, stackTrace) {
        debugPrint(stackTrace.toString());
        SnackbarUtils.showError('Failed to delete $entityLabelLower.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitialized = ref.watch(rbacInitializationProvider);
    if (!isInitialized) return const SizedBox.shrink();

    final rbacService = ref.watch(rbacServiceProvider);
    final canDelete = rbacService.canDelete(moduleName);

    if (!canDelete) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.delete, color: Color(0xFFE53935)),
      onPressed: () => _deleteEntity(context),
    );
  }
}

class EditEntityButton<T> extends ConsumerWidget {
  final String moduleName; // e.g. "orders", "routes"
  final String entityLabel; // e.g. "Order"
  final EntityAdapter<T> adapter; // adapter to extract id
  final T entity; // the entity instance
  final String idField; // id field name
  final String editRouteName; // route name for edit page
  final String? parentId; // optional parentId for queryParameters

  const EditEntityButton({
    super.key,
    required this.moduleName,
    required this.entityLabel,
    required this.adapter,
    required this.entity,
    required this.idField,
    required this.editRouteName,
    this.parentId,
  });

  void _navigateToEdit(BuildContext context) {
    final pathParams = {'id': adapter.getId(entity, idField).toString()};

    final queryParams = <String, String>{};
    if (parentId != null) {
      queryParams['parentId'] = parentId!;
    }

    context.pushNamed(
      editRouteName,
      pathParameters: pathParams,
      queryParameters: queryParams,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitialized = ref.watch(rbacInitializationProvider);
    if (!isInitialized) return const SizedBox.shrink();

    final rbacService = ref.watch(rbacServiceProvider);
    final canUpdate = rbacService.canUpdate(moduleName);

    if (!canUpdate) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      tooltip: 'Edit $entityLabel',
      onPressed: () => _navigateToEdit(context),
    );
  }
}
