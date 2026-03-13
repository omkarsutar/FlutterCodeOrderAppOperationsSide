import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../po_items/model/po_item_model.dart';
import '../../products/product_barrel.dart';
import '../services/cart_storage_service.dart';

class CartState {
  final List<ModelPoItem> items;
  final bool isLoading;
  final String? error;
  final String? lastModifiedItemId;
  final bool isPromptAcknowledged;
  final bool isNewItemAdded;

  final String? shopId;
  final String? routeId;
  final String? purchaseOrderId;
  final String? status;
  final int? itemCountInPo;

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.lastModifiedItemId,
    this.isPromptAcknowledged = false,
    this.isNewItemAdded = false,
    this.shopId,
    this.routeId,
    this.purchaseOrderId,
    this.status,
    this.itemCountInPo,
  });

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + (item.itemPrice ?? 0));
  double get totalProfit =>
      items.fold(0, (sum, item) => sum + (item.profitToShop ?? 0));

  bool get isReadOnly {
    if (status == null) return false;
    final s = status!.toLowerCase();
    return s != 'pending' && s != 'confirmed';
  }

  CartState copyWith({
    List<ModelPoItem>? items,
    bool? isLoading,
    String? error,
    String? Function()? lastModifiedItemId,
    bool? isPromptAcknowledged,
    bool? isNewItemAdded,
    String? Function()? shopId,
    String? Function()? routeId,
    String? Function()? purchaseOrderId,
    String? Function()? status,
    int? Function()? itemCountInPo,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastModifiedItemId: lastModifiedItemId != null
          ? lastModifiedItemId()
          : this.lastModifiedItemId,
      isPromptAcknowledged: isPromptAcknowledged ?? this.isPromptAcknowledged,
      isNewItemAdded: isNewItemAdded ?? this.isNewItemAdded,
      shopId: shopId != null ? shopId() : this.shopId,
      routeId: routeId != null ? routeId() : this.routeId,
      purchaseOrderId: purchaseOrderId != null
          ? purchaseOrderId()
          : this.purchaseOrderId,
      status: status != null ? status() : this.status,
      itemCountInPo: itemCountInPo != null
          ? itemCountInPo()
          : this.itemCountInPo,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  Timer? _clearTimer;

  @override
  CartState build() {
    // Start loading from storage on initialization
    Future.microtask(() => _loadFromStorage());
    return CartState(isLoading: true);
  }

  Future<void> _loadFromStorage() async {
    try {
      final storage = ref.read(cartStorageServiceProvider);
      final result = await storage.loadPendingOrder();
      if (result != null) {
        final items = result['items'] as List<ModelPoItem>;
        state = state.copyWith(
          items: items,
          isLoading: false,
          shopId: () => result['shopId'],
          routeId: () => result['routeId'],
          purchaseOrderId: () => result['purchaseOrderId'],
          status: () => result['status'],
          itemCountInPo: () => result['itemCountInPo'],
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final storage = ref.read(cartStorageServiceProvider);
      // Clear storage only if the cart is truly empty (no items AND no linked PO)
      if (state.items.isEmpty && state.purchaseOrderId == null) {
        await storage.clearPendingOrder();
      } else {
        await storage.savePendingOrder(
          state.items,
          shopId: state.shopId,
          routeId: state.routeId,
          purchaseOrderId: state.purchaseOrderId,
          status: state.status,
          itemCountInPo: state.itemCountInPo,
        );
      }
    } catch (e) {
      // In a real app, we might want to log this or show a non-intrusive warning
      state = state.copyWith(error: 'Failed to sync cart: $e');
    }
  }

  void setItems(List<ModelPoItem> items, {bool triggerSave = true}) {
    state = state.copyWith(
      items: items,
      isLoading: false,
      isPromptAcknowledged: false, // Reset for newly loaded items
    );
    if (triggerSave) {
      _saveToStorage();
    }
  }

  void loadOrderIntoCart({
    required String shopId,
    required String routeId,
    required String purchaseOrderId,
    required String status,
    required int itemCountInPo,
    required List<ModelPoItem> items,
  }) {
    state = state.copyWith(
      items: items,
      shopId: () => shopId,
      routeId: () => routeId,
      purchaseOrderId: () => purchaseOrderId,
      status: () => status,
      itemCountInPo: () => itemCountInPo,
      isLoading: false,
      isPromptAcknowledged: true,
    );
    _saveToStorage();
  }

  void setOrderDetails({
    String? shopId,
    String? routeId,
    String? purchaseOrderId,
    String? status,
    int? itemCountInPo,
  }) {
    state = state.copyWith(
      shopId: () => shopId,
      routeId: () => routeId,
      purchaseOrderId: () => purchaseOrderId,
      status: () => status,
      itemCountInPo: () => itemCountInPo,
    );
    _saveToStorage();
  }

  void markPromptAsAcknowledged() {
    state = state.copyWith(isPromptAcknowledged: true);
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
        isPromptAcknowledged: true, // Manual action acknowledges the state
        isNewItemAdded: true,
      );
      _startClearTimer();
      _saveToStorage();
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
        isPromptAcknowledged: true,
        isNewItemAdded: false,
      );
      _startClearTimer();
      _saveToStorage();
    } else {
      // Standard update in place
      state = state.copyWith(
        items: state.items.map((item) {
          return item.poItemId == updatedItem.poItemId ? updatedItem : item;
        }).toList(),
        lastModifiedItemId: () => updatedItem.poItemId,
        isPromptAcknowledged: true,
        isNewItemAdded: false,
      );
      _startClearTimer();
      _saveToStorage();
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
    _saveToStorage();
  }

  void clearCart() {
    state = state.copyWith(
      items: [],
      isPromptAcknowledged: false,
      shopId: () => null,
      routeId: () => null,
      purchaseOrderId: () => null,
      status: () => null,
      itemCountInPo: () => null,
    );
    _saveToStorage();
  }
}

final cartStorageServiceProvider = Provider((ref) => CartStorageService());

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

final isEditingCartItemProvider = StateProvider<bool>((ref) => false);

final selectedProductForAdditionProvider = StateProvider<ModelProduct?>(
  (ref) => null,
);
