import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/route_shop_link_model.dart';
import 'providers/route_shop_link_controller.dart';
import 'providers/route_shop_link_providers.dart';
import 'ui/route_shop_link_list_page_riverpod.dart';
import 'ui/route_shop_link_tile.dart';
import 'ui/route_shop_links_view_page_riverpod.dart';
import 'ui/route_shop_link_form_page_riverpod.dart';

/// JSON-based route generation for Route Shop Links module
/// Fully migrated to Riverpod - no GetIt dependency
class RouteShopLinksRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/route_shop_links/route_shop_link_config.json',
    );

    // Cache the configuration so providers can access it
    RouteShopLinkConfigCache.config = _config;

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelRouteShopLink>>((
      ref,
    ) {
      return ref.watch(routeShopLinkServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelRouteShopLink>>((
      ref,
    ) {
      return ref.watch(routeShopLinkAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method
    // This ensures it's set on the correct Riverpod provider service instance

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelRouteShopLink>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: routeShopLinksStreamProvider,
      entityByIdProvider: routeShopLinkByIdProvider,
      formProvider: routeShopLinkFormProvider,
      customItemBuilder: (context, entity, adapter, onTap) =>
          RouteShopLinkListTile(entity: entity, adapter: adapter, onTap: onTap),
      customListBuilder: (context, state) => RouteShopLinkListPageRiverpod(
        entityMeta: _config.entityMeta,
        fieldConfigs: _config.fields,
        idField: _config.table.idField,
        timestampField: _config.table.timestampField,
        viewRouteName: _config.routes.viewRouteName,
        newRouteName: _config.routes.newRouteName,
        rbacModule: _config.table.name,
        initialSorting: _config.listPage?.sorting,
        // Search settings
        searchFields: _config.listPage?.searchFields,
        // Custom Item Builder
        customItemBuilder: (context, entity, adapter, onTap) =>
            RouteShopLinkListTile(
              entity: entity,
              adapter: adapter,
              onTap: onTap,
            ),
      ),
      customViewBuilder: (context, entityId) =>
          RouteShopLinksViewPageRiverpod<ModelRouteShopLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            idField: _config.table.idField,
            timestampField: _config.table.timestampField,
            editRouteName: _config.routes.editRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: routeShopLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            deleteFunction: (ref, id) async {
              final service = ref.read(entityServiceProvider);
              try {
                await service.delete(id);
                return true;
              } catch (e) {
                return false;
              }
            },
          ),
      customFormBuilder: (context, entityId) =>
          RouteShopLinkFormPageRiverpod<ModelRouteShopLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            listRouteName: _config.routes.listRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: routeShopLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            onSave: (ref, fieldValues, id) async {
              final service = ref.read(entityServiceProvider);
              try {
                if (id != null) {
                  // Convert Map to ModelRouteShopLink for update
                  final updateData =
                      RouteShopLinkController.convertToModelRouteShopLink(
                        fieldValues,
                      );
                  await service.update(id, updateData);
                } else {
                  // Convert Map to ModelRouteShopLink for create
                  final createData =
                      RouteShopLinkController.convertToModelRouteShopLink(
                        fieldValues,
                      );
                  await service.create(createData);
                }
                return true;
              } catch (e) {
                return false;
              }
            },
          ),
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'RouteShopLinksRoutesJson not initialized. Call initialize() first.',
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
  static String get routeShopLinks => _config.routes.listPath;
  static String get newRouteShopLink => _config.routes.newPath;
  static String editRouteShopLinkRoute(String id) =>
      _config.routes.editRoute(id);
  static String viewRouteShopLinkRoute(String id) =>
      _config.routes.viewRoute(id);
}
