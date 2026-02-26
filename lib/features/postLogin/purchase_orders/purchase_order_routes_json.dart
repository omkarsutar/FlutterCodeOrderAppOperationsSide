import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/purchase_order_list_byShopID.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/route_permission.dart';
import '../../../core/services/rbac_service.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/purchase_order_model.dart';
import 'providers/purchase_order_providers.dart';
import 'ui/purchase_order_list_tile.dart';
import 'ui/purchase_order_list_page_riverpod.dart';

/// JSON-based route generation for Purchase Orders module
/// Fully migrated to Riverpod - no GetIt dependency
/// Strategy: Listen to purchase_order table, read from view_purchase_orders
/// Real-time sync enabled via Supabase Realtime subscriptions
class PurchaseOrdersRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/purchase_orders/purchase_order_config.json',
    );

    // Cache the configuration so providers can access it
    PurchaseOrderConfigCache.config = _config;

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelPurchaseOrder>>((
      ref,
    ) {
      return ref.watch(purchaseOrderServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelPurchaseOrder>>((
      ref,
    ) {
      return ref.watch(purchaseOrderAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method
    // This ensures it's set on the correct Riverpod provider service instance

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelPurchaseOrder>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: purchaseOrdersStreamProvider,
      entityByIdProvider: purchaseOrderByIdProvider,
      formProvider: purchaseOrderFormProvider,
      customItemBuilder: (context, entity, adapter, onTap) {
        return PurchaseOrderListTile(
          entity: entity,
          adapter: adapter,
          onTap: onTap,
        );
      },
      customListBuilder: (context, state) {
        final filterShopId = state.uri.queryParameters['filterShopId'];

        if (filterShopId != null) {
          return PurchaseOrderListByShopID(
            entityMeta: _config.entityMeta,
            idField: _config.table.idField,
            fieldConfigs: _config.fields,
            timestampField: _config.table.timestampField,
            viewRouteName: _config.routes.viewRouteName,
            newRouteName: _config.routes.newRouteName,
            rbacModule: _config.table.name,
            searchFields: _config.listPage?.searchFields,
            initialSorting: _config.listPage?.sorting,
          );
        }

        return PurchaseOrderListPageRiverpod(
          entityMeta: _config.entityMeta,
          idField: _config.table.idField,
          fieldConfigs: _config.fields,
          timestampField: _config.table.timestampField,
          viewRouteName: _config.routes.viewRouteName,
          newRouteName: _config.routes.newRouteName,
          rbacModule: _config.table.name,
          searchFields: _config.listPage?.searchFields,
          initialSorting: _config.listPage?.sorting,
        );
      },
    );

    // Register manual routes for RBAC
    ModuleRouteRegistry.registerRoutePermission(
      'purchase_order_collection',
      RoutePermission(moduleId: 'purchase_order', action: RbacAction.update),
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'PurchaseOrderRoutesJson not initialized. Call initialize() first.',
      );
    }
    return ModuleRouteRegistry.routes
        .where((route) => route.path.startsWith(_config.routes.basePath))
        .toList();
  }

  /// Helper properties to access route names
  static String get listRouteName => _config.routes.listRouteName;
  static String get newRouteName => _config.routes.newRouteName;
  static String get editRouteName => _config.routes.editRouteName;
  static String get viewRouteName => _config.routes.viewRouteName;

  /// Route paths
  static String get purchaseOrders => _config.routes.listPath;
  static String get newPurchaseOrder => _config.routes.newPath;
  static String editPurchaseOrderRoute(String id) =>
      _config.routes.editRoute(id);
  static String viewPurchaseOrderRoute(String id) =>
      _config.routes.viewRoute(id);

  /* /// Helper methods to generate route paths
  static String get listPath => _config.routes.basePath;
  static String newPath() => '${_config.routes.basePath}/new';
  static String editPath(String poId) =>
      '${_config.routes.basePath}/$poId/edit';
  static String viewPath(String poId) => '${_config.routes.basePath}/$poId'; */
}
