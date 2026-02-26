import '../../../../core/services/entity_service.dart';
import '../model/shop_model.dart';

class ShopAdapter implements EntityAdapter<ModelShop> {
  @override
  dynamic getFieldValue(ModelShop entity, String fieldName) {
    switch (fieldName) {
      case ModelShopFields.shopId:
        return entity.shopId;
      case ModelShopFields.shopName:
        return entity.shopName;
      case ModelShopFields.shopsPrimaryRoute:
        return entity.shopsPrimaryRoute;
      case ModelShopFields.shopNote:
        return entity.shopNote;
      case ModelShopFields.hiddenNote:
        return entity.hiddenNote;
      case ModelShopFields.shopMobile1:
        return entity.shopMobile1;
      case ModelShopFields.shopMobile2:
        return entity.shopMobile2;
      case ModelShopFields.shopPersonName:
        return entity.shopPersonName;
      case ModelShopFields.isActive:
        return entity.isActive;
      case ModelShopFields.shopLocationUrl:
        return entity.shopLocationUrl;
      case ModelShopFields.shopLandmark:
        return entity.shopLandmark;
      case ModelShopFields.shopAddress:
        return entity.shopAddress;
      case ModelShopFields.shopPhotoId:
        return entity.shopPhotoId;
      case ModelShopFields.shopPhotoUrl:
        return entity.shopPhotoUrl;
      case ModelShopFields.shopLat:
        return entity.shopLat;
      case ModelShopFields.shopLong:
        return entity.shopLong;
      case ModelShopFields.createdAt:
        return entity.createdAt;
      case ModelShopFields.updatedAt:
        return entity.updatedAt;
      case ModelShopFields.visitOrder:
        return entity.visitOrder;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelShop entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  /* @override
  dynamic getLabelValue(ModelShop entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getId(ModelShop entity, String idField) => entity.shopId;

  @override
  dynamic getTimestamp(ModelShop entity, String timestampField) {
    return entity.createdAt;
  }
}
