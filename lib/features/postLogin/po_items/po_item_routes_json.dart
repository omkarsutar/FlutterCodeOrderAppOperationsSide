import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/po_item_model.dart';
import 'providers/po_item_providers.dart';
import 'ui/po_item_list_page_riverpod.dart';

/// JSON-based route generation for PoItems module
class PoItemsRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/po_items/po_item_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelPoItem>>((ref) {
      return ref.watch(poItemServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelPoItem>>((ref) {
      return ref.watch(poItemAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelPoItem>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: poItemsStreamProvider,
      entityByIdProvider: poItemByIdProvider,
      formProvider: poItemFormProvider,
      customListBuilder: (context, state) {
        final poId = state.uri.queryParameters['po_id'] ?? '';
        // final po = state.extra as ModelPurchaseOrder; // <-- get the extra

        /* // Navigate to Purchase Orders list if po_id is not provided
        if (poId.isEmpty) {
          // Use WidgetsBinding to navigate safely after frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/purchase_orders');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } */

        return PoItemListPageRiverpod(
          poId: poId,
          entityLabel: _config.entityMeta.entityName,
          viewRouteName: _config.routes.viewRouteName,
          newRouteName: _config.routes.newRouteName,
          initialSorting: _config.listPage?.sorting,
          // po: po,
        );
      },
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'PoItemsRoutesJson not initialized. Call initialize() first.',
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
  static String get poItems => _config.routes.listPath;
  static String get newPoItem => _config.routes.newPath;
  static String editPoItemRoute(String id) => _config.routes.editRoute(id);
  static String viewPoItemRoute(String id) => _config.routes.viewRoute(id);
}
