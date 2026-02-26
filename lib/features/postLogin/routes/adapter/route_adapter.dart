import '../../../../core/services/entity_service.dart';
import '../model/route_model.dart';

class RouteAdapter implements EntityAdapter<ModelRoute> {
  @override
  dynamic getFieldValue(ModelRoute entity, String fieldName) {
    switch (fieldName) {
      case ModelRouteFields.routeId:
        return entity.routeId;
      case ModelRouteFields.routeName:
        return entity.routeName;
      case ModelRouteFields.routeNote:
        return entity.routeNote;
      case ModelRouteFields.isActive:
        return entity.isActive;
      case ModelRouteFields.createdAt:
        return entity.createdAt;
      case ModelRouteFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelRoute entity, String fieldName) {
    switch (fieldName) {
      case ModelRouteFields.isActive:
        return entity.isActive ? 'Active' : 'Inactive';
      case ModelRouteFields.createdAt:
        return _formatDate(entity.createdAt);
      case ModelRouteFields.updatedAt:
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
  dynamic getId(ModelRoute entity, String idField) => entity.routeId;

  @override
  dynamic getTimestamp(ModelRoute entity, String timestampField) {
    return entity.createdAt;
  }
}
