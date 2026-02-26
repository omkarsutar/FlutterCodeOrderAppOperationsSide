import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/shop_adapter.dart';
import '../model/shop_model.dart';
import '../service/shop_service_impl.dart';

// ============================================================================
// SERVICE, MAPPER AND ADAPTER PROVIDERS
// ============================================================================

/// Mapper provider
final shopMapperProvider = Provider<EntityMapper<ModelShop>>((ref) {
  return ModelShopMapper();
});

/// Service provider
final shopServiceProvider = Provider<ShopServiceImpl>((ref) {
  return ShopServiceImpl(
    ref.watch(shopMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final shopAdapterProvider = Provider<ShopAdapter>((ref) {
  return ShopAdapter();
});

/// Fetches all shops with automatic disposal
/// Uses StreamProvider for real-time updates
final shopsStreamProvider = StreamProvider.autoDispose<List<ModelShop>>((ref) {
  final service = ref.read(shopServiceProvider);
  return service.streamEntities();
});

/// Fetches a single shop by ID
final shopByIdProvider = FutureProvider.autoDispose.family<ModelShop?, String>((
  ref,
  shopId,
) async {
  final service = ref.read(shopServiceProvider);
  return await service.fetchById(shopId);
});

/// State provider for managing shop creation/editing
final shopFormProvider =
    StateNotifierProvider.autoDispose<ShopFormNotifier, ShopFormState>(
      (ref) => ShopFormNotifier(ref),
    );

// ============================================================================
// FORM STATE AND NOTIFIER
// ============================================================================

/// Form state for shop creation/editing
class ShopFormState {
  final String shopName;
  final String? shopsPrimaryRoute;
  final String? shopNote;
  final String? hiddenNote;
  final String? shopMobile1;
  final String? shopMobile2;
  final String? shopPersonName;
  final bool? isActive;
  final String? shopLocationUrl;
  final String? shopLandmark;
  final String? shopAddress;
  final String? shopPhotoId;
  final String? shopPhotoUrl;
  final double? shopLat;
  final double? shopLong;
  final bool isLoading;
  final String? error;

  ShopFormState({
    this.shopName = '',
    this.shopsPrimaryRoute,
    this.shopNote,
    this.hiddenNote,
    this.shopMobile1,
    this.shopMobile2,
    this.shopPersonName,
    this.isActive = true,
    this.shopLocationUrl,
    this.shopLandmark,
    this.shopAddress,
    this.shopPhotoId,
    this.shopPhotoUrl,
    this.shopLat,
    this.shopLong,
    this.isLoading = false,
    this.error,
  });

  ShopFormState copyWith({
    String? shopName,
    String? shopsPrimaryRoute,
    String? shopNote,
    String? hiddenNote,
    String? shopMobile1,
    String? shopMobile2,
    String? shopPersonName,
    bool? isActive,
    String? shopLocationUrl,
    String? shopLandmark,
    String? shopAddress,
    String? shopPhotoId,
    String? shopPhotoUrl,
    double? shopLat,
    double? shopLong,
    bool? isLoading,
    String? error,
  }) {
    return ShopFormState(
      shopName: shopName ?? this.shopName,
      shopsPrimaryRoute: shopsPrimaryRoute ?? this.shopsPrimaryRoute,
      shopNote: shopNote ?? this.shopNote,
      hiddenNote: hiddenNote ?? this.hiddenNote,
      shopMobile1: shopMobile1 ?? this.shopMobile1,
      shopMobile2: shopMobile2 ?? this.shopMobile2,
      shopPersonName: shopPersonName ?? this.shopPersonName,
      isActive: isActive ?? this.isActive,
      shopLocationUrl: shopLocationUrl ?? this.shopLocationUrl,
      shopLandmark: shopLandmark ?? this.shopLandmark,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhotoId: shopPhotoId ?? this.shopPhotoId,
      shopPhotoUrl: shopPhotoUrl ?? this.shopPhotoUrl,
      shopLat: shopLat ?? this.shopLat,
      shopLong: shopLong ?? this.shopLong,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing shop form state
class ShopFormNotifier extends StateNotifier<ShopFormState> {
  final Ref ref;
  bool _mounted = true;

  ShopFormNotifier(this.ref) : super(ShopFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateField(String fieldName, dynamic value) {
    if (!_mounted) return;

    switch (fieldName) {
      case ModelShopFields.shopName:
        state = state.copyWith(shopName: value as String, error: null);
        break;
      case ModelShopFields.shopsPrimaryRoute:
        state = state.copyWith(
          shopsPrimaryRoute: value as String?,
          error: null,
        );
        break;
      case ModelShopFields.shopNote:
        state = state.copyWith(shopNote: value as String?, error: null);
        break;
      case ModelShopFields.hiddenNote:
        state = state.copyWith(hiddenNote: value as String?, error: null);
        break;
      case ModelShopFields.shopMobile1:
        state = state.copyWith(shopMobile1: value as String?, error: null);
        break;
      case ModelShopFields.shopMobile2:
        state = state.copyWith(shopMobile2: value as String?, error: null);
        break;
      case ModelShopFields.shopPersonName:
        state = state.copyWith(shopPersonName: value as String?, error: null);
        break;
      case ModelShopFields.isActive:
        state = state.copyWith(isActive: value as bool?, error: null);
        break;
      case ModelShopFields.shopLocationUrl:
        state = state.copyWith(shopLocationUrl: value as String?, error: null);
        break;
      case ModelShopFields.shopLandmark:
        state = state.copyWith(shopLandmark: value as String?, error: null);
        break;
      case ModelShopFields.shopAddress:
        state = state.copyWith(shopAddress: value as String?, error: null);
        break;
      case ModelShopFields.shopPhotoId:
        state = state.copyWith(shopPhotoId: value as String?, error: null);
        break;
      case ModelShopFields.shopPhotoUrl:
        state = state.copyWith(shopPhotoUrl: value as String?, error: null);
        break;
      case ModelShopFields.shopLat:
        state = state.copyWith(
          shopLat: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelShopFields.shopLong:
        state = state.copyWith(
          shopLong: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    // Validation
    if (state.shopName.trim().isEmpty) {
      state = state.copyWith(error: 'Shop name is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(shopServiceProvider);
      final entity = ModelShop(
        shopId: entityId,
        shopName: state.shopName.trim(),
        shopsPrimaryRoute: state.shopsPrimaryRoute,
        shopNote: state.shopNote,
        hiddenNote: state.hiddenNote,
        shopMobile1: state.shopMobile1,
        shopMobile2: state.shopMobile2,
        shopPersonName: state.shopPersonName,
        isActive: state.isActive ?? true,
        shopLocationUrl: state.shopLocationUrl,
        shopLandmark: state.shopLandmark,
        shopAddress: state.shopAddress,
        shopPhotoId: state.shopPhotoId,
        shopPhotoUrl: state.shopPhotoUrl,
        shopLat: state.shopLat,
        shopLong: state.shopLong,
      );

      if (entityId == null) {
        // Create new shop
        await service.create(entity);
      } else {
        // Update existing shop
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save shop: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(shopServiceProvider);
      await service.delete(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete shop: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelShop entity) {
    if (!_mounted) return;
    state = ShopFormState(
      shopName: entity.shopName,
      shopsPrimaryRoute: entity.shopsPrimaryRoute,
      shopNote: entity.shopNote,
      hiddenNote: entity.hiddenNote,
      shopMobile1: entity.shopMobile1,
      shopMobile2: entity.shopMobile2,
      shopPersonName: entity.shopPersonName,
      isActive: entity.isActive,
      shopLocationUrl: entity.shopLocationUrl,
      shopLandmark: entity.shopLandmark,
      shopAddress: entity.shopAddress,
      shopPhotoId: entity.shopPhotoId,
      shopPhotoUrl: entity.shopPhotoUrl,
      shopLat: entity.shopLat,
      shopLong: entity.shopLong,
    );
  }

  void reset() {
    if (!_mounted) return;
    state = ShopFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}
