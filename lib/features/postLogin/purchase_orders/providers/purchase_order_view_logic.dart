import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/purchase_order_model.dart';
import 'purchase_order_list_controller.dart';

class ProcessedPurchaseOrderData {
  final List<ModelPurchaseOrder> filteredOrders;
  final Map<String, int> statusCounts;
  final String? activeFabType; // 'bill', 'delivery', null

  ProcessedPurchaseOrderData({
    required this.filteredOrders,
    required this.statusCounts,
    this.activeFabType,
  });
}

final purchaseOrderViewLogicProvider =
    Provider.autoDispose<ProcessedPurchaseOrderData>((ref) {
      final listState = ref.watch(
        purchaseOrderListControllerProvider('purchaseOrderList'),
      );
      final allOrders = listState.allPurchaseOrders;
      final filteredOrders = listState.filteredPurchaseOrders;
      final selectedStatus = listState.selectedStatus?.toLowerCase();

      // 1. Calculate status counts
      final statuses = [
        'All',
        'pending',
        'confirmed',
        'delivered',
        'cancelled',
      ];
      final Map<String, int> statusCounts = {};

      for (final status in statuses) {
        if (status == 'All') {
          statusCounts[status] = allOrders.length;
        } else {
          statusCounts[status] = allOrders
              .where((po) => po.status?.toLowerCase() == status.toLowerCase())
              .length;
        }
      }

      // 2. Determine FAB type
      String? activeFabType;
      if (selectedStatus == 'confirmed') {
        activeFabType = 'bill';
      } else if (selectedStatus == 'delivered') {
        activeFabType = 'delivery';
      }

      return ProcessedPurchaseOrderData(
        filteredOrders: filteredOrders,
        statusCounts: statusCounts,
        activeFabType: activeFabType,
      );
    });
