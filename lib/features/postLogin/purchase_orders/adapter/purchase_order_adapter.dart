import '../../../../core/services/entity_service.dart';
import '../model/purchase_order_model.dart';

class PurchaseOrderAdapter implements EntityAdapter<ModelPurchaseOrder> {
  @override
  dynamic getFieldValue(ModelPurchaseOrder entity, String fieldName) {
    switch (fieldName) {
      case ModelPurchaseOrderFields.poId:
        return entity.poId;
      case ModelPurchaseOrderFields.poTotalAmount:
        return entity.poTotalAmount;
      case ModelPurchaseOrderFields.poLineItemCount:
        return entity.poLineItemCount;
      case ModelPurchaseOrderFields.poRouteId:
        return entity.poRouteId;
      case ModelPurchaseOrderFields.poShopId:
        return entity.poShopId;
      case ModelPurchaseOrderFields.userComment:
        return entity.userComment;
      case ModelPurchaseOrderFields.profitToShop:
        return entity.profitToShop;
      case ModelPurchaseOrderFields.poLat:
        return entity.poLat;
      case ModelPurchaseOrderFields.poLong:
        return entity.poLong;
      case ModelPurchaseOrderFields.status:
        return entity.status;
      case ModelPurchaseOrderFields.createdBy:
        return entity.createdBy;
      case ModelPurchaseOrderFields.updatedBy:
        return entity.updatedBy;
      case ModelPurchaseOrderFields.createdAt:
        return entity.createdAt;
      case ModelPurchaseOrderFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  /* @override
  dynamic getLabelValue(ModelPurchaseOrder entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getLabelValue(ModelPurchaseOrder entity, String fieldName) {
    if (entity.resolvedLabels.containsKey('${fieldName}_label')) {
      return entity.resolvedLabels['${fieldName}_label'];
    }
    switch (fieldName) {
      case ModelPurchaseOrderFields.poRouteId:
      case ModelPurchaseOrderFields.poShopId:
      case ModelPurchaseOrderFields.createdBy:
      case ModelPurchaseOrderFields.updatedBy:
        return entity.resolvedLabels['${fieldName}_label'];
      case ModelPurchaseOrderFields.status:
        return entity.status ?? 'Pending';
      default:
        return null;
    }
  }

  @override
  dynamic getId(ModelPurchaseOrder entity, String idField) => entity.poId;

  @override
  dynamic getTimestamp(ModelPurchaseOrder entity, String timestampField) {
    return entity.createdAt;
  }
}
