import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import 'package:collection/collection.dart';
import '../../../../core/config/module_config.dart';

import '../adapter/purchase_order_adapter.dart';
import '../model/purchase_order_model.dart';
import '../service/purchase_order_service_impl.dart';

/// Mapper provider
final purchaseOrderMapperProvider = Provider<EntityMapper<ModelPurchaseOrder>>((
  ref,
) {
  return ModelPurchaseOrderMapper();
});

/// Cache for module configuration to avoid circular dependencies
class PurchaseOrderConfigCache {
  static ModuleConfig? config;
}

/// Service provider
final purchaseOrderServiceProvider = Provider<PurchaseOrderServiceImpl>((ref) {
  // Extract initial sorting from cached config if available
  final initialSorting = PurchaseOrderConfigCache.config?.listPage?.sorting;

  return PurchaseOrderServiceImpl(
    ref.watch(purchaseOrderMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
    ref,
    initialSorting: initialSorting,
  );
});

/// Adapter provider
final purchaseOrderAdapterProvider = Provider<PurchaseOrderAdapter>((ref) {
  return PurchaseOrderAdapter();
});

/// Real-time stream of all purchase orders
/// Uses StreamProvider.autoDispose for automatic cleanup when page is unmounted
/// Strategy: Listen to purchase_order table, read from view_purchase_orders
/// The stream automatically updates when any purchase order is created, updated, or deleted
final purchaseOrdersStreamProvider =
    StreamProvider.autoDispose<List<ModelPurchaseOrder>>((ref) {
      final service = ref.read(purchaseOrderServiceProvider);
      return service.streamEntities();
    });

/// Fetch a single purchase order by ID
/// Uses FutureProvider.autoDispose.family for efficient caching and cleanup
final purchaseOrderByIdProvider = FutureProvider.autoDispose
    .family<ModelPurchaseOrder?, String>((ref, poId) async {
      final service = ref.read(purchaseOrderServiceProvider);
      return await service.fetchById(poId);
    });

/// State provider for managing purchase order creation/editing
/// Uses StateNotifierProvider.autoDispose for form state management
final purchaseOrderFormProvider =
    StateNotifierProvider.autoDispose<
      PurchaseOrderFormNotifier,
      PurchaseOrderFormState
    >((ref) => PurchaseOrderFormNotifier(ref));

final purchaseOrderStreamByIdProvider =
    StreamProvider.family<ModelPurchaseOrder?, String>((ref, poId) {
      return ref
          .watch(purchaseOrderServiceProvider)
          .streamEntities()
          .map((orders) => orders.firstWhereOrNull((o) => o.poId == poId));
    });

/// Persistent search query for PO list
final purchaseOrderSearchProvider = StateProvider.family
    .autoDispose<String, String>((ref, key) => '');

/// Persistent status filter for PO list
final purchaseOrderStatusFilterProvider = StateProvider.family
    .autoDispose<String?, String>((ref, key) => 'confirmed');

/// Fetch a single purchase order by ID

/// Form state for purchase order
class PurchaseOrderFormState {
  final String poRouteId;
  final String poShopId;
  final double? poTotalAmount;
  final int? poLineItemCount;
  final String? userComment;
  final double? profitToShop;
  final double? poLat;
  final double? poLong;
  final String? status;
  final bool isLoading;
  final String? error;

  PurchaseOrderFormState({
    this.poRouteId = '',
    this.poShopId = '',
    this.poTotalAmount,
    this.poLineItemCount,
    this.userComment,
    this.profitToShop,
    this.poLat,
    this.poLong,
    this.status = 'confirmed',
    this.isLoading = false,
    this.error,
  });

  PurchaseOrderFormState copyWith({
    String? poRouteId,
    String? poShopId,
    double? poTotalAmount,
    int? poLineItemCount,
    String? userComment,
    double? profitToShop,
    double? poLat,
    double? poLong,
    String? status,
    bool? isLoading,
    String? error,
  }) {
    return PurchaseOrderFormState(
      poRouteId: poRouteId ?? this.poRouteId,
      poShopId: poShopId ?? this.poShopId,
      poTotalAmount: poTotalAmount ?? this.poTotalAmount,
      poLineItemCount: poLineItemCount ?? this.poLineItemCount,
      userComment: userComment ?? this.userComment,
      profitToShop: profitToShop ?? this.profitToShop,
      poLat: poLat ?? this.poLat,
      poLong: poLong ?? this.poLong,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing purchase order form state
class PurchaseOrderFormNotifier extends StateNotifier<PurchaseOrderFormState> {
  final Ref ref;
  bool _mounted = true;

  PurchaseOrderFormNotifier(this.ref) : super(PurchaseOrderFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateField(String fieldName, dynamic value) {
    if (!_mounted) return;

    switch (fieldName) {
      case ModelPurchaseOrderFields.poRouteId:
        state = state.copyWith(poRouteId: value as String, error: null);
        break;
      case ModelPurchaseOrderFields.poShopId:
        state = state.copyWith(poShopId: value as String, error: null);
        break;
      case ModelPurchaseOrderFields.poTotalAmount:
        state = state.copyWith(
          poTotalAmount: value != null
              ? double.tryParse(value.toString())
              : null,
          error: null,
        );
        break;
      case ModelPurchaseOrderFields.poLineItemCount:
        state = state.copyWith(
          poLineItemCount: value != null
              ? int.tryParse(value.toString())
              : null,
          error: null,
        );
        break;
      case ModelPurchaseOrderFields.userComment:
        state = state.copyWith(userComment: value as String?, error: null);
        break;
      case ModelPurchaseOrderFields.profitToShop:
        state = state.copyWith(
          profitToShop: value != null
              ? double.tryParse(value.toString())
              : null,
          error: null,
        );
        break;
      case ModelPurchaseOrderFields.poLat:
        state = state.copyWith(
          poLat: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelPurchaseOrderFields.poLong:
        state = state.copyWith(
          poLong: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelPurchaseOrderFields.status:
        state = state.copyWith(status: value as String?, error: null);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    // Validation
    if (state.poRouteId.trim().isEmpty) {
      state = state.copyWith(error: 'Route is required');
      return false;
    }
    if (state.poShopId.trim().isEmpty) {
      state = state.copyWith(error: 'Shop is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(purchaseOrderServiceProvider);
      final entity = ModelPurchaseOrder(
        poId: entityId,
        poRouteId: state.poRouteId.trim(),
        poShopId: state.poShopId.trim(),
        poTotalAmount: state.poTotalAmount,
        poLineItemCount: state.poLineItemCount,
        userComment: state.userComment,
        profitToShop: state.profitToShop,
        poLat: state.poLat,
        poLong: state.poLong,
        status: state.status,
      );

      if (entityId == null) {
        // Create new purchase order
        await service.create(entity);
      } else {
        // Update existing purchase order
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save purchase order: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(purchaseOrderServiceProvider);
      await service.deleteEntityById(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete purchase order: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelPurchaseOrder entity) {
    if (!_mounted) return;
    state = PurchaseOrderFormState(
      poRouteId: entity.poRouteId ?? '',
      poShopId: entity.poShopId ?? '',
      poTotalAmount: entity.poTotalAmount,
      poLineItemCount: entity.poLineItemCount,
      userComment: entity.userComment,
      profitToShop: entity.profitToShop,
      poLat: entity.poLat,
      poLong: entity.poLong,
      status: entity.status ?? 'confirmed',
    );
  }

  void reset() {
    if (!_mounted) return;
    state = PurchaseOrderFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}
