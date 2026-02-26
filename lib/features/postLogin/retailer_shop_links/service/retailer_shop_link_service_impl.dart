import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../shops/shop_barrel.dart';
import '../../users/user_barrel.dart';
import '../model/retailer_shop_link_model.dart';

class RetailerShopLinkServiceImpl
    extends ForeignKeyAwareService<ModelRetailerShopLink> {
  final EntityMapper<ModelRetailerShopLink> _mapper;

  RetailerShopLinkServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelRetailerShopLink> get mapper => _mapper;

  @override
  String get tableName => ModelRetailerShopLinkFields.table;

  @override
  String? get viewName =>
      ModelRetailerShopLinkFields.tableViewWithForeignKeyLabels;

  @override
  String get idColumn => ModelRetailerShopLinkFields.linkId;

  @override
  String get createdAt => ModelRetailerShopLinkFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelRetailerShopLinkFields.userId: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
    ModelRetailerShopLinkFields.shopId: ForeignKeyConfig(
      table: ModelShopFields.table,
      idColumn: ModelShopFields.shopId,
      labelColumn: ModelShopFields.shopName,
    ),
  };
}
