import '../../../../core/services/entity_service.dart';

class ModelRetailerShopLinkFields {
  static const String table = 'retailer_shop_link';
  static const String tableViewWithForeignKeyLabels = 'view_retailer_shop_link';

  static const String linkId = 'link_id';
  static const String userId = 'user_id';
  static const String shopId = 'shop_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
}

class ModelRetailerShopLink {
  final String linkId; // PK
  final String userId; // FK
  final String shopId; // FK
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final Map<String, dynamic> _resolvedLabels;

  ModelRetailerShopLink({
    required this.linkId,
    required this.userId,
    required this.shopId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  factory ModelRetailerShopLink.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelRetailerShopLink(
      linkId: map[ModelRetailerShopLinkFields.linkId].toString(),
      userId: map[ModelRetailerShopLinkFields.userId].toString(),
      shopId: map[ModelRetailerShopLinkFields.shopId].toString(),
      createdAt: _parseDate(map[ModelRetailerShopLinkFields.createdAt]),
      updatedAt: _parseDate(map[ModelRetailerShopLinkFields.updatedAt]),
      createdBy: map[ModelRetailerShopLinkFields.createdBy]?.toString(),
      updatedBy: map[ModelRetailerShopLinkFields.updatedBy]?.toString(),
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (linkId.isNotEmpty && linkId != 'null')
        ModelRetailerShopLinkFields.linkId: linkId,
      ModelRetailerShopLinkFields.userId: userId,
      ModelRetailerShopLinkFields.shopId: shopId,
      if (createdAt != null)
        ModelRetailerShopLinkFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelRetailerShopLinkFields.updatedAt: updatedAt!.toIso8601String(),
      if (createdBy != null) ModelRetailerShopLinkFields.createdBy: createdBy,
      if (updatedBy != null) ModelRetailerShopLinkFields.updatedBy: updatedBy,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class ModelRetailerShopLinkMapper
    implements EntityMapper<ModelRetailerShopLink> {
  @override
  ModelRetailerShopLink fromMap(Map<String, dynamic> map) =>
      ModelRetailerShopLink.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelRetailerShopLink entity) => entity.toMap();
}
