import '../../../../core/services/entity_service.dart';
import '../model/role_model.dart';

class RoleAdapter implements EntityAdapter<ModelRole> {
  @override
  dynamic getFieldValue(ModelRole entity, String fieldName) {
    switch (fieldName) {
      case ModelRoleFields.roleId:
        return entity.roleId;
      case ModelRoleFields.roleName:
        return entity.roleName;
      case ModelRoleFields.roleDescription: // ✅ renamed
        return entity.roleDescription;
      case ModelRoleFields.createdAt:
        return entity.createdAt;
      case ModelRoleFields.updatedAt:
        return entity.updatedAt;
      case ModelRoleFields.isActive: // ✅ new
        return entity.isActive;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelRole entity, String fieldName) {
    return null; // or custom label logic
  }

  @override
  dynamic getId(ModelRole entity, String idField) => entity.roleId;

  @override
  dynamic getTimestamp(ModelRole entity, String timestampField) {
    return entity.createdAt;
  }
}
