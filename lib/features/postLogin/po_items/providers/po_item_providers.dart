import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';

import '../adapter/po_item_adapter.dart';
import '../model/po_item_model.dart';
import '../service/po_item_service_impl.dart';
import 'po_item_summary_controller.dart';

/// Mapper provider
final poItemMapperProvider = Provider<EntityMapper<ModelPoItem>>((ref) {
  return ModelPoItemMapper();
});

/// Service provider
final poItemServiceProvider = Provider<PoItemServiceImpl>((ref) {
  return PoItemServiceImpl(
    ref.watch(poItemMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final poItemAdapterProvider = Provider<PoItemAdapter>((ref) {
  return PoItemAdapter();
});

/// Real-time stream of all PO Items with automatic disposal
/// Uses StreamProvider for real-time updates
final poItemsStreamProvider = StreamProvider.autoDispose<List<ModelPoItem>>((
  ref,
) {
  final service = ref.read(poItemServiceProvider);
  return service.streamEntities();
});

/// Fetches a single PO Item by ID
final poItemByIdProvider = FutureProvider.autoDispose
    .family<ModelPoItem?, String>((ref, poItemId) async {
      final service = ref.read(poItemServiceProvider);
      return await service.fetchById(poItemId);
    });

/// State provider for managing PO Item creation/editing
final poItemFormProvider =
    StateNotifierProvider.autoDispose<PoItemFormNotifier, PoItemFormState>(
      (ref) => PoItemFormNotifier(ref),
    );

/// Form state for PO Item
class PoItemFormState {
  final String poId;
  final String itemId;
  final int itemQuantity;
  final double itemPrice;
  final double itemSellRate;
  final double? profitToShop;
  final bool isLoading;
  final String? error;

  PoItemFormState({
    this.poId = '',
    this.itemId = '',
    this.itemQuantity = 0,
    this.itemPrice = 0.0,
    this.itemSellRate = 0.0,
    this.profitToShop,
    this.isLoading = false,
    this.error,
  });

  PoItemFormState copyWith({
    String? poId,
    String? itemId,
    int? itemQuantity,
    double? itemPrice,
    double? itemSellRate,
    double? profitToShop,
    bool? isLoading,
    String? error,
  }) {
    return PoItemFormState(
      poId: poId ?? this.poId,
      itemId: itemId ?? this.itemId,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      itemPrice: itemPrice ?? this.itemPrice,
      itemSellRate: itemSellRate ?? this.itemSellRate,
      profitToShop: profitToShop ?? this.profitToShop,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing PO Item form state
class PoItemFormNotifier extends StateNotifier<PoItemFormState> {
  final Ref ref;
  bool _mounted = true;

  PoItemFormNotifier(this.ref) : super(PoItemFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updatePoId(String poId) {
    if (!_mounted) return;
    state = state.copyWith(poId: poId, error: null);
  }

  void updateItemId(String itemId) {
    if (!_mounted) return;
    state = state.copyWith(itemId: itemId, error: null);
  }

  void updateItemQuantity(int quantity) {
    if (!_mounted) return;
    state = state.copyWith(itemQuantity: quantity, error: null);
  }

  void updateItemPrice(double price) {
    if (!_mounted) return;
    state = state.copyWith(itemPrice: price, error: null);
  }

  void updateItemSellRate(double sellRate) {
    if (!_mounted) return;
    state = state.copyWith(itemSellRate: sellRate, error: null);
  }

  void updateProfitToShop(double? profit) {
    if (!_mounted) return;
    state = state.copyWith(profitToShop: profit, error: null);
  }

  void setLoading(bool isLoading) {
    if (!_mounted) return;
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    if (!_mounted) return;
    state = state.copyWith(error: error);
  }

  void reset() {
    if (!_mounted) return;
    state = PoItemFormState();
  }
}

/// PO Item Stream by PO ID (filtered by parent PO)
final poItemsByPoIdProvider = StreamProvider.autoDispose
    .family<List<ModelPoItem>, String>((ref, poId) {
      if (poId.isEmpty) {
        return Stream.value([]);
      }

      final service = ref.read(poItemServiceProvider);
      return service.streamItemsByPo(poId);
    });

/// Provider for processed PO summary items (sorted/grouped logic)
final processedPoSummaryItemsProvider = Provider.autoDispose
    .family<AsyncValue<List<ModelPoItem>>, String>((ref, poId) {
      final itemsAsync = ref.watch(poItemsByPoIdProvider(poId));
      final isGrouped = ref.watch(poItemSummaryGroupedProvider);

      return itemsAsync.whenData((items) {
        if (!isGrouped) return items;

        final sortedItems = List<ModelPoItem>.from(items);
        sortedItems.sort((a, b) {
          final typeA =
              a.resolvedLabels['product_type_label']?.toString() ?? '';
          final typeB =
              b.resolvedLabels['product_type_label']?.toString() ?? '';
          return typeA.compareTo(typeB);
        });
        return sortedItems;
      });
    });
