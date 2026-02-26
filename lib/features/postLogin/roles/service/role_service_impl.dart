import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../model/role_model.dart';

class RoleServiceImpl extends SupabaseEntityService<ModelRole> {
  final EntityMapper<ModelRole> _mapper;

  RoleServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelRole> get mapper => _mapper;

  @override
  String get entityTypeName => 'ModelRole';

  @override
  String get tableName => ModelRoleFields.table;

  @override
  String get idColumn => ModelRoleFields.roleId;
  @override
  String get createdAt => ModelRoleFields.createdAt;

  // --- Convenience methods ---

  /// Get raw maps instead of typed entities
  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final roles = await fetchAll(); // uses LoggingEntityService wrapper
    return roles.map((r) => mapper.toMap(r)).toList();
  }
}
