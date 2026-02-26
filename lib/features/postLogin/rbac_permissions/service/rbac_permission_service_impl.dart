import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_modules/rbac_module_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/roles/role_barrel.dart';

import '../../../../core/services/logger_service.dart';
import '../../../../core/config/field_config.dart';
import '../../../../core/services/entity_service.dart';
import '../model/rbac_permission_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RbacPermissionServiceImpl
    extends ForeignKeyAwareService<ModelRbacPermission> {
  final EntityMapper<ModelRbacPermission> _mapper;

  RbacPermissionServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelRbacPermission> get mapper => _mapper;

  @override
  String get tableName => ModelRbacPermissionFields.table;

  @override
  String get idColumn => ModelRbacPermissionFields.permissionId;
  @override
  String get createdAt => ModelRbacPermissionFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelRbacPermissionFields.roleId: ForeignKeyConfig(
      table: ModelRoleFields.table,
      idColumn: ModelRoleFields.roleId,
      labelColumn: ModelRoleFields.roleName,
    ),
    ModelRbacPermissionFields.moduleId: ForeignKeyConfig(
      table: ModelRbacModuleFields.table,
      idColumn: ModelRbacModuleFields.moduleId,
      labelColumn: ModelRbacModuleFields.moduleName,
    ),
  };

  @override
  Future<ModelRbacPermission?> fetchById(String id) async {
    try {
      // Use the view that includes foreign key labels
      final raw = await client
          .from(ModelRbacPermissionFields.tableViewWithForeignKeyLabels)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      if (raw == null) {
        return null;
      }

      // The view already contains the labels, so we don't need resolveForeignLabelsForSingle
      return mapper.fromMap(raw);
    } catch (e) {
      rethrow;
    }
  }

  /// Override streamEntities to use the view for better performance
  @override
  Stream<List<ModelRbacPermission>> streamEntities() {
    final controller = StreamController<List<ModelRbacPermission>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelRbacPermissionFields.tableViewWithForeignKeyLabels)
            .select()
            .order(sortField ?? createdAt, ascending: sortAscending);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (_) => fetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  /// Override fetchAll to use the view for better performance
  @override
  Future<List<ModelRbacPermission>> fetchAll() async {
    final response = await client
        .from(ModelRbacPermissionFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return (response as List).map((e) => mapper.fromMap(e)).toList();
  }
}
