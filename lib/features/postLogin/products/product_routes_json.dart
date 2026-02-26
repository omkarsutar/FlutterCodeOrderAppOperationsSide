import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/product_model.dart';
import 'providers/product_providers.dart';
import 'ui/product_list_page_riverpod.dart';
import 'ui/product_list_tile.dart';
import 'ui/product_view_page_riverpod.dart';

/// JSON-based route generation for Products module
/// Fully migrated to Riverpod - no GetIt dependency
class ProductsRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/products/product_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelProduct>>((ref) {
      return ref.watch(productServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelProduct>>((ref) {
      return ref.watch(productAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelProduct>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: productsStreamProvider,
      entityByIdProvider: productByIdProvider,
      formProvider: productFormProvider,
      customListBuilder: (context, state) {
        final isSelectionMode =
            state.uri.queryParameters['selection'] == 'true';
        return ProductListPageRiverpod<ModelProduct>(
          entityMeta: _config.entityMeta,
          idField: _config.table.idField,
          viewRouteName: _config.routes.viewRouteName,
          fieldConfigs: _config.fields,
          streamProvider: productsStreamProvider,
          adapterProvider: entityAdapterProvider,
          serviceProvider: entityServiceProvider,
          newRouteName: _config.routes.newRouteName,
          rbacModule: _config.table.name,
          timestampField: _config.table.timestampField,
          searchFields: _config.listPage?.searchFields,
          isSelectionMode: isSelectionMode,
          initialSorting: _config.listPage?.sorting,
          customItemBuilder: (context, entity, adapter, onTap) {
            return ProductListTile(
              entity: entity,
              adapter: adapter,
              onTap: onTap,
            );
          },
        );
      },
      customViewBuilder: (context, entityId) {
        return ProductViewPageRiverpod(entityId: entityId);
      },
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'ProductsRoutesJson not initialized. Call initialize() first.',
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
  static String get products => _config.routes.listPath;
  static String get newProduct => _config.routes.newPath;
  static String editProductRoute(String id) => _config.routes.editRoute(id);
  static String viewProductRoute(String id) => _config.routes.viewRoute(id);
}
