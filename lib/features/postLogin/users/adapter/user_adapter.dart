import '../../../../core/services/entity_service.dart';
import '../model/user_model.dart';

class UserAdapter implements EntityAdapter<ModelUser> {
  @override
  dynamic getFieldValue(ModelUser entity, String fieldName) {
    switch (fieldName) {
      case ModelUserFields.userId:
        return entity.userId;
      case ModelUserFields.fullName:
        return entity.fullName;
      case ModelUserFields.roleId:
        return entity.roleId;
      case ModelUserFields.preferredRouteId:
        return entity.preferredRouteId;
      case ModelUserFields.createdAt:
        return entity.createdAt;
      case ModelUserFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  /* @override
  dynamic getLabelValue(ModelUser entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getLabelValue(ModelUser entity, String fieldName) {
    switch (fieldName) {
      case ModelUserFields.roleId:
      case ModelUserFields.preferredRouteId:
        return entity.resolvedLabels['${fieldName}_label'];
      case ModelUserFields.createdAt:
        return _formatDate(entity.createdAt);
      case ModelUserFields.updatedAt:
        return _formatDate(entity.updatedAt);
      default:
        return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  dynamic getId(ModelUser entity, String idField) => entity.userId;

  @override
  dynamic getTimestamp(ModelUser entity, String timestampField) {
    return entity.createdAt;
  }
}
