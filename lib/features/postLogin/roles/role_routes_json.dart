import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/role_model.dart';
import 'providers/role_providers.dart';

/// JSON-based route generation for Roles module
/// Fully migrated to Riverpod - no GetIt dependency
class RolesRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/roles/role_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelRole>>((ref) {
      return ref.watch(roleServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelRole>>((ref) {
      return ref.watch(roleAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelRole>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: rolesStreamProvider,
      entityByIdProvider: roleByIdProvider,
      formProvider: roleFormProvider,
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'RolesRoutesJson not initialized. Call initialize() first.',
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
  static String get roles => _config.routes.listPath;
  static String get newRole => _config.routes.newPath;
  static String editRoleRoute(String id) => _config.routes.editRoute(id);
  static String viewRoleRoute(String id) => _config.routes.viewRoute(id);
}
