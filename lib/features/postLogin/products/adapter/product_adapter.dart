import '../../../../core/services/entity_service.dart';
import '../model/product_model.dart';

class ProductAdapter implements EntityAdapter<ModelProduct> {
  @override
  dynamic getFieldValue(ModelProduct entity, String fieldName) {
    switch (fieldName) {
      case ModelProductFields.productId:
        return entity.productId;
      case ModelProductFields.productType:
        return entity.productType;
      case ModelProductFields.productName:
        return entity.productName;
      case ModelProductFields.productWeightValue:
        return entity.productWeightValue;
      case ModelProductFields.productWeightUnit:
        return entity.productWeightUnit;
      case ModelProductFields.purchaseRateForRetailer:
        return entity.purchaseRateForRetailer;
      case ModelProductFields.mrp:
        return entity.mrp;
      case ModelProductFields.packagingType:
        return entity.packagingType;
      case ModelProductFields.piecesPerOuter:
        return entity.piecesPerOuter;
      case ModelProductFields.isOuter:
        return entity.isOuter;
      case ModelProductFields.isActive:
        return entity.isActive;
      case ModelProductFields.isAvailable:
        return entity.isAvailable;
      case ModelProductFields.qtyInDecimal:
        return entity.qtyInDecimal;
      case ModelProductFields.productImage:
        return entity.productImage;
      case ModelProductFields.createdBy:
        return entity.createdBy;
      case ModelProductFields.updatedBy:
        return entity.updatedBy;
      case ModelProductFields.createdAt:
        return entity.createdAt;
      case ModelProductFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  /* @override
  dynamic getLabelValue(ModelProduct entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getLabelValue(ModelProduct entity, String fieldName) {
    switch (fieldName) {
      case ModelProductFields.createdAt:
        return _formatDate(entity.createdAt);
      case ModelProductFields.updatedAt:
        return _formatDate(entity.updatedAt);
      case ModelProductFields.isOuter:
      case ModelProductFields.isActive:
      case ModelProductFields.isAvailable:
        return (getFieldValue(entity, fieldName) == true) ? 'Yes' : 'No';
      default:
        return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  dynamic getId(ModelProduct entity, String idField) => entity.productId;

  @override
  dynamic getTimestamp(ModelProduct entity, String timestampField) {
    return entity.createdAt;
  }
}
