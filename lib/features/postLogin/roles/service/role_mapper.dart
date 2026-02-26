import '../../../../core/services/entity_service.dart';
import '../model/role_model.dart';

class RoleMapper implements EntityMapper<ModelRole> {
  @override
  ModelRole fromMap(Map<String, dynamic> map) {
    return ModelRole.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelRole entity) {
    return entity.toMap();
  }
}
