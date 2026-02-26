import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../po_items/model/po_item_model.dart';
import '../providers/cart_providers.dart';
import '../../products/product_barrel.dart';

class ProcessedCartItem {
  final ModelPoItem item;
  final String productName;
  final String formattedQty;
  final String formattedRate;
  final String formattedAmount;

  ProcessedCartItem({
    required this.item,
    required this.productName,
    required this.formattedQty,
    required this.formattedRate,
    required this.formattedAmount,
  });
}

class ProcessedCartData {
  final List<ProcessedCartItem> items;
  final String totalAmount;
  final String totalProfit;
  final int itemCount;
  final bool isEmpty;

  ProcessedCartData({
    required this.items,
    required this.totalAmount,
    required this.totalProfit,
    required this.itemCount,
    required this.isEmpty,
  });
}

final cartViewLogicProvider = Provider.autoDispose<ProcessedCartData>((ref) {
  final cartState = ref.watch(cartProvider);
  final products = ref.watch(productsStreamProvider).value ?? [];

  String formatQty(num val) {
    String text = val.toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return text;
  }

  final processedItems = cartState.items.map((item) {
    // Resolve product name
    String productName = item.itemName ?? 'Unknown';
    if (productName == 'Unknown') {
      try {
        productName = products
            .firstWhere((p) => p.productId == item.productId)
            .productName;
      } catch (_) {
        productName = 'Unknown';
      }
    }

    return ProcessedCartItem(
      item: item,
      productName: productName,
      formattedQty: formatQty(item.itemQty ?? 0),
      formattedRate: (item.itemSellRate ?? 0).toStringAsFixed(2),
      formattedAmount: (item.itemPrice ?? 0).toStringAsFixed(2),
    );
  }).toList();

  return ProcessedCartData(
    items: processedItems,
    totalAmount: cartState.totalAmount.round().toString(),
    totalProfit: cartState.totalProfit.toStringAsFixed(2),
    itemCount: cartState.items.length,
    isEmpty: cartState.items.isEmpty,
  );
});
