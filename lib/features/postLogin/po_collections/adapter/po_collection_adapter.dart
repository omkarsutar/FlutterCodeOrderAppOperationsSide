import '../../../../core/services/entity_service.dart';
import '../model/po_collection_model.dart';

class PoCollectionAdapter implements EntityAdapter<ModelPoCollection> {
  @override
  dynamic getFieldValue(ModelPoCollection entity, String fieldName) {
    switch (fieldName) {
      case ModelPoCollectionFields.collectionId:
        return entity.collectionId;
      case ModelPoCollectionFields.poId:
        return entity.poId;
      case ModelPoCollectionFields.collectedAmount:
        return entity.collectedAmount;
      case ModelPoCollectionFields.isCash:
        return entity.isCash;
      case ModelPoCollectionFields.isOnline:
        return entity.isOnline;
      case ModelPoCollectionFields.isCheque:
        return entity.isCheque;
      case ModelPoCollectionFields.chequeNo:
        return entity.chequeNo;
      case ModelPoCollectionFields.isSign:
        return entity.isSign;
      case ModelPoCollectionFields.signAmount:
        return entity.signAmount;
      case ModelPoCollectionFields.comments:
        return entity.comments;
      case ModelPoCollectionFields.createdAt:
        return entity.createdAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelPoCollection entity, String fieldName) {
    final value = getFieldValue(entity, fieldName);
    if (value == null) return '';

    if (fieldName == ModelPoCollectionFields.collectedAmount ||
        fieldName == ModelPoCollectionFields.signAmount) {
      return '₹ $value';
    }

    if (value is bool) {
      return value ? 'Yes' : 'No';
    }

    return value.toString();
  }

  @override
  dynamic getId(ModelPoCollection entity, String idField) {
    if (idField == ModelPoCollectionFields.collectionId) {
      return entity.collectionId;
    }
    if (idField == ModelPoCollectionFields.poId) {
      return entity.poId;
    }
    return null;
  }

  @override
  dynamic getTimestamp(ModelPoCollection entity, String timestampField) {
    if (timestampField == ModelPoCollectionFields.createdAt) {
      return entity.createdAt;
    }
    return null;
  }
}
