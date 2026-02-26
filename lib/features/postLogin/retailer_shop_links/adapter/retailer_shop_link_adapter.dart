import '../../../../core/services/entity_service.dart';
import '../model/retailer_shop_link_model.dart';

class RetailerShopLinkAdapter extends EntityAdapter<ModelRetailerShopLink> {
  @override
  String getId(ModelRetailerShopLink entity, String idField) => entity.linkId;

  @override
  dynamic getFieldValue(ModelRetailerShopLink entity, String fieldName) {
    switch (fieldName) {
      case ModelRetailerShopLinkFields.linkId:
        return entity.linkId;
      case ModelRetailerShopLinkFields.userId:
        return entity.userId;
      case ModelRetailerShopLinkFields.shopId:
        return entity.shopId;
      case ModelRetailerShopLinkFields.createdAt:
        return entity.createdAt;
      case ModelRetailerShopLinkFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelRetailerShopLink entity, String fieldName) {
    if (fieldName == 'user_role')
      return entity.resolvedLabels['user_role_label'];
    if (fieldName == 'shop_route')
      return entity.resolvedLabels['shop_route_label'];

    if (fieldName.endsWith('_id')) {
      final labelKey = '${fieldName}_label';
      return entity.resolvedLabels[labelKey];
    }
    return null;
  }

  @override
  DateTime? getTimestamp(ModelRetailerShopLink entity, String timestampField) {
    if (timestampField == ModelRetailerShopLinkFields.createdAt) {
      return entity.createdAt;
    }
    if (timestampField == ModelRetailerShopLinkFields.updatedAt) {
      return entity.updatedAt;
    }
    return null;
  }

  /// Returns the title to display in the UI (e.g., list tile)
  String getTitle(ModelRetailerShopLink entity) {
    // Show "User Name -> Shop Name" or fallback
    final userName = entity.resolvedLabels['user_id_label'] ?? entity.userId;
    final shopName = entity.resolvedLabels['shop_id_label'] ?? entity.shopId;
    return '$userName -> $shopName';
  }

  /// Returns the subtitle to display in the UI
  String? getSubtitle(ModelRetailerShopLink entity) {
    return 'Created: ${entity.createdAt?.toString().split(' ')[0] ?? 'N/A'}';
  }

  /// Returns the leading widget (avatar/icon)
  String? getLeading(ModelRetailerShopLink entity) {
    return null; // Default icon will be used
  }
}
