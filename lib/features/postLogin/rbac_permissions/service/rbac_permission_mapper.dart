import '../../../../core/services/entity_service.dart';
import '../model/rbac_permission_model.dart';

class RbacPermissionMapper implements EntityMapper<ModelRbacPermission> {
  @override
  ModelRbacPermission fromMap(Map<String, dynamic> map) {
    return ModelRbacPermission.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelRbacPermission entity) {
    return entity.toMap();
  }
}
