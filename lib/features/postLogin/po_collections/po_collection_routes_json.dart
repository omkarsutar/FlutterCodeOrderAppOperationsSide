import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/po_collection_model.dart';
import 'providers/po_collection_providers.dart';
import 'ui/po_collection_list_page.dart';
import 'ui/po_collection_page.dart';

/// JSON-based route generation for PO Collections module
class PoCollectionsRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/po_collections/po_collection_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelPoCollection>>((
      ref,
    ) {
      return ref.watch(poCollectionServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelPoCollection>>((
      ref,
    ) {
      return ref.watch(poCollectionAdapterProvider);
    });

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelPoCollection>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: poCollectionsStreamProvider,
      entityByIdProvider: poCollectionByIdProvider,
      formProvider: poCollectionFormProvider,
      customListBuilder: (context, state) => const PoCollectionListPage(),
      customViewBuilder: (context, poId) =>
          PurchaseOrderCollectionPage(poId: poId),
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'PoCollectionsRoutesJson not initialized. Call initialize() first.',
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
  static String get collections => _config.routes.listPath;
  static String get newCollection => _config.routes.newPath;
  static String editCollectionRoute(String id) => _config.routes.editRoute(id);
  static String viewCollectionRoute(String id) => _config.routes.viewRoute(id);
}
