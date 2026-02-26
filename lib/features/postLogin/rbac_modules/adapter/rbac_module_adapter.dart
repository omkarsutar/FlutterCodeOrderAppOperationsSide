import '../../../../core/services/entity_service.dart';
import '../model/rbac_module_model.dart';

class RbacModuleAdapter implements EntityAdapter<ModelRbacModule> {
  @override
  dynamic getFieldValue(ModelRbacModule entity, String fieldName) {
    switch (fieldName) {
      case ModelRbacModuleFields.moduleId:
        return entity.moduleId;
      case ModelRbacModuleFields.moduleName:
        return entity.moduleName;
      case ModelRbacModuleFields.moduleDescription:
        return entity.moduleDescription;
      case ModelRbacModuleFields.createdAt:
        return entity.createdAt;
      case ModelRbacModuleFields.updatedAt:
        return entity.updatedAt;
      case ModelRbacModuleFields.isActive:
        return entity.isActive;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelRbacModule entity, String fieldName) {
    return null; // or custom label logic
  }

  @override
  dynamic getId(ModelRbacModule entity, String idField) => entity.moduleId;

  @override
  dynamic getTimestamp(ModelRbacModule entity, String timestampField) {
    return entity.createdAt;
  }
}
