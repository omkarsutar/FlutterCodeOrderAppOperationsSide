import '../../../../core/services/entity_service.dart';
import '../model/route_model.dart';

class RouteMapper implements EntityMapper<ModelRoute> {
  @override
  ModelRoute fromMap(Map<String, dynamic> map) {
    return ModelRoute.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelRoute entity) {
    return entity.toMap();
  }
}
