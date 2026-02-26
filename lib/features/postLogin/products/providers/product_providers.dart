import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/product_adapter.dart';
import '../model/product_model.dart';
import '../service/product_service_impl.dart';

/// Mapper provider
final productMapperProvider = Provider<EntityMapper<ModelProduct>>((ref) {
  return ModelProductMapper();
});

/// Service provider
final productServiceProvider = Provider<ProductServiceImpl>((ref) {
  return ProductServiceImpl(
    ref.watch(productMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final productAdapterProvider = Provider<ProductAdapter>((ref) {
  return ProductAdapter();
});

/// Fetches all products with automatic disposal
/// Uses StreamProvider for real-time updates
final productsStreamProvider = StreamProvider.autoDispose<List<ModelProduct>>((
  ref,
) {
  final service = ref.read(productServiceProvider);
  return service.streamEntities();
});

/// Centralized provider for product filter types/categories
final productFilterTypesProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'Custard': 'Pow Custard'},
    {'Powder': 'Powder'},
    {'Pouch': 'Pouch'},
    {'Essence': 'Essence'},
    {'Color': 'Color'},
    {'Aata': 'Aata'},
    {'Goli': 'Goli'},
    {'Biscuit': 'Biscuit'},
    {'Jelly': 'Pow Jelly'},
    {'Ice Cream Mix': 'Pow Ice Cream Mix'},
  ];
});

/// Fetches a single product by ID
final productByIdProvider = FutureProvider.autoDispose
    .family<ModelProduct?, String>((ref, productId) async {
      final service = ref.read(productServiceProvider);
      return await service.fetchById(productId);
    });

/// State provider for managing product creation/editing
final productFormProvider =
    StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>(
      (ref) => ProductFormNotifier(ref),
    );

/// Form state for Product
class ProductFormState {
  final String productType;
  final String productName;
  final double productWeightValue;
  final String productWeightUnit;
  final double purchaseRateForRetailer;
  final double mrp;
  final String packagingType;
  final int? piecesPerOuter;
  final bool isOuter;
  final bool isActive;
  final bool isAvailable;
  final bool qtyInDecimal; // new field
  final String productImage;
  final bool isLoading;
  final String? error;

  const ProductFormState({
    this.productType = '',
    this.productName = '',
    this.productWeightValue = 0.0,
    this.productWeightUnit = 'gms',
    this.purchaseRateForRetailer = 0.0,
    this.mrp = 0.0,
    this.packagingType = 'box',
    this.piecesPerOuter = 0,
    this.isOuter = false,
    this.isActive = true,
    this.isAvailable = true,
    this.qtyInDecimal = false, // default
    this.productImage = '',
    this.isLoading = false,
    this.error,
  });

  ProductFormState copyWith({
    String? productType,
    String? productName,
    double? productWeightValue,
    String? productWeightUnit,
    double? purchaseRateForRetailer,
    double? mrp,
    String? packagingType,
    int? piecesPerOuter,
    bool? isOuter,
    bool? isActive,
    bool? isAvailable,
    bool? qtyInDecimal,
    String? productImage,
    bool? isLoading,
    String? error,
  }) {
    return ProductFormState(
      productType: productType ?? this.productType,
      productName: productName ?? this.productName,
      productWeightValue: productWeightValue ?? this.productWeightValue,
      productWeightUnit: productWeightUnit ?? this.productWeightUnit,
      purchaseRateForRetailer:
          purchaseRateForRetailer ?? this.purchaseRateForRetailer,
      mrp: mrp ?? this.mrp,
      packagingType: packagingType ?? this.packagingType,
      piecesPerOuter: piecesPerOuter ?? this.piecesPerOuter,
      isOuter: isOuter ?? this.isOuter,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      qtyInDecimal: qtyInDecimal ?? this.qtyInDecimal,
      productImage: productImage ?? this.productImage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory ProductFormState.fromEntity(ModelProduct entity) {
    return ProductFormState(
      productType: entity.productType,
      productName: entity.productName,
      productWeightValue: entity.productWeightValue,
      productWeightUnit: entity.productWeightUnit,
      purchaseRateForRetailer: entity.purchaseRateForRetailer,
      mrp: entity.mrp,
      packagingType: entity.packagingType,
      piecesPerOuter: entity.piecesPerOuter ?? 0,
      isOuter: entity.isOuter,
      isActive: entity.isActive,
      isAvailable: entity.isAvailable,
      qtyInDecimal: entity.qtyInDecimal,
      productImage: entity.productImage ?? '',
    );
  }
}

/// Notifier for managing Product form state
class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final Ref ref;
  bool _mounted = true;

  ProductFormNotifier(this.ref) : super(ProductFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateProductType(String type) {
    if (!_mounted) return;
    state = state.copyWith(productType: type, error: null);
  }

  void updateProductName(String name) {
    if (!_mounted) return;
    state = state.copyWith(productName: name, error: null);
  }

  void updateWeightValue(double value) {
    if (!_mounted) return;
    state = state.copyWith(productWeightValue: value, error: null);
  }

  void updateWeightUnit(String unit) {
    if (!_mounted) return;
    state = state.copyWith(productWeightUnit: unit, error: null);
  }

  void updatePurchaseRateForRetailer(double rate) {
    if (!_mounted) return;
    state = state.copyWith(purchaseRateForRetailer: rate, error: null);
  }

  void updateMrp(double value) {
    if (!_mounted) return;
    state = state.copyWith(mrp: value, error: null);
  }

  void updatePackagingType(String type) {
    if (!_mounted) return;
    state = state.copyWith(packagingType: type, error: null);
  }

  void updatePiecesPerOuter(int? pieces) {
    if (!_mounted) return;
    state = state.copyWith(piecesPerOuter: pieces, error: null);
  }

  void updateIsOuter(bool isOuter) {
    if (!_mounted) return;
    state = state.copyWith(isOuter: isOuter, error: null);
  }

  void updateIsActive(bool isActive) {
    if (!_mounted) return;
    state = state.copyWith(isActive: isActive, error: null);
  }

  void updateIsAvailable(bool value) {
    state = state.copyWith(isAvailable: value);
  }

  void updateQtyInDecimal(bool value) {
    state = state.copyWith(qtyInDecimal: value);
  }

  void updateProductImage(String value) {
    state = state.copyWith(productImage: value);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelProductFields.productType:
        updateProductType(value as String);
        break;
      case ModelProductFields.productName:
        updateProductName(value as String);
        break;
      case ModelProductFields.productWeightValue:
        updateWeightValue(
          value is double ? value : double.tryParse(value.toString()) ?? 0.0,
        );
        break;
      case ModelProductFields.productWeightUnit:
        updateWeightUnit(value as String);
        break;
      case ModelProductFields.purchaseRateForRetailer:
        updatePurchaseRateForRetailer(
          value is double ? value : double.tryParse(value.toString()) ?? 0.0,
        );
        break;
      case ModelProductFields.mrp:
        updateMrp(
          value is double ? value : double.tryParse(value.toString()) ?? 0.0,
        );
        break;
      case ModelProductFields.packagingType:
        updatePackagingType(value as String);
        break;
      case ModelProductFields.piecesPerOuter:
        updatePiecesPerOuter(
          value is int ? value : int.tryParse(value.toString()),
        );
        break;
      case ModelProductFields.isOuter:
        updateIsOuter(value as bool);
        break;
      case ModelProductFields.isActive:
        updateIsActive(value as bool);
        break;
      case ModelProductFields.isAvailable:
        updateIsAvailable(value as bool);
        break;
      case ModelProductFields.qtyInDecimal:
        updateQtyInDecimal(value as bool);
        break;
      case ModelProductFields.productImage:
        updateProductImage(value as String);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    // Basic validation
    if (state.productType.trim().isEmpty) {
      state = state.copyWith(error: 'Product type is required');
      return false;
    }
    if (state.productName.trim().isEmpty) {
      state = state.copyWith(error: 'Product name is required');
      return false;
    }
    if (state.productWeightUnit.trim().isEmpty) {
      state = state.copyWith(error: 'Weight unit is required');
      return false;
    }
    if (state.packagingType.trim().isEmpty) {
      state = state.copyWith(error: 'Packaging type is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(productServiceProvider);
      final entity = ModelProduct(
        productId: entityId,
        productType: state.productType.trim(),
        productName: state.productName.trim(),
        productWeightValue: state.productWeightValue,
        productWeightUnit: state.productWeightUnit.trim(),
        purchaseRateForRetailer: state.purchaseRateForRetailer,
        mrp: state.mrp,
        packagingType: state.packagingType.trim(),
        piecesPerOuter: state.isOuter ? state.piecesPerOuter : null,
        isOuter: state.isOuter,
        isActive: state.isActive,
        isAvailable: state.isAvailable,
        qtyInDecimal: state.qtyInDecimal,
        productImage: state.productImage.trim(),
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
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to save ${productEntityMeta.entityNameLower}: $e',
        );
      }
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(productServiceProvider);
      await service.deleteEntityById(entityId);

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete ${productEntityMeta.entityNameLower}: $e',
        );
      }
      return false;
    }
  }

  void loadEntity(ModelProduct entity) {
    if (!_mounted) return;
    state = ProductFormState(
      productType: entity.productType,
      productName: entity.productName,
      productWeightValue: entity.productWeightValue,
      productWeightUnit: entity.productWeightUnit,
      purchaseRateForRetailer: entity.purchaseRateForRetailer,
      mrp: entity.mrp,
      packagingType: entity.packagingType,
      piecesPerOuter: entity.piecesPerOuter,
      isOuter: entity.isOuter,
      isActive: entity.isActive,
      isAvailable: entity.isAvailable,
      productImage: entity.productImage ?? '',
    );
  }

  void reset() {
    if (!_mounted) return;
    state = ProductFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}
