import '../../../../core/services/entity_service.dart';
import '../model/purchase_order_model.dart';

class PurchaseOrderMapper implements EntityMapper<ModelPurchaseOrder> {
  @override
  ModelPurchaseOrder fromMap(Map<String, dynamic> map) {
    return ModelPurchaseOrder.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelPurchaseOrder entity) {
    return entity.toMap();
  }
}
