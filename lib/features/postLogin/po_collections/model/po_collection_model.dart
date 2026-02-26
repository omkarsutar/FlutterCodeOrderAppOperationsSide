import '../../../../core/services/entity_service.dart';

class ModelPoCollectionFields {
  static const String table = 'po_collections';
  static const String tableViewWithForeignKeyLabels = 'view_po_collections';
  static const String collectionId = 'collection_id';
  static const String poId = 'po_id';
  static const String collectedAmount = 'collected_amount';
  static const String isCash = 'is_cash';
  static const String isOnline = 'is_online';
  static const String isCheque = 'is_cheque';
  static const String chequeNo = 'cheque_no';
  static const String isSign = 'is_sign';
  static const String signAmount = 'sign_amount';
  static const String comments = 'comments';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
}

class ModelPoCollection {
  final String? collectionId;
  final String poId;
  final double collectedAmount;
  final bool isCash;
  final bool isOnline;
  final bool isCheque;
  final String? chequeNo;
  final bool isSign;
  final double? signAmount;
  final String? comments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  // From View
  final String? poStatusLabel;
  final String? shopIdLabel;
  final String? routeIdLabel;
  final String? createdByLabel;
  final String? updatedByLabel;
  final DateTime? poUpdatedAt;

  ModelPoCollection({
    this.collectionId,
    required this.poId,
    this.collectedAmount = 0.0,
    this.isCash = false,
    this.isOnline = false,
    this.isCheque = false,
    this.chequeNo,
    this.isSign = false,
    this.signAmount = 0.0,
    this.comments,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.poStatusLabel,
    this.shopIdLabel,
    this.routeIdLabel,
    this.createdByLabel,
    this.updatedByLabel,
    this.poUpdatedAt,
  });

  ModelPoCollection copyWith({
    String? collectionId,
    String? poId,
    double? collectedAmount,
    bool? isCash,
    bool? isOnline,
    bool? isCheque,
    String? chequeNo,
    bool? isSign,
    double? signAmount,
    String? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? poStatusLabel,
    String? shopIdLabel,
    String? routeIdLabel,
    String? createdByLabel,
    String? updatedByLabel,
    DateTime? poUpdatedAt,
  }) {
    return ModelPoCollection(
      collectionId: collectionId ?? this.collectionId,
      poId: poId ?? this.poId,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      isCash: isCash ?? this.isCash,
      isOnline: isOnline ?? this.isOnline,
      isCheque: isCheque ?? this.isCheque,
      chequeNo: chequeNo ?? this.chequeNo,
      isSign: isSign ?? this.isSign,
      signAmount: signAmount ?? this.signAmount,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      poStatusLabel: poStatusLabel ?? this.poStatusLabel,
      shopIdLabel: shopIdLabel ?? this.shopIdLabel,
      routeIdLabel: routeIdLabel ?? this.routeIdLabel,
      createdByLabel: createdByLabel ?? this.createdByLabel,
      updatedByLabel: updatedByLabel ?? this.updatedByLabel,
      poUpdatedAt: poUpdatedAt ?? this.poUpdatedAt,
    );
  }

  factory ModelPoCollection.fromMap(Map<String, dynamic> map) {
    return ModelPoCollection(
      collectionId: map[ModelPoCollectionFields.collectionId],
      poId: map[ModelPoCollectionFields.poId],
      collectedAmount: (map[ModelPoCollectionFields.collectedAmount] ?? 0.0)
          .toDouble(),
      isCash: map[ModelPoCollectionFields.isCash] ?? false,
      isOnline: map[ModelPoCollectionFields.isOnline] ?? false,
      isCheque: map[ModelPoCollectionFields.isCheque] ?? false,
      chequeNo: map[ModelPoCollectionFields.chequeNo],
      isSign: map[ModelPoCollectionFields.isSign] ?? false,
      signAmount: (map[ModelPoCollectionFields.signAmount] ?? 0.0).toDouble(),
      comments: map[ModelPoCollectionFields.comments],
      createdAt: map[ModelPoCollectionFields.createdAt] != null
          ? DateTime.parse(map[ModelPoCollectionFields.createdAt])
          : null,
      updatedAt: map[ModelPoCollectionFields.updatedAt] != null
          ? DateTime.parse(map[ModelPoCollectionFields.updatedAt])
          : null,
      createdBy: map[ModelPoCollectionFields.createdBy],
      updatedBy: map[ModelPoCollectionFields.updatedBy],
      poStatusLabel: map['po_status_label'],
      shopIdLabel: map['shop_id_label'],
      routeIdLabel: map['route_id_label'],
      createdByLabel: map['created_by_label'],
      updatedByLabel: map['updated_by_label'],
      poUpdatedAt: map['po_updated_at'] != null
          ? DateTime.tryParse(map['po_updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (collectionId != null)
        ModelPoCollectionFields.collectionId: collectionId,
      ModelPoCollectionFields.poId: poId,
      ModelPoCollectionFields.collectedAmount: collectedAmount,
      ModelPoCollectionFields.isCash: isCash,
      ModelPoCollectionFields.isOnline: isOnline,
      ModelPoCollectionFields.isCheque: isCheque,
      ModelPoCollectionFields.chequeNo: chequeNo,
      ModelPoCollectionFields.isSign: isSign,
      ModelPoCollectionFields.signAmount: signAmount,
      ModelPoCollectionFields.comments: comments,
      if (createdBy != null) ModelPoCollectionFields.createdBy: createdBy,
      if (updatedBy != null) ModelPoCollectionFields.updatedBy: updatedBy,
    };
  }
}

class ModelPoCollectionMapper extends EntityMapper<ModelPoCollection> {
  @override
  ModelPoCollection fromMap(Map<String, dynamic> map) =>
      ModelPoCollection.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelPoCollection entity) => entity.toMap();
}
