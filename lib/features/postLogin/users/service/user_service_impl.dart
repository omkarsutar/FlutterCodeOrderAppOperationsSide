import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../roles/role_barrel.dart';
import '../../routes/route_barrel.dart';
import '../model/user_model.dart';

class UserServiceImpl extends ForeignKeyAwareService<ModelUser> {
  final EntityMapper<ModelUser> _mapper;

  UserServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelUser> get mapper => _mapper;

  @override
  String get tableName => ModelUserFields.table;

  @override
  String get idColumn => ModelUserFields.userId;
  @override
  String get createdAt => ModelUserFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelUserFields.roleId: ForeignKeyConfig(
      table: ModelRoleFields.table,
      idColumn: ModelRoleFields.roleId,
      labelColumn: ModelRoleFields.roleName,
    ),
    ModelUserFields.preferredRouteId: ForeignKeyConfig(
      table: ModelRouteFields.table,
      idColumn: ModelRouteFields.routeId,
      labelColumn: ModelRouteFields.routeName,
    ),
  };

  @override
  Stream<List<ModelUser>> streamEntities() {
    final controller = StreamController<List<ModelUser>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelUserFields.tableViewWithForeignKeyLabels)
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

  @override
  Future<List<ModelUser>> fetchAll() async {
    final List<dynamic> data = await client
        .from(ModelUserFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);

    return data.map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelUser?> fetchById(String id) async {
    try {
      // Use the view that includes foreign key labels
      final raw = await client
          .from(ModelUserFields.tableViewWithForeignKeyLabels)
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
}
