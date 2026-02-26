import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';

import '../../../../core/config/module_config.dart';

import '../adapter/route_shop_link_adapter.dart';
import '../model/route_shop_link_model.dart';
import '../service/route_shop_link_service_impl.dart';

/// Mapper provider
final routeShopLinkMapperProvider = Provider<EntityMapper<ModelRouteShopLink>>((
  ref,
) {
  return ModelRouteShopLinkMapper();
});

/// Cache for module configuration to avoid circular dependencies
class RouteShopLinkConfigCache {
  static ModuleConfig? config;
}

/// Service provider
final routeShopLinkServiceProvider = Provider<RouteShopLinkServiceImpl>((ref) {
  // Extract initial sorting from cached config if available
  final initialSorting = RouteShopLinkConfigCache.config?.listPage?.sorting;

  return RouteShopLinkServiceImpl(
    ref.watch(routeShopLinkMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
    initialSorting: initialSorting,
  );
});

/// Adapter provider
final routeShopLinkAdapterProvider = Provider<RouteShopLinkAdapter>((ref) {
  return RouteShopLinkAdapter();
});

/// Fetches all route-shop links with automatic disposal
/// Uses StreamProvider for real-time updates
final routeShopLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelRouteShopLink>>((ref) {
      final service = ref.read(routeShopLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single route-shop link by ID
final routeShopLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelRouteShopLink?, String>((ref, linkId) async {
      final service = ref.read(routeShopLinkServiceProvider);
      return await service.fetchById(linkId);
    });

/// Fetches route-shop links for a specific route ID using the view/RPC
final routeShopLinksByRouteProvider = StreamProvider.autoDispose
    .family<List<ModelRouteShopLink>, String>((ref, routeId) {
      final service = ref.read(routeShopLinkServiceProvider);
      return service.streamEntitiesByRoute(routeId);
    });

/// State provider for managing route-shop link creation/editing
final routeShopLinkFormProvider =
    StateNotifierProvider.autoDispose<
      RouteShopLinkFormNotifier,
      RouteShopLinkFormState
    >((ref) => RouteShopLinkFormNotifier(ref));

/// Form state for route-shop link
class RouteShopLinkFormState {
  final String? routeId;
  final String? shopId;
  final int? visitOrder;
  final bool isLoading;
  final String? error;

  RouteShopLinkFormState({
    this.routeId,
    this.shopId,
    this.visitOrder,
    this.isLoading = false,
    this.error,
  });

  RouteShopLinkFormState copyWith({
    String? routeId,
    String? shopId,
    int? visitOrder,
    bool? isLoading,
    String? error,
  }) {
    return RouteShopLinkFormState(
      routeId: routeId ?? this.routeId,
      shopId: shopId ?? this.shopId,
      visitOrder: visitOrder ?? this.visitOrder,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing route-shop link form state
class RouteShopLinkFormNotifier extends StateNotifier<RouteShopLinkFormState> {
  final Ref ref;

  RouteShopLinkFormNotifier(this.ref) : super(RouteShopLinkFormState());

  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateRouteId(String routeId) {
    if (!_mounted) return;
    state = state.copyWith(routeId: routeId, error: null);
  }

  void updateShopId(String shopId) {
    if (!_mounted) return;
    state = state.copyWith(shopId: shopId, error: null);
  }

  void updateVisitOrder(int visitOrder) {
    if (!_mounted) return;
    state = state.copyWith(visitOrder: visitOrder, error: null);
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;
    if (state.routeId == null || state.shopId == null) {
      state = state.copyWith(error: 'Route and Shop must be selected');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(routeShopLinkServiceProvider);
      final entity = ModelRouteShopLink(
        linkId: entityId,
        routeId: state.routeId!,
        shopId: state.shopId!,
        visitOrder: state.visitOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (entityId == null) {
        // Create new entity
        await service.create(entity);
      } else {
        // Update existing entity
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save route-shop link: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(routeShopLinkServiceProvider);
      await service.delete(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete route-shop link: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelRouteShopLink entity) {
    if (!_mounted) return;
    state = state.copyWith(
      routeId: entity.routeId,
      shopId: entity.shopId,
      visitOrder: entity.visitOrder,
    );
  }

  void reset() {
    if (!_mounted) return;
    state = RouteShopLinkFormState();
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelRouteShopLinkFields.routeId:
        updateRouteId(value as String);
        break;
      case ModelRouteShopLinkFields.shopId:
        updateShopId(value as String);
        break;
      case ModelRouteShopLinkFields.visitOrder:
        final intValue = value == null
            ? null
            : (value is int ? value : int.tryParse(value.toString()));
        if (intValue != null) {
          updateVisitOrder(intValue);
        }
        break;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}
