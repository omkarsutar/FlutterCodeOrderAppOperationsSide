import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../service/retailer_shop_link_service_impl.dart';
import '../adapter/retailer_shop_link_adapter.dart';
import '../model/retailer_shop_link_model.dart';

/// Mapper provider
final retailerShopLinkMapperProvider =
    Provider<EntityMapper<ModelRetailerShopLink>>((ref) {
      return ModelRetailerShopLinkMapper();
    });

/// Service provider
final retailerShopLinkServiceProvider = Provider<RetailerShopLinkServiceImpl>((
  ref,
) {
  return RetailerShopLinkServiceImpl(
    ref.watch(retailerShopLinkMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final retailerShopLinkAdapterProvider = Provider<RetailerShopLinkAdapter>((
  ref,
) {
  return RetailerShopLinkAdapter();
});

/// Fetches all links with automatic disposal
final retailerShopLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelRetailerShopLink>>((ref) {
      final service = ref.read(retailerShopLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single link by ID
final retailerShopLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelRetailerShopLink?, String>((ref, id) async {
      final service = ref.read(retailerShopLinkServiceProvider);
      return await service.fetchById(id);
    });

/// State provider for managing form state
final retailerShopLinkFormProvider =
    StateNotifierProvider.autoDispose<
      RetailerShopLinkFormNotifier,
      RetailerShopLinkFormState
    >((ref) {
      return RetailerShopLinkFormNotifier(ref);
    });

/// Form state
class RetailerShopLinkFormState {
  final String? userId;
  final String? shopId;
  final bool isLoading;
  final String? error;

  RetailerShopLinkFormState({
    this.userId,
    this.shopId,
    this.isLoading = false,
    this.error,
  });

  RetailerShopLinkFormState copyWith({
    String? userId,
    String? shopId,
    bool? isLoading,
    String? error,
  }) {
    return RetailerShopLinkFormState(
      userId: userId ?? this.userId,
      shopId: shopId ?? this.shopId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing form state
class RetailerShopLinkFormNotifier
    extends StateNotifier<RetailerShopLinkFormState> {
  final Ref ref;

  RetailerShopLinkFormNotifier(this.ref) : super(RetailerShopLinkFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateUserId(String? userId) {
    if (!_mounted) return;
    state = state.copyWith(userId: userId, error: null);
  }

  void updateShopId(String? shopId) {
    if (!_mounted) return;
    state = state.copyWith(shopId: shopId, error: null);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelRetailerShopLinkFields.userId:
        updateUserId(value as String?);
        break;
      case ModelRetailerShopLinkFields.shopId:
        updateShopId(value as String?);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(retailerShopLinkServiceProvider);

      // Validation
      if (state.userId == null || state.shopId == null) {
        throw Exception('User and Shop are required');
      }

      final entity = ModelRetailerShopLink(
        linkId: entityId ?? '',
        userId: state.userId!,
        shopId: state.shopId!,
      );

      if (entityId == null) {
        await service.create(entity);
      } else {
        await service.update(entityId, entity);
      }

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method
  Future<bool> delete(String id) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(retailerShopLinkServiceProvider);
      await service.deleteEntityById(id);
      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }
}
