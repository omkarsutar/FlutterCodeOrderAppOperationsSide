import '../../../../core/services/entity_service.dart';
import '../model/route_shop_link_model.dart';

class RouteShopLinkMapper implements EntityMapper<ModelRouteShopLink> {
  @override
  ModelRouteShopLink fromMap(Map<String, dynamic> map) {
    return ModelRouteShopLink.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelRouteShopLink entity) {
    return entity.toMap();
  }
}
