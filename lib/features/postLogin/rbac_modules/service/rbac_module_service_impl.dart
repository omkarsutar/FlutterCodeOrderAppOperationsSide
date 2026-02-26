import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/supabase_entity_service.dart';
import '../model/rbac_module_model.dart';

class RbacModuleServiceImpl extends SupabaseEntityService<ModelRbacModule> {
  final EntityMapper<ModelRbacModule> _mapper;

  RbacModuleServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelRbacModule> get mapper => _mapper;

  @override
  String get entityTypeName => 'ModelRbacModule';

  @override
  String get tableName => ModelRbacModuleFields.table;

  @override
  String get idColumn => ModelRbacModuleFields.moduleId;
  @override
  String get createdAt => ModelRbacModuleFields.createdAt;

  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final modules = await fetchAll();
    return modules.map((m) => mapper.toMap(m)).toList();
  }
}
