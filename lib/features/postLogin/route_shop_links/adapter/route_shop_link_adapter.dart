import '../../../../core/services/entity_service.dart';
import '../model/route_shop_link_model.dart';

class RouteShopLinkAdapter implements EntityAdapter<ModelRouteShopLink> {
  @override
  dynamic getFieldValue(ModelRouteShopLink entity, String fieldName) {
    switch (fieldName) {
      case ModelRouteShopLinkFields.linkId:
        return entity.linkId;
      case ModelRouteShopLinkFields.routeId:
        return entity.routeId;
      case ModelRouteShopLinkFields.shopId:
        return entity.shopId;
      case ModelRouteShopLinkFields.visitOrder:
        return entity.visitOrder;
      case ModelRouteShopLinkFields.createdAt:
        return entity.createdAt;
      case ModelRouteShopLinkFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelRouteShopLink entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  /* @override
  dynamic getLabelValue(ModelRouteShopLink entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getId(ModelRouteShopLink entity, String idField) => entity.linkId;

  @override
  dynamic getTimestamp(ModelRouteShopLink entity, String timestampField) {
    return entity.createdAt;
  }
}
