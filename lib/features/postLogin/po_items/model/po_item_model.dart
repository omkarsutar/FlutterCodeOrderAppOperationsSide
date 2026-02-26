import '../../../../core/services/entity_service.dart';

class ModelPoItemFields {
  static const String table = 'po_item';
  static const String tableViewWithForeignKeyLabels = 'view_po_items';

  static const String poItemId = 'po_item_id';
  static const String poId = 'po_id';
  static const String productId = 'product_id';
  static const String itemName = 'item_name';
  static const String itemQty = 'item_qty';
  static const String itemSellRate = 'item_sell_rate';
  static const String itemPrice = 'item_price';
  static const String itemUnitMrp = 'item_unit_mrp';
  static const String profitToShop = 'profit_to_shop';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const Map<String, String> labels = {
    poItemId: 'PO Item',
    poId: 'PO',
    productId: 'Product',
    itemName: 'Item Name',
    itemQty: 'Quantity',
    itemSellRate: 'Sell Rate',
    itemPrice: 'Price',
    itemUnitMrp: 'Unit MRP',
    profitToShop: 'Profit to Shop',
    createdBy: 'Created By',
    updatedBy: 'Updated By',
    createdAt: 'Created At',
    updatedAt: 'Updated At',
  };

  static String getLabel(String field) => labels[field] ?? field;
}

class ModelPoItem {
  final String? poItemId;
  final String? poId;
  final String? productId;
  final String? itemName;
  final double? itemQty; // changed from int? to double?
  final double? itemSellRate;
  final double? itemPrice;
  final double? itemUnitMrp;
  final double? profitToShop;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> _resolvedLabels;

  ModelPoItem({
    this.poItemId,
    this.poId,
    this.productId,
    this.itemName,
    required this.itemQty, // enforce non-null
    this.itemSellRate,
    this.itemPrice,
    this.itemUnitMrp,
    this.profitToShop,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  ModelPoItem copyWith({
    String? poItemId,
    String? poId,
    String? productId,
    String? itemName,
    double? itemQty,
    double? itemSellRate,
    double? itemPrice,
    double? itemUnitMrp,
    double? profitToShop,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? resolvedLabels,
  }) {
    return ModelPoItem(
      poItemId: poItemId ?? this.poItemId,
      poId: poId ?? this.poId,
      productId: productId ?? this.productId,
      itemName: itemName ?? this.itemName,
      itemQty: itemQty ?? this.itemQty,
      itemSellRate: itemSellRate ?? this.itemSellRate,
      itemPrice: itemPrice ?? this.itemPrice,
      itemUnitMrp: itemUnitMrp ?? this.itemUnitMrp,
      profitToShop: profitToShop ?? this.profitToShop,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedLabels: resolvedLabels ?? this.resolvedLabels,
    );
  }

  factory ModelPoItem.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelPoItem(
      poItemId: map[ModelPoItemFields.poItemId]?.toString(),
      poId: map[ModelPoItemFields.poId]?.toString(),
      productId: map[ModelPoItemFields.productId]?.toString(),
      itemName: map[ModelPoItemFields.itemName]?.toString(),
      itemQty: map[ModelPoItemFields.itemQty] != null
          ? double.tryParse(map[ModelPoItemFields.itemQty].toString())
          : null, // parse as double
      itemSellRate: map[ModelPoItemFields.itemSellRate] != null
          ? double.tryParse(map[ModelPoItemFields.itemSellRate].toString())
          : null,
      itemPrice: map[ModelPoItemFields.itemPrice] != null
          ? double.tryParse(map[ModelPoItemFields.itemPrice].toString())
          : null,
      itemUnitMrp: map[ModelPoItemFields.itemUnitMrp] != null
          ? double.tryParse(map[ModelPoItemFields.itemUnitMrp].toString())
          : null,
      profitToShop: map[ModelPoItemFields.profitToShop] != null
          ? double.tryParse(map[ModelPoItemFields.profitToShop].toString())
          : null,
      createdBy: map[ModelPoItemFields.createdBy]?.toString(),
      updatedBy: map[ModelPoItemFields.updatedBy]?.toString(),
      createdAt: map[ModelPoItemFields.createdAt] != null
          ? DateTime.tryParse(map[ModelPoItemFields.createdAt].toString())
          : null,
      updatedAt: map[ModelPoItemFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelPoItemFields.updatedAt].toString())
          : null,
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (poItemId != null) map[ModelPoItemFields.poItemId] = poItemId;
    if (poId != null) map[ModelPoItemFields.poId] = poId;
    if (productId != null) map[ModelPoItemFields.productId] = productId;
    // if (itemName != null) map[ModelPoItemFields.itemName] = itemName;
    if (itemQty != null) map[ModelPoItemFields.itemQty] = itemQty; // double
    if (itemSellRate != null)
      map[ModelPoItemFields.itemSellRate] = itemSellRate;
    if (itemPrice != null) map[ModelPoItemFields.itemPrice] = itemPrice;
    // if (itemUnitMrp != null) map[ModelPoItemFields.itemUnitMrp] = itemUnitMrp;
    if (profitToShop != null)
      map[ModelPoItemFields.profitToShop] = profitToShop;
    if (createdBy != null) map[ModelPoItemFields.createdBy] = createdBy;
    if (updatedBy != null) map[ModelPoItemFields.updatedBy] = updatedBy;
    if (createdAt != null)
      map[ModelPoItemFields.createdAt] = createdAt!.toIso8601String();
    if (updatedAt != null)
      map[ModelPoItemFields.updatedAt] = updatedAt!.toIso8601String();

    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'poItemId': poItemId,
      'poId': poId,
      'itemName': itemName,
      'itemQty': itemQty,
      'itemSellRate': itemSellRate,
      'itemPrice': itemPrice,
      'itemUnitMrp': itemUnitMrp,
      'profitToShop': profitToShop,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'productId': productId,
    };
  }

  factory ModelPoItem.fromJson(Map<String, dynamic> json) {
    return ModelPoItem(
      poItemId: json['poItemId'] as String?,
      poId: json['poId'] as String?,
      itemName: json['itemName'] as String?,
      itemQty: (json['itemQty'] as num).toDouble(),
      itemSellRate: (json['itemSellRate'] as num).toDouble(),
      itemPrice: (json['itemPrice'] as num).toDouble(),
      itemUnitMrp: (json['itemUnitMrp'] as num?)?.toDouble(),
      profitToShop: (json['profitToShop'] as num?)?.toDouble(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      productId: json['productId'] as String?,
    );
  }
}

class ModelPoItemMapper implements EntityMapper<ModelPoItem> {
  @override
  ModelPoItem fromMap(Map<String, dynamic> map) => ModelPoItem.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelPoItem entity) => entity.toMap();
}
