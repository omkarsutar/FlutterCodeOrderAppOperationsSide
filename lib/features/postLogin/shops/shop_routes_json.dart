import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/shop_model.dart';
import 'providers/shop_providers.dart';

import 'ui/shop_list_page_riverpod.dart';
import 'ui/shop_list_tile.dart';

/// JSON-based route generation for Shops module
class ShopsRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/shops/shop_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelShop>>((ref) {
      return ref.watch(shopServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelShop>>((ref) {
      return ref.watch(shopAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelShop>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: shopsStreamProvider,
      entityByIdProvider: shopByIdProvider,
      formProvider: shopFormProvider,
      customListBuilder: (context, state) {
        return ShopListPageRiverpod(
          entityMeta: _config.entityMeta,
          idField: _config.table.idField,
          viewRouteName: _config.routes.viewRouteName,
          fieldConfigs: _config.fields,
          streamProvider: shopsStreamProvider,
          adapterProvider: entityAdapterProvider,
          serviceProvider: entityServiceProvider,
          newRouteName: _config.routes.newRouteName,
          rbacModule: _config.table.name,
          timestampField: _config.table.timestampField,
          initialSorting: _config.listPage?.sorting,
          searchFields: _config.listPage?.searchFields,
          routeIdField: 'shops_primary_route',
          isSelectionMode:
              state.uri.queryParameters['selection'] == 'true' ||
              state.uri.queryParameters['isSelectionMode'] == 'true',
          customItemBuilder: (context, entity, adapter, onTap) {
            return ShopListTile<ModelShop>(
              entity: entity,
              adapter: adapter,
              idField: _config.table.idField,
              entityLabel: _config.entityMeta.entityName,
              entityLabelLower: _config.entityMeta.entityNameLower,
              viewRouteName: _config.routes.viewRouteName,
              rbacModule: _config.table.name,
              onTap: onTap,
            );
          },
        );
      },
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'ShopsRoutesJson not initialized. Call initialize() first.',
      );
    }
    return ModuleRouteRegistry.routes
        .where((route) => route.path.startsWith(_config.routes.basePath))
        .toList();
  }

  /// Route names (for navigation)
  static String get listRouteName => _config.routes.listRouteName;
  static String get newRouteName => _config.routes.newRouteName;
  static String get editRouteName => _config.routes.editRouteName;
  static String get viewRouteName => _config.routes.viewRouteName;

  /// Route paths
  static String get shops => _config.routes.listPath;
  static String get newShop => _config.routes.newPath;
  static String editShopRoute(String id) => _config.routes.editRoute(id);
  static String viewShopRoute(String id) => _config.routes.viewRoute(id);
}
