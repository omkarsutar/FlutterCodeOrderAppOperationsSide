import '../../../../core/services/entity_service.dart';
import '../model/shop_model.dart';

class ShopMapper implements EntityMapper<ModelShop> {
  @override
  ModelShop fromMap(Map<String, dynamic> map) {
    return ModelShop.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelShop entity) {
    return entity.toMap();
  }
}
