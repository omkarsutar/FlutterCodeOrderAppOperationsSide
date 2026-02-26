import '../../../../core/services/entity_service.dart';
import '../model/rbac_module_model.dart';

class RbacModuleMapper implements EntityMapper<ModelRbacModule> {
  @override
  ModelRbacModule fromMap(Map<String, dynamic> map) {
    return ModelRbacModule.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelRbacModule entity) {
    return entity.toMap();
  }
}
