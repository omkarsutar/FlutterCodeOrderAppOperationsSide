import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/product_barrel.dart';
import '../model/po_item_model.dart';
import 'po_item_providers.dart';
import '../service/po_item_service_impl.dart';

// State definition
class PoItemListState {
  final bool isLoading;
  final String? error;
  final List<ModelPoItem> items;
  final List<ModelProduct> products;
  final String? lastModifiedItemId;
  final bool isNewItemAdded;

  const PoItemListState({
    this.isLoading = true,
    this.error,
    this.items = const [],
    this.products = const [],
    this.lastModifiedItemId,
    this.isNewItemAdded = false,
  });

  PoItemListState copyWith({
    bool? isLoading,
    String? error,
    List<ModelPoItem>? items,
    List<ModelProduct>? products,
    String? Function()? lastModifiedItemId,
    bool? isNewItemAdded,
  }) {
    return PoItemListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      products: products ?? this.products,
      lastModifiedItemId: lastModifiedItemId != null
          ? lastModifiedItemId()
          : this.lastModifiedItemId,
      isNewItemAdded: isNewItemAdded ?? this.isNewItemAdded,
    );
  }
}

// Controller
class PoItemListController
    extends AutoDisposeFamilyAsyncNotifier<PoItemListState, String> {
  PoItemServiceImpl get _service => ref.read(poItemServiceProvider);
  Timer? _clearTimer;

  @override
  Future<PoItemListState> build(String poId) async {
    try {
      // Use cached products stream
      final products = await ref.watch(productsStreamProvider.future);

      // Fetch PO items (service now handles sorting)
      final items = await _service.fetchEntitiesByPo(poId);

      return PoItemListState(
        isLoading: false,
        items: items,
        products: products,
      );
    } catch (e) {
      return PoItemListState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addItem(ModelPoItem item, String poId) async {
    try {
      final currentData = state.value;
      if (currentData == null) return false;

      final newItem = await _service.insertEntityForPo(item, poId);
      state = AsyncValue.data(
        currentData.copyWith(
          items: [newItem, ...currentData.items],
          lastModifiedItemId: () => newItem.poItemId,
          isNewItemAdded: true,
        ),
      );
      _startClearTimer();
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  void _startClearTimer() {
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 1500), () {
      final currentData = state.value;
      if (currentData != null) {
        state = AsyncValue.data(
          currentData.copyWith(
            lastModifiedItemId: () => null,
            isNewItemAdded: false,
          ),
        );
      }
    });
  }

  Future<bool> updateItem(
    ModelPoItem item,
    String poId, {
    bool moveToTop = false,
  }) async {
    try {
      if (item.poItemId == null) throw Exception("Item ID missing for update");
      await _service.update(item.poItemId!, item);
      final currentData = state.value;
      if (currentData != null) {
        List<ModelPoItem> updatedItems;
        if (moveToTop) {
          final others = currentData.items.where(
            (i) => i.poItemId != item.poItemId,
          );
          updatedItems = [item, ...others];
        } else {
          updatedItems = currentData.items
              .map((i) => i.poItemId == item.poItemId ? item : i)
              .toList();
        }

        state = AsyncValue.data(
          currentData.copyWith(
            items: updatedItems,
            lastModifiedItemId: () => item.poItemId,
            isNewItemAdded: false,
          ),
        );
        _startClearTimer();
      } else {
        state = await AsyncValue.guard(() => build(poId));
      }
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteItem(String itemId, String poId) async {
    try {
      await _service.delete(itemId);
      state = await AsyncValue.guard(() => build(poId));
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final poItemListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PoItemListController, PoItemListState, String>(
      () => PoItemListController(),
    );
