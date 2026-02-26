import '../../../../core/services/entity_service.dart';
import '../model/po_item_model.dart';

class PoItemAdapter implements EntityAdapter<ModelPoItem> {
  @override
  dynamic getFieldValue(ModelPoItem entity, String fieldName) {
    switch (fieldName) {
      case ModelPoItemFields.poItemId:
        return entity.poItemId;
      case ModelPoItemFields.poId:
        return entity.poId;
      case ModelPoItemFields.productId:
        return entity.productId;
      case ModelPoItemFields.itemName:
        return entity.itemName;
      case ModelPoItemFields.itemQty:
        return entity.itemQty;
      case ModelPoItemFields.itemSellRate:
        return entity.itemSellRate;
      case ModelPoItemFields.itemPrice:
        return entity.itemPrice;
      case ModelPoItemFields.itemUnitMrp:
        return entity.itemUnitMrp;
      case ModelPoItemFields.profitToShop:
        return entity.profitToShop;
      case ModelPoItemFields.createdBy:
        return entity.createdBy;
      case ModelPoItemFields.updatedBy:
        return entity.updatedBy;
      case ModelPoItemFields.createdAt:
        return entity.createdAt;
      case ModelPoItemFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelPoItem entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  /* @override
  dynamic getLabelValue(ModelPoItem entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getId(ModelPoItem entity, String idField) => entity.poItemId;

  @override
  dynamic getTimestamp(ModelPoItem entity, String timestampField) {
    return entity.createdAt;
  }
}
