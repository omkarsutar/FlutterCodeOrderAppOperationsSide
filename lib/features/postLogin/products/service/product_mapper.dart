import '../../../../core/services/entity_service.dart';
import '../model/product_model.dart';

class ProductMapper implements EntityMapper<ModelProduct> {
  @override
  ModelProduct fromMap(Map<String, dynamic> map) {
    return ModelProduct.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelProduct entity) {
    return entity.toMap();
  }
}
