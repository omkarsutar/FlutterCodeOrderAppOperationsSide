import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/module_config.dart';
import '../providers/core_providers.dart';

import '../services/entity_service.dart';
import '../../features/postLogin/entity_page/entity_page_barrel.dart';
import '../models/route_permission.dart';
import '../services/rbac_service.dart';

/// Generic route generator that creates routes from JSON module configuration
/// This is the core of the WordPress-style configurable module system
class ModuleRouteGenerator<T> {
  final ModuleConfig config;
  final Provider<EntityService<T>> serviceProvider;
  final Provider<EntityAdapter<T>> adapterProvider;
  final ProviderListenable<AsyncValue<List<T>>> streamProvider;
  final AutoDisposeFutureProviderFamily<T?, String> entityByIdProvider;
  final AutoDisposeStateNotifierProvider<dynamic, dynamic> formProvider;
  final Widget Function(BuildContext, T, EntityAdapter<T>, VoidCallback)?
  customItemBuilder;
  final Widget Function(BuildContext, String)? customViewBuilder;
  final Widget Function(BuildContext context, GoRouterState state)?
  customListBuilder;
  final Widget Function(BuildContext, String?)? customFormBuilder;

  ModuleRouteGenerator({
    required this.config,
    required this.serviceProvider,
    required this.adapterProvider,
    required this.streamProvider,
    required this.entityByIdProvider,
    required this.formProvider,
    this.customItemBuilder,
    this.customViewBuilder,
    this.customListBuilder,
    this.customFormBuilder,
  });

  /// Generate all routes for this module
  List<GoRoute> generateRoutes() {
    final listRoute = _generateListRoute();
    final newRoute = _generateNewRoute();
    final editRoute = _generateEditRoute();
    final viewRoute = _generateViewRoute();

    // Register permissions for each route
    if (listRoute.name != null) {
      ModuleRouteRegistry.registerRoutePermission(
        listRoute.name!,
        RoutePermission(moduleId: config.moduleName, action: RbacAction.read),
      );
    }
    if (viewRoute.name != null) {
      ModuleRouteRegistry.registerRoutePermission(
        viewRoute.name!,
        RoutePermission(moduleId: config.moduleName, action: RbacAction.read),
      );
    }
    if (newRoute.name != null) {
      ModuleRouteRegistry.registerRoutePermission(
        newRoute.name!,
        RoutePermission(moduleId: config.moduleName, action: RbacAction.create),
      );
    }
    if (editRoute.name != null) {
      ModuleRouteRegistry.registerRoutePermission(
        editRoute.name!,
        RoutePermission(moduleId: config.moduleName, action: RbacAction.update),
      );
    }

    return [listRoute, newRoute, editRoute, viewRoute];
  }

  /// Generate list/index route
  GoRoute _generateListRoute() {
    return GoRoute(
      name: config.routes.listRouteName,
      path: config.routes.listPath,
      redirect: (context, state) {
        final rbacService = ProviderScope.containerOf(
          context,
        ).read(rbacServiceProvider);

        // Wait for RBAC initialization
        if (!rbacService.isInitialized) return null;

        final hasAccess = rbacService.hasPermission(
          config.moduleName,
          RbacAction.read,
        );

        if (!hasAccess) {
          debugPrint(
            'ModuleRouteGenerator: Access denied for ${config.moduleName} (read)',
          );
          return '/unauthorized';
        }
        return null;
      },
      builder: (context, state) {
        // Selection mode parameter is available if needed in future
        // final isSelectionMode = state.uri.queryParameters['selection'] == 'true';

        // Use custom List builder if provided
        if (customListBuilder != null) {
          return customListBuilder!(context, state);
        }

        return EntityListPageRiverpod<T>(
          entityMeta: config.entityMeta,
          fieldConfigs: config.fields,
          idField: config.table.idField,
          timestampField: config.table.timestampField,
          viewRouteName: config.routes.viewRouteName,
          newRouteName: config.routes.newRouteName,
          rbacModule: config.moduleName,
          // Riverpod providers
          streamProvider: streamProvider,
          adapterProvider: adapterProvider,
          serviceProvider: serviceProvider,
          // Search settings
          searchFields: config.listPage?.searchFields,
          initialSorting: config.listPage?.sorting,
          // Custom Builder
          customItemBuilder: customItemBuilder,
        );
      },
    );
  }

  /// Generate new/create route
  GoRoute _generateNewRoute() {
    return GoRoute(
      name: config.routes.newRouteName,
      path: config.routes.newPath,
      redirect: (context, state) {
        final rbacService = ProviderScope.containerOf(
          context,
        ).read(rbacServiceProvider);

        // Wait for RBAC initialization
        if (!rbacService.isInitialized) return null;

        final hasAccess = rbacService.hasPermission(
          config.moduleName,
          RbacAction.create,
        );

        if (!hasAccess) {
          debugPrint(
            'ModuleRouteGenerator: Access denied for ${config.moduleName} (create)',
          );
          return '/unauthorized';
        }
        return null;
      },
      builder: (context, state) {
        // Pass query parameters as initial values (e.g. for pre-selecting parent ID)
        final initialValues = state.uri.queryParameters.isNotEmpty
            ? state.uri.queryParameters
            : null;

        // Use custom form builder if provided
        if (customFormBuilder != null) {
          return customFormBuilder!(context, null);
        }

        return EntityFormPageRiverpod<T>(
          entityMeta: config.entityMeta,
          fieldConfigs: config.fields,
          listRouteName: config.routes.listRouteName,
          rbacModule: config.moduleName,
          entityByIdProvider: entityByIdProvider,
          adapterProvider: adapterProvider,
          onSave: _createOnSaveCallback(),
          defaultValues: initialValues,
        );
      },
    );
  }

  /// Generate edit route
  GoRoute _generateEditRoute() {
    return GoRoute(
      name: config.routes.editRouteName,
      path: config.routes.editPath,
      redirect: (context, state) {
        final rbacService = ProviderScope.containerOf(
          context,
        ).read(rbacServiceProvider);

        // Wait for RBAC initialization
        if (!rbacService.isInitialized) return null;

        final hasAccess = rbacService.hasPermission(
          config.moduleName,
          RbacAction.update,
        );

        if (!hasAccess) {
          debugPrint(
            'ModuleRouteGenerator: Access denied for ${config.moduleName} (update)',
          );
          return '/unauthorized';
        }
        return null;
      },
      builder: (context, state) {
        final entityId = state.pathParameters['id']!;

        // Use custom form builder if provided
        if (customFormBuilder != null) {
          return customFormBuilder!(context, entityId);
        }

        return EntityFormPageRiverpod<T>(
          entityId: entityId,
          entityMeta: config.entityMeta,
          fieldConfigs: config.fields,
          listRouteName: config.routes.listRouteName,
          rbacModule: config.moduleName,
          entityByIdProvider: entityByIdProvider,
          adapterProvider: adapterProvider,
          onSave: _createOnSaveCallback(),
          initialValues: null,
        );
      },
    );
  }

  /// Generate view/detail route
  GoRoute _generateViewRoute() {
    return GoRoute(
      name: config.routes.viewRouteName,
      path: config.routes.viewPath,
      redirect: (context, state) {
        final rbacService = ProviderScope.containerOf(
          context,
        ).read(rbacServiceProvider);

        // Wait for RBAC initialization
        if (!rbacService.isInitialized) return null;

        final hasAccess = rbacService.hasPermission(
          config.moduleName,
          RbacAction.read,
        );

        if (!hasAccess) {
          debugPrint(
            'ModuleRouteGenerator: Access denied for ${config.moduleName} (read/view)',
          );
          return '/unauthorized';
        }
        return null;
      },
      builder: (context, state) {
        final entityId = state.pathParameters['id']!;
        // Use custom View builder if provided
        if (customViewBuilder != null) {
          return customViewBuilder!(context, entityId);
        }
        return EntityViewPageRiverpod<T>(
          entityId: entityId,
          entityMeta: config.entityMeta,
          fieldConfigs: config.fields,
          idField: config.table.idField,
          timestampField: config.table.timestampField,
          editRouteName: config.routes.editRouteName,
          rbacModule: config.moduleName,
          entityByIdProvider: entityByIdProvider,
          adapterProvider: adapterProvider,
          deleteFunction: _createDeleteCallback(),
        );
      },
    );
  }

  /// Create onSave callback for form
  Future<bool> Function(WidgetRef, Map<String, dynamic>, String?)
  _createOnSaveCallback() {
    return (ref, fieldValues, entityId) async {
      final notifier = ref.read(formProvider.notifier);

      // Update all fields in the notifier
      for (final field in config.fields) {
        final value = fieldValues[field.name];
        if (value != null) {
          // Call updateField method on the notifier
          // This assumes all form notifiers have an updateField method
          (notifier as dynamic).updateField(field.name, value);
        }
      }

      // Save the entity
      // This assumes all form notifiers have a save method
      final success = await (notifier as dynamic).save(entityId: entityId);
      if (!success) {
        final state = ref.read(formProvider);
        final error = (state as dynamic).error;
        throw Exception(error ?? 'Failed to save');
      }
      return true;
    };
  }

  /// Create delete callback for view page
  Future<bool> Function(WidgetRef, String) _createDeleteCallback() {
    return (ref, id) async {
      final notifier = ref.read(formProvider.notifier);
      // This assumes all form notifiers have a delete method
      return await (notifier as dynamic).delete(id);
    };
  }
}

/// Helper class to register module routes
class ModuleRouteRegistry {
  static final Map<String, ModuleConfig> _configs = {};
  static final List<GoRoute> _routes = [];
  static final Map<String, RoutePermission> _routePermissions = {};

  /// Register a permission for a route by name
  static void registerRoutePermission(
    String routeName,
    RoutePermission permission,
  ) {
    _routePermissions[routeName] = permission;
  }

  /// Get the permission required for a route
  static RoutePermission? getRoutePermission(String routeName) {
    return _routePermissions[routeName];
  }

  /// Register a module and generate its routes
  static void registerModule<T>({
    required ModuleConfig config,
    required Provider<EntityService<T>> serviceProvider,
    required Provider<EntityAdapter<T>> adapterProvider,
    required ProviderListenable<AsyncValue<List<T>>> streamProvider,
    required AutoDisposeFutureProviderFamily<T?, String> entityByIdProvider,
    required AutoDisposeStateNotifierProvider<dynamic, dynamic> formProvider,
    Widget Function(BuildContext, T, EntityAdapter<T>, VoidCallback)?
    customItemBuilder,
    Widget Function(BuildContext, String)? customViewBuilder,
    Widget Function(BuildContext, GoRouterState)? customListBuilder,
    Widget Function(BuildContext, String?)? customFormBuilder,
  }) {
    _configs[config.moduleName] = config;

    final generator = ModuleRouteGenerator<T>(
      config: config,
      serviceProvider: serviceProvider,
      adapterProvider: adapterProvider,
      streamProvider: streamProvider,
      entityByIdProvider: entityByIdProvider,
      formProvider: formProvider,
      customItemBuilder: customItemBuilder,
      customViewBuilder: customViewBuilder,
      customListBuilder: customListBuilder,
      customFormBuilder: customFormBuilder,
    );

    _routes.addAll(generator.generateRoutes());
  }

  /// Get all registered routes
  static List<GoRoute> get routes => List.unmodifiable(_routes);

  /// Get config for a specific module
  static ModuleConfig? getConfig(String moduleName) => _configs[moduleName];

  /// Clear all registrations (useful for testing)
  static void clear() {
    _configs.clear();
    _routes.clear();
  }
}
