import '../../../../core/services/entity_service.dart';
import '../../po_items/model/po_item_model.dart';
import '../model/purchase_order_model.dart';

class OrderCardPart {
  final ModelPurchaseOrder order;
  final List<ModelPoItem> items;
  final int partIndex;
  final int totalParts;
  final int globalIndex;

  OrderCardPart({
    required this.order,
    required this.items,
    required this.partIndex,
    required this.totalParts,
    required this.globalIndex,
  });
}

class CollectionSheetGroup {
  final String type;
  final List<ModelPoItem> items;
  final double totalQty;
  final String unit;

  CollectionSheetGroup({
    required this.type,
    required this.items,
    required this.totalQty,
    required this.unit,
  });
}

class CollectionSheetResult {
  final Map<String, List<ModelPurchaseOrder>> ordersByRoute;
  final List<String> sortedRoutes;

  CollectionSheetResult({
    required this.ordersByRoute,
    required this.sortedRoutes,
  });
}

class PdfDataProcessor {
  /// Process raw orders and items into chunked card parts for Bill PDF
  static List<OrderCardPart> processForBillPdf({
    required List<ModelPurchaseOrder> orders,
    required List<List<ModelPoItem>> allItems,
    int maxItemsPerCard = 15,
    Map<String, bool>? splitPreferences,
  }) {
    final List<OrderCardPart> cardParts = [];

    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      final items = List<ModelPoItem>.from(allItems[i]);

      // 1. Group by product type by sorting
      items.sort((a, b) {
        final typeA = a.resolvedLabels['product_type_label']?.toString() ?? '';
        final typeB = b.resolvedLabels['product_type_label']?.toString() ?? '';
        return typeA.compareTo(typeB);
      });

      if (items.isEmpty) {
        cardParts.add(
          OrderCardPart(
            order: order,
            items: [],
            partIndex: 1,
            totalParts: 1,
            globalIndex: i + 1,
          ),
        );
        continue;
      }

      // Check for split preference
      bool shouldSplit = true;
      if (splitPreferences != null && order.poId != null) {
        shouldSplit = splitPreferences[order.poId!] ?? true;
      }

      final int currentMaxItems = shouldSplit
          ? maxItemsPerCard
          : (items.length > 0 ? items.length : 1);

      // 2. Split into parts based on currentMaxItems
      final int totalParts = (items.length / currentMaxItems).ceil();
      for (int p = 0; p < totalParts; p++) {
        final start = p * currentMaxItems;
        final end = (start + currentMaxItems) > items.length
            ? items.length
            : start + currentMaxItems;
        cardParts.add(
          OrderCardPart(
            order: order,
            items: items.sublist(start, end),
            partIndex: p + 1,
            totalParts: totalParts,
            globalIndex: i + 1,
          ),
        );
      }
    }

    return cardParts;
  }

  /// Process raw items into typed groups for Collection Sheet PDF
  static List<CollectionSheetGroup> processForCollectionSheetGroups({
    required List<ModelPoItem> allItems,
  }) {
    final Map<String, List<ModelPoItem>> grouped = {};
    for (var item in allItems) {
      final type =
          item.resolvedLabels['product_type_label']?.toString() ?? 'Other';
      grouped.putIfAbsent(type, () => []).add(item);
    }

    final List<CollectionSheetGroup> groups = [];
    final sortedTypes = grouped.keys.toList()..sort();

    for (var type in sortedTypes) {
      final items = grouped[type]!;
      final totalQty = items.fold<double>(
        0,
        (sum, item) => sum + (item.itemQty ?? 0),
      );
      final unit = items.isNotEmpty
          ? (items.first.productId?.toLowerCase().contains('pouch') ?? false
                ? ''
                : '')
          : '';

      groups.add(
        CollectionSheetGroup(
          type: type,
          items: items,
          totalQty: totalQty,
          unit: unit,
        ),
      );
    }

    return groups;
  }

  /// Group orders by route for Collection Sheet PDF
  static CollectionSheetResult processRouteGrouping({
    required List<ModelPurchaseOrder> orders,
    required EntityAdapter<ModelPurchaseOrder> adapter,
  }) {
    final ordersByRoute = <String, List<ModelPurchaseOrder>>{};
    for (final order in orders) {
      final routeName =
          adapter
              .getLabelValue(order, ModelPurchaseOrderFields.poRouteId)
              ?.toString() ??
          'Unknown Route';
      ordersByRoute.putIfAbsent(routeName, () => []).add(order);
    }

    final sortedRoutes = ordersByRoute.keys.toList()..sort();

    return CollectionSheetResult(
      ordersByRoute: ordersByRoute,
      sortedRoutes: sortedRoutes,
    );
  }
}
