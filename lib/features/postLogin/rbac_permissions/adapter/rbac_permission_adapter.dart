import '../../../../core/services/entity_service.dart';
import '../model/rbac_permission_model.dart';

class RbacPermissionAdapter implements EntityAdapter<ModelRbacPermission> {
  @override
  dynamic getFieldValue(ModelRbacPermission entity, String fieldName) {
    switch (fieldName) {
      case ModelRbacPermissionFields.permissionId:
        return entity.permissionId;
      case ModelRbacPermissionFields.roleId:
        return entity.roleId;
      case ModelRbacPermissionFields.moduleId:
        return entity.moduleId;
      case ModelRbacPermissionFields.canRead:
        return entity.canRead;
      case ModelRbacPermissionFields.canCreate:
        return entity.canCreate;
      case ModelRbacPermissionFields.canUpdate:
        return entity.canUpdate;
      case ModelRbacPermissionFields.canDelete:
        return entity.canDelete;
      case ModelRbacPermissionFields.createdAt:
        return entity.createdAt;
      case ModelRbacPermissionFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelRbacPermission entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  @override
  dynamic getId(ModelRbacPermission entity, String idField) =>
      entity.permissionId;

  @override
  dynamic getTimestamp(ModelRbacPermission entity, String timestampField) {
    return entity.createdAt;
  }
}
