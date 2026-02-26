import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/shop_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/field_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/entity_service.dart';
import '../model/purchase_order_model.dart';

import '../../../../core/config/module_config.dart';

class PurchaseOrderServiceImpl
    extends ForeignKeyAwareService<ModelPurchaseOrder> {
  final EntityMapper<ModelPurchaseOrder> _mapper;
  final Ref _ref;

  PurchaseOrderServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
    this._ref, {
    SortingConfig? initialSorting,
  }) : super(client, logger) {
    if (initialSorting != null) {
      sortField = initialSorting.field;
      sortAscending = initialSorting.sortAscending;
    } else {
      /* sortField = ModelPurchaseOrderFields.createdAt;
      sortAscending = false; */
    }
  }

  @override
  EntityMapper<ModelPurchaseOrder> get mapper => _mapper;

  @override
  String get tableName => ModelPurchaseOrderFields.table;

  @override
  String get idColumn => ModelPurchaseOrderFields.poId;
  @override
  String get createdAt => ModelPurchaseOrderFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelPurchaseOrderFields.poRouteId: ForeignKeyConfig(
      table: ModelRouteFields.table,
      idColumn: ModelRouteFields.routeId,
      labelColumn: ModelRouteFields.routeName,
    ),
    ModelPurchaseOrderFields.poShopId: ForeignKeyConfig(
      table: ModelShopFields.table,
      idColumn: ModelShopFields.shopId,
      labelColumn: ModelShopFields.shopName,
    ),
    ModelPurchaseOrderFields.createdBy: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
    ModelPurchaseOrderFields.updatedBy: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
  };

  // --- Custom helpers ---

  /// Create an empty purchase order for a given route and shop
  Future<Map<String, dynamic>> createEmptyPurchaseOrder({
    required String poRouteId,
    required String poShopId,
  }) async {
    final userId = _ref.read(userProfileStateProvider).profile?.userId;
    if (userId == null) throw Exception('No signed-in user found');

    final entity = ModelPurchaseOrder(
      poTotalAmount: 0.0,
      poLineItemCount: 0,
      poRouteId: poRouteId,
      poShopId: poShopId,
      userComment: null,
      profitToShop: null,
      poLat: null,
      poLong: null,
      status: null,
      createdBy: userId,
      updatedBy: userId,
    );

    final enriched = mapper.toMap(entity);
    final response = await client
        .from(tableName)
        .insert(enriched)
        .select()
        .single();
    return response;
  }

  /// Fetch all purchase orders for a given shop
  Future<List<Map<String, dynamic>>> fetchPurchaseOrdersForShop(
    String? selectedShopId,
  ) async {
    if (selectedShopId == null || selectedShopId.isEmpty) {
      throw Exception('Shop ID not provided');
    }

    final purchaseOrders = await client
        .from(ModelPurchaseOrderFields.tableViewWithForeignKeyLabels)
        .select('*')
        .eq(ModelPurchaseOrderFields.poShopId, selectedShopId);

    return List<Map<String, dynamic>>.from(purchaseOrders);
  }

  /// Convenience method to get raw maps instead of typed entities
  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final response = await client
        .from(tableName)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Stream purchase orders filtered by route
  Stream<List<ModelPurchaseOrder>> streamEntitiesByRoute(String routeId) {
    final controller = StreamController<List<ModelPurchaseOrder>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelPurchaseOrderFields.tableViewWithForeignKeyLabels)
            .select()
            .eq(ModelPurchaseOrderFields.poRouteId, routeId)
            .order(sortField ?? createdAt, ascending: sortAscending);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName:$routeId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: ModelPurchaseOrderFields.poRouteId,
            value: routeId,
          ),
          callback: (_) => fetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  /// Fetch purchase orders for a given shop with foreign labels resolved
  Future<List<Map<String, dynamic>>> fetchEntitiesByShop(String shopId) async {
    final List<dynamic> result = await client
        .from(ModelPurchaseOrderFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(ModelPurchaseOrderFields.poShopId, shopId)
        .order(sortField ?? createdAt, ascending: sortAscending);

    return List<Map<String, dynamic>>.from(result);
  }

  // --- Override generic methods to use view ---

  @override
  Stream<List<ModelPurchaseOrder>> streamEntities() {
    final controller = StreamController<List<ModelPurchaseOrder>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelPurchaseOrderFields.tableViewWithForeignKeyLabels)
            .select()
            .order(sortField ?? createdAt, ascending: sortAscending);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (_) => fetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  @override
  Future<List<ModelPurchaseOrder>> fetchAll() async {
    final response = await client
        .from(ModelPurchaseOrderFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return (response as List).map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelPurchaseOrder> fetchById(String id) async {
    final response = await client
        .from(ModelPurchaseOrderFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(idColumn, id)
        .single();
    return mapper.fromMap(response);
  }

  // --- Override insertEntity to enrich with createdBy/updatedBy ---
  @override
  Future<void> insertEntity(ModelPurchaseOrder entity) async {
    final userId = _ref.read(userProfileStateProvider).profile?.userId;
    if (userId == null) throw Exception('No signed-in user found');

    final enriched = mapper.toMap(entity);
    enriched[ModelPurchaseOrderFields.createdBy] = userId;
    enriched[ModelPurchaseOrderFields.updatedBy] = userId;

    await client.from(tableName).insert(enriched);
  }
}
