import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/shop_barrel.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/config/module_config.dart';
import '../model/route_shop_link_model.dart';

abstract class RouteFilteredEntityService<T> {
  Stream<List<T>> streamEntitiesByRoute(String routeId);
}

class RouteShopLinkServiceImpl
    extends ForeignKeyAwareService<ModelRouteShopLink>
    implements RouteFilteredEntityService<ModelRouteShopLink> {
  final EntityMapper<ModelRouteShopLink> _mapper;

  RouteShopLinkServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger, {
    SortingConfig? initialSorting,
  }) : super(client, logger) {
    if (initialSorting != null) {
      sortField = initialSorting.field;
      sortAscending = initialSorting.sortAscending;
    } else {
      /* sortField = ModelRouteShopLinkFields.visitOrder;
      sortAscending = true; */
    }
  }

  @override
  EntityMapper<ModelRouteShopLink> get mapper => _mapper;

  @override
  String get tableName => ModelRouteShopLinkFields.table;

  @override
  String get idColumn => ModelRouteShopLinkFields.linkId;

  @override
  String get createdAt => ModelRouteShopLinkFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelRouteShopLinkFields.routeId: ForeignKeyConfig(
      table: ModelRouteFields.table,
      idColumn: ModelRouteFields.routeId,
      labelColumn: ModelRouteFields.routeName,
    ),
    ModelRouteShopLinkFields.shopId: ForeignKeyConfig(
      table: ModelShopFields.table,
      idColumn: ModelShopFields.shopId,
      labelColumn: ModelShopFields.shopName,
      // Add this to use the optimized dropdown method
      fetchDropdownItems: (service) =>
          (service as ShopServiceImpl).getShopsForDropdown(),
    ),
  };

  @override
  Future<List<ModelRouteShopLink>> fetchAll() async {
    final List<dynamic> data = await client
        .from(ModelRouteShopLinkFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);

    return data.map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelRouteShopLink?> fetchById(String id) async {
    try {
      // Use the view that includes foreign key labels
      final raw = await client
          .from(ModelRouteShopLinkFields.tableViewWithForeignKeyLabels)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      if (raw == null) {
        return null;
      }

      // The view already contains the labels, so we don't need resolveForeignLabelsForSingle
      return mapper.fromMap(raw);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<ModelRouteShopLink>> streamEntities() {
    final controller = StreamController<List<ModelRouteShopLink>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelRouteShopLinkFields.tableViewWithForeignKeyLabels)
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

  // --- Custom helper: stream links filtered by route ---
  @override
  Stream<List<ModelRouteShopLink>> streamEntitiesByRoute(String routeId) {
    final controller = StreamController<List<ModelRouteShopLink>>();
    RealtimeChannel? channel;
    Timer? debounceTimer;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelRouteShopLinkFields.tableViewWithForeignKeyLabels)
            .select()
            .eq(ModelRouteShopLinkFields.routeId, routeId)
            .order(sortField ?? createdAt, ascending: sortAscending);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void debouncedFetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 500), () {
        fetch();
      });
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: ModelRouteShopLinkFields.routeId,
            value: routeId,
          ),
          callback: (_) => debouncedFetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  /* /// Fetches route shop links using the 'view_route_shop_links' View
  Future<List<ModelRouteShopLink>> fetchByRouteId(String routeId) async {
    // It is a View, so we query it like a table
    final List<dynamic> data = await client
        .from(ModelRouteShopLinkFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(ModelRouteShopLinkFields.routeId, routeId)
        .order(ModelRouteShopLinkFields.visitOrder, ascending: true);

    return data.map((e) => mapper.fromMap(e)).toList();
  } */

  /// Reorders route shop links using server-side function
  /// Returns the updated list of links for the route
  Future<void> reorderRouteShopLink(String linkId, int newPosition) async {
    await client.rpc(
      'reorder_route_shop_links',
      params: {'p_link_id': linkId, 'p_new_position': newPosition},
    );
  }
}
