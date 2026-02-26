import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/rbac_permission_model.dart';
import 'providers/rbac_permission_providers.dart';
import 'ui/rbac_permission_list_page_riverpod.dart';

/// JSON-based route generation for RBAC Permissions module
/// Fully migrated to Riverpod - no GetIt dependency
class RbacPermissionsRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/rbac_permissions/rbac_permission_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelRbacPermission>>((
      ref,
    ) {
      return ref.watch(rbacPermissionServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelRbacPermission>>((
      ref,
    ) {
      return ref.watch(rbacPermissionAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelRbacPermission>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: rbacPermissionsStreamProvider,
      entityByIdProvider: rbacPermissionByIdProvider,
      formProvider: rbacPermissionFormProvider,
      customListBuilder: (context, state) => RbacPermissionListPageRiverpod(
        entityLabel: _config.entityMeta.entityName,
        viewRouteName: _config.routes.viewRouteName,
        newRouteName: _config.routes.newRouteName,
        rbacModule: _config.table.name,
      ),
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'RbacPermissionsRoutesJson not initialized. Call initialize() first.',
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
  static String get permissions => _config.routes.listPath;
  static String get newPermission => _config.routes.newPath;
  static String editPermissionRoute(String id) => _config.routes.editRoute(id);
  static String viewPermissionRoute(String id) => _config.routes.viewRoute(id);
}
