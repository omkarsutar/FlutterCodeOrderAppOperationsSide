import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../po_items/model/po_item_model.dart';
import '../../products/product_barrel.dart';

class CartState {
  final List<ModelPoItem> items;
  final bool isLoading;
  final String? error;
  final String? lastModifiedItemId;
  final bool isNewItemAdded;

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.lastModifiedItemId,
    this.isNewItemAdded = false,
  });

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + (item.itemPrice ?? 0));
  double get totalProfit =>
      items.fold(0, (sum, item) => sum + (item.profitToShop ?? 0));

  CartState copyWith({
    List<ModelPoItem>? items,
    bool? isLoading,
    String? error,
    String? Function()? lastModifiedItemId,
    bool? isNewItemAdded,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastModifiedItemId: lastModifiedItemId != null
          ? lastModifiedItemId()
          : this.lastModifiedItemId,
      isNewItemAdded: isNewItemAdded ?? this.isNewItemAdded,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  Timer? _clearTimer;

  @override
  CartState build() {
    return CartState();
  }

  void addItem(ModelPoItem item) {
    // Check if product already exists in cart, if so update quantity
    final index = state.items.indexWhere((i) => i.productId == item.productId);
    if (index != -1) {
      final existingItem = state.items[index];
      final updatedQty = (existingItem.itemQty ?? 0) + (item.itemQty ?? 0);
      updateItem(
        existingItem.copyWith(
          itemQty: updatedQty,
          itemPrice: (item.itemSellRate ?? 0) * updatedQty,
          profitToShop:
              ((item.itemUnitMrp ?? 0) - (item.itemSellRate ?? 0)) * updatedQty,
        ),
        moveToTop: true,
      );
    } else {
      // Assign a unique local ID if missing
      final itemWithId = item.poItemId == null
          ? item.copyWith(
              poItemId: DateTime.now().microsecondsSinceEpoch.toString(),
            )
          : item;
      state = state.copyWith(
        items: [itemWithId, ...state.items],
        lastModifiedItemId: () => itemWithId.poItemId,
        isNewItemAdded: true,
      );
      _startClearTimer();
    }
  }

  void _startClearTimer() {
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 1500), () {
      state = state.copyWith(
        lastModifiedItemId: () => null,
        isNewItemAdded: false,
      );
    });
  }

  void updateItem(ModelPoItem updatedItem, {bool moveToTop = false}) {
    if (moveToTop) {
      // Remove the item from its current position and prepend it
      final otherItems = state.items
          .where((item) => item.poItemId != updatedItem.poItemId)
          .toList();
      state = state.copyWith(
        items: [updatedItem, ...otherItems],
        lastModifiedItemId: () => updatedItem.poItemId,
        isNewItemAdded: false,
      );
      _startClearTimer();
    } else {
      // Standard update in place
      state = state.copyWith(
        items: state.items.map((item) {
          return item.poItemId == updatedItem.poItemId ? updatedItem : item;
        }).toList(),
        lastModifiedItemId: () => updatedItem.poItemId,
        isNewItemAdded: false,
      );
      _startClearTimer();
    }
  }

  void updateQuantity(String poItemId, double change) {
    final index = state.items.indexWhere((i) => i.poItemId == poItemId);
    if (index == -1) return;

    final item = state.items[index];
    final newQty = (item.itemQty ?? 0) + change;

    if (newQty <= 0) {
      removeItem(poItemId);
    } else {
      updateItem(
        item.copyWith(
          itemQty: newQty,
          itemPrice: (item.itemSellRate ?? 0) * newQty,
          profitToShop:
              ((item.itemUnitMrp ?? 0) - (item.itemSellRate ?? 0)) * newQty,
        ),
      );
    }
  }

  void removeItem(String poItemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.poItemId != poItemId).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

final isEditingCartItemProvider = StateProvider<bool>((ref) => false);

final selectedProductForAdditionProvider = StateProvider<ModelProduct?>(
  (ref) => null,
);
