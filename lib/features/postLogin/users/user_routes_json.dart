import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/user_model.dart';
import 'providers/user_providers.dart';
import 'ui/user_list_tile.dart';
import 'ui/user_view_page_riverpod.dart';

/// JSON-based route generation for Users Module
/// Fully migrated to Riverpod - no GetIt dependency
class UsersRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/users/user_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelUser>>((ref) {
      return ref.watch(userServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelUser>>((ref) {
      return ref.watch(userAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelUser>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: usersStreamProvider,
      entityByIdProvider: userByIdProvider,
      formProvider: userFormProvider,
      customItemBuilder: (context, entity, adapter, onTap) =>
          UserListTile(entity: entity, adapter: adapter, onTap: onTap),
      customViewBuilder: (context, entityId) => UserViewPageRiverpod<ModelUser>(
        entityId: entityId,
        entityMeta: _config.entityMeta,
        fieldConfigs: _config.fields,
        idField: _config.table.idField,
        timestampField: _config.table.timestampField,
        editRouteName: _config.routes.editRouteName,
        rbacModule: _config.table.name,
        entityByIdProvider: userByIdProvider,
        adapterProvider: entityAdapterProvider,
        deleteFunction: (ref, id) async {
          final notifier = ref.read(userFormProvider.notifier);
          // Using dynamic dispatch to access delete method on the notifier,
          // matching the pattern in ModuleRouteGenerator
          return await (notifier as dynamic).delete(id);
        },
      ),
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'UsersRoutesJson not initialized. Call initialize() first.',
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
  static String get usersPath => _config.routes.listPath;
  static String get newUser => _config.routes.newPath;
  static String editUserRoute(String id) => _config.routes.editRoute(id);
  static String viewUserRoute(String id) => _config.routes.viewRoute(id);
}
