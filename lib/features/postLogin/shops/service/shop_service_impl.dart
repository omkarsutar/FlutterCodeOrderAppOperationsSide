import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_items/po_item_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/purchase_order_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/route_shop_links/route_shop_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/config/field_config.dart';
import '../model/shop_model.dart';
import 'package:async/async.dart';

class ShopServiceImpl extends ForeignKeyAwareService<ModelShop> {
  final EntityMapper<ModelShop> _mapper;

  ShopServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelShop> get mapper => _mapper;

  @override
  String get tableName => ModelShopFields.table;

  @override
  String get idColumn => ModelShopFields.shopId;
  @override
  String get createdAt => ModelShopFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelShopFields.shopsPrimaryRoute: ForeignKeyConfig(
      table: ModelRouteFields.table,
      idColumn: ModelRouteFields.routeId,
      labelColumn: ModelRouteFields.routeName,
    ),
  };

  // --- Custom helpers ---

  /// Fetch all shops linked to a user's preferred route
  Future<List<ModelShop>> fetchAllShopsForPreferredRoute(
    String? preferredRouteId,
  ) async {
    if (preferredRouteId == null || preferredRouteId.isEmpty) {
      throw Exception('Preferred route not set for user');
    }

    final linkData = await client
        .from(ModelRouteShopLinkFields.table)
        .select(idColumn)
        .eq(ModelRouteShopLinkFields.routeId, preferredRouteId);

    final shopIds = List<String>.from(linkData.map((e) => e[idColumn]));
    if (shopIds.isEmpty) return [];

    // Use view_shops instead of manual relational query
    final shops = await client
        .from(ModelShopFields.tableViewWithForeignKeyLabels)
        .select('*')
        .inFilter(idColumn, shopIds);

    return List<Map<String, dynamic>>.from(
      shops,
    ).map((shop) => mapper.fromMap(shop)).toList();
  }

  // In your service:
  Stream<Map<String, List<ModelShop>>> streamShopsByPOItemStatus(
    String preferredRouteId,
  ) async* {
    // Supabase live streams
    final poStream = client
        .from(ModelPurchaseOrderFields.table)
        .stream(primaryKey: [ModelPurchaseOrderFields.poId])
        .eq(ModelPurchaseOrderFields.poRouteId, preferredRouteId);

    final poItemStream = client
        .from(ModelPoItemFields.table)
        .stream(primaryKey: [ModelPoItemFields.poItemId]);

    // Merge both streams into one
    final merged = StreamGroup.merge([poStream, poItemStream]);

    await for (final _ in merged) {
      final result = await fetchShopsByPOItemStatus(
        preferredRouteId: preferredRouteId,
      );
      yield result;
    }
  }

  /// Classify shops by purchase order item status for today
  Future<Map<String, List<ModelShop>>> fetchShopsByPOItemStatus({
    required String? preferredRouteId,
  }) async {
    if (preferredRouteId == null || preferredRouteId.isEmpty) {
      throw Exception('Preferred route not set for user');
    }

    // Step 1: Get shop_ids linked to preferred_route_id in route order
    final linkData = await client
        .from(ModelRouteShopLinkFields.table)
        .select(ModelRouteShopLinkFields.shopId)
        .eq(ModelRouteShopLinkFields.routeId, preferredRouteId)
        .order(ModelRouteShopLinkFields.visitOrder, ascending: true);

    final shopIdsInRouteOrder = List<String>.from(
      linkData.map((e) => e[ModelRouteShopLinkFields.shopId]),
    );

    if (shopIdsInRouteOrder.isEmpty) {
      return {'noPOs': [], 'emptyPOs': [], 'filledPOs': []};
    }

    final nowLocal = DateTime.now(); // IST
    final startOfDayLocal = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );
    final endOfDayLocal = startOfDayLocal.add(const Duration(days: 1));

    final startUtc = startOfDayLocal.toUtc();
    final endUtc = endOfDayLocal.toUtc();

    final poData = await client
        .from(ModelPurchaseOrderFields.table)
        .select(
          '${ModelPurchaseOrderFields.poId}, ${ModelPurchaseOrderFields.poShopId}',
        )
        .inFilter(ModelPurchaseOrderFields.poShopId, shopIdsInRouteOrder)
        .gte(ModelPurchaseOrderFields.createdAt, startUtc.toIso8601String())
        .lt(ModelPurchaseOrderFields.createdAt, endUtc.toIso8601String());

    final poByShop = <String, List<String>>{};
    for (final po in poData) {
      final shopId = po[ModelPurchaseOrderFields.poShopId];
      final poId = po[ModelPurchaseOrderFields.poId];
      poByShop.putIfAbsent(shopId, () => []).add(poId);
    }

    // Step 3: Get po_item counts for today's POs
    final allPoIds = poData
        .map((e) => e[ModelPurchaseOrderFields.poId])
        .toList();
    final poItems = await client
        .from(ModelPoItemFields.table)
        .select(ModelPoItemFields.poId)
        .inFilter(ModelPoItemFields.poId, allPoIds);

    final poIdsWithItems = Set<String>.from(
      poItems.map((e) => e[ModelPoItemFields.poId]),
    );

    // Step 4: Classify shops
    final shopsWithFilledPOs = <String>{};
    final shopsWithEmptyPOs = <String>{};

    poByShop.forEach((shopId, poIds) {
      final hasFilled = poIds.any((poId) => poIdsWithItems.contains(poId));
      if (hasFilled) {
        shopsWithFilledPOs.add(shopId);
      } else {
        shopsWithEmptyPOs.add(shopId);
      }
    });

    final shopsWithPOs = shopsWithFilledPOs.union(shopsWithEmptyPOs);
    final shopsWithNoPOs = shopIdsInRouteOrder
        .where((id) => !shopsWithPOs.contains(id))
        .toSet();

    // Step 5: Fetch shop details and sort by route order
    Future<List<ModelShop>> fetchShops(Set<String> ids) async {
      if (ids.isEmpty) return [];
      final result = await client
          .from(ModelShopFields.tableViewWithForeignKeyLabels)
          .select('*')
          .inFilter(ModelShopFields.shopId, ids.toList());

      final shops = List<Map<String, dynamic>>.from(
        result,
      ).map((map) => ModelShop.fromMap(map)).toList();

      return sortShopsByRouteOrder(
        shops: shops,
        shopIdsInRouteOrder: shopIdsInRouteOrder,
      );
    }

    return {
      'noPOs': await fetchShops(shopsWithNoPOs),
      'emptyPOs': await fetchShops(shopsWithEmptyPOs),
      'filledPOs': await fetchShops(shopsWithFilledPOs),
    };
  }

  Future<List<String>> fetchRouteShopIds(String routeId) async {
    final linkData = await client
        .from(ModelRouteShopLinkFields.table)
        .select(ModelRouteShopLinkFields.shopId)
        .eq(ModelRouteShopLinkFields.routeId, routeId)
        .order(ModelRouteShopLinkFields.visitOrder, ascending: true);

    return List<String>.from(
      linkData.map((e) => e[ModelRouteShopLinkFields.shopId]),
    );
  }

  /// Sort shops according to the route order defined in ModelRouteShopLinkFields
  List<ModelShop> sortShopsByRouteOrder({
    required List<ModelShop> shops,
    required List<String> shopIdsInRouteOrder,
  }) {
    shops.sort((a, b) {
      final aId = a.shopId ?? ''; // fallback if null
      final bId = b.shopId ?? '';
      final aIndex = shopIdsInRouteOrder.indexOf(aId);
      final bIndex = shopIdsInRouteOrder.indexOf(bId);
      return aIndex.compareTo(bIndex);
    });
    return shops;
  }

  Future<List<ModelShop>> fetchAllShopsForRoute(String routeId) async {
    // 1) Get route-linked shop IDs in visit order
    final linkData = await client
        .from(ModelRouteShopLinkFields.table)
        .select(ModelRouteShopLinkFields.shopId)
        .eq(ModelRouteShopLinkFields.routeId, routeId)
        .order(ModelRouteShopLinkFields.visitOrder, ascending: true);

    final shopIdsInRouteOrder = List<String>.from(
      linkData.map((e) => e[ModelRouteShopLinkFields.shopId]),
    );

    if (shopIdsInRouteOrder.isEmpty) return [];

    // 2) Fetch shops via view
    final result = await client
        .from(ModelShopFields.tableViewWithForeignKeyLabels)
        .select('*')
        .inFilter(ModelShopFields.shopId, shopIdsInRouteOrder);

    final shops = List<Map<String, dynamic>>.from(
      result,
    ).map((map) => ModelShop.fromMap(map)).toList();

    // 3) Sort by route order (stable and consistent)
    return sortShopsByRouteOrder(
      shops: shops,
      shopIdsInRouteOrder: shopIdsInRouteOrder,
    );
  }

  /// Fetch shops for preferred route filtered by whether they have POs today
  Future<List<Map<String, dynamic>>> fetchShopsForPreferredRouteByPOStatus({
    required String? preferredRouteId,
    required bool hasPOsToday,
  }) async {
    if (preferredRouteId == null || preferredRouteId.isEmpty) {
      throw Exception('Preferred route not set for user');
    }

    // Step 1: Get shop_ids linked to preferred_route_id
    final linkData = await client
        .from(ModelRouteShopLinkFields.table)
        .select(idColumn)
        .eq(ModelRouteShopLinkFields.routeId, preferredRouteId);

    final shopIds = List<String>.from(linkData.map((e) => e[idColumn]));

    if (shopIds.isEmpty) return [];

    // Step 2: Get shop_ids that HAVE purchase orders today
    final nowUtc = DateTime.now().toUtc();
    final startOfDayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final endOfDayUtc = startOfDayUtc.add(Duration(days: 1));

    final purchaseOrders = await client
        .from(ModelPurchaseOrderFields.table)
        .select(ModelPurchaseOrderFields.poShopId)
        .inFilter(ModelPurchaseOrderFields.poShopId, shopIds)
        .gte(
          ModelPurchaseOrderFields.createdAt,
          startOfDayUtc.toIso8601String(),
        )
        .lt(ModelPurchaseOrderFields.createdAt, endOfDayUtc.toIso8601String());

    final shopsWithPOsToday = Set<String>.from(
      purchaseOrders.map((e) => e[ModelPurchaseOrderFields.poShopId]),
    );

    // Step 3: Filter shopIds based on PO status
    final filteredShopIds = hasPOsToday
        ? shopIds.where((id) => shopsWithPOsToday.contains(id)).toList()
        : shopIds.where((id) => !shopsWithPOsToday.contains(id)).toList();

    if (filteredShopIds.isEmpty) return [];

    // Step 4: Fetch shops with those filtered shop_ids
    final shops = await client
        .from(tableName)
        .select('*')
        .inFilter(idColumn, filteredShopIds);

    return List<Map<String, dynamic>>.from(shops);
  }

  // --- Legacy methods delegate to new ones ---
  Future<List<ModelShop>> getAllEntities() async => await fetchAll();

  /* Future<ModelShop> fetchShopById(String shopId) async {
    final entity = await fetchById(shopId);
    if (entity == null) throw Exception('Shop not found');
    return entity;
  } */

  // --- Override generic methods to use view ---

  @override
  Stream<List<ModelShop>> streamEntities() {
    final controller = StreamController<List<ModelShop>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelShopFields.tableViewWithForeignKeyLabels)
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
  Future<List<ModelShop>> fetchAll() async {
    final response = await client
        .from(ModelShopFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return (response as List).map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelShop> fetchById(String id) async {
    final response = await client
        .from(ModelShopFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(idColumn, id)
        .single();
    return mapper.fromMap(response);
  }

  /// Fetches a simplified list of shops with only id and name for dropdowns
  Future<List<Map<String, dynamic>>> getShopsForDropdown() async {
    print("inside getShopsForDropdown()");
    try {
      final response = await client
          .from(ModelShopFields.table)
          .select('${ModelShopFields.shopId}, ${ModelShopFields.shopName}')
          .order(ModelShopFields.shopName, ascending: true);

      // Convert to the format expected by dropdowns
      return (response as List).map((shop) {
        return {
          'shop_id': shop[ModelShopFields.shopId],
          'shop_name': shop[ModelShopFields.shopName],
        };
      }).toList();
    } catch (e) {
      // Handle error appropriately
      rethrow;
    }
  }

  @override
  Future<ModelShop> getEntityById(String id) async => await fetchById(id);

  @override
  Future<void> insertEntity(ModelShop entity) async => await create(entity);

  @override
  Future<void> updateEntity(String id, ModelShop entity) async =>
      await update(id, entity);

  @override
  Future<void> deleteEntityById(String id) async => await delete(id);
}
