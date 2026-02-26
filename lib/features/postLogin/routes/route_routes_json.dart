import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/route_model.dart';
import 'providers/route_providers.dart';

/// JSON-based route generation for Routes module
/// Fully migrated to Riverpod - no GetIt dependency
class RoutesRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/routes/route_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelRoute>>((ref) {
      return ref.watch(routeServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelRoute>>((ref) {
      return ref.watch(routeAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelRoute>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: routesStreamProvider,
      entityByIdProvider: routeByIdProvider,
      formProvider: routeFormProvider,
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'RoutesRoutesJson not initialized. Call initialize() first.',
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
  static String get routesPath => _config.routes.listPath;
  static String get newRoute => _config.routes.newPath;
  static String editRouteRoute(String id) => _config.routes.editRoute(id);
  static String viewRouteRoute(String id) => _config.routes.viewRoute(id);
}
