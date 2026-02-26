import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/rbac_module_model.dart';
import 'providers/rbac_module_providers.dart';

/// JSON-based route generation for RBAC Modules module
/// Fully migrated to Riverpod - no GetIt dependency
class RbacModulesRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/rbac_modules/rbac_module_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelRbacModule>>((
      ref,
    ) {
      return ref.watch(rbacModuleServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelRbacModule>>((
      ref,
    ) {
      return ref.watch(rbacModuleAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelRbacModule>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: rbacModulesStreamProvider,
      entityByIdProvider: rbacModuleByIdProvider,
      formProvider: rbacModuleFormProvider,
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'RbacModulesRoutesJson not initialized. Call initialize() first.',
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
  static String get rbacModulesPath => _config.routes.listPath;
  static String get newRbacModule => _config.routes.newPath;
  static String editRbacModuleRoute(String id) => _config.routes.editRoute(id);
  static String viewRbacModuleRoute(String id) => _config.routes.viewRoute(id);
}
