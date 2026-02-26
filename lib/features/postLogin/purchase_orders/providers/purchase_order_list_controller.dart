import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/entity_service.dart';
import '../../../../core/config/module_config.dart';
import '../model/purchase_order_model.dart';
import '../providers/purchase_order_providers.dart';

/// State for Purchase Order List
class PurchaseOrderListState {
  final String searchQuery;
  final String? selectedStatus; // Added status filter
  final List<ModelPurchaseOrder> allPurchaseOrders; // Original unfiltered list
  final List<ModelPurchaseOrder> filteredPurchaseOrders; // Filtered results
  final SortingConfig? currentSorting;
  final bool isLoading;
  final String? error;

  const PurchaseOrderListState({
    this.searchQuery = '',
    this.selectedStatus,
    this.allPurchaseOrders = const [],
    this.filteredPurchaseOrders = const [],
    this.currentSorting,
    this.isLoading = true,
    this.error,
  });

  PurchaseOrderListState copyWith({
    String? searchQuery,
    String? selectedStatus,
    bool clearStatus = false,
    List<ModelPurchaseOrder>? allPurchaseOrders,
    List<ModelPurchaseOrder>? filteredPurchaseOrders,
    SortingConfig? currentSorting,
    bool? isLoading,
    String? error,
  }) {
    return PurchaseOrderListState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      allPurchaseOrders: allPurchaseOrders ?? this.allPurchaseOrders,
      filteredPurchaseOrders:
          filteredPurchaseOrders ?? this.filteredPurchaseOrders,
      currentSorting: currentSorting ?? this.currentSorting,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PurchaseOrderListController
    extends AutoDisposeFamilyNotifier<PurchaseOrderListState, String> {
  @override
  PurchaseOrderListState build(String arg) {
    final posAsync = ref.watch(purchaseOrdersStreamProvider);
    final service = ref.read(purchaseOrderServiceProvider);
    final searchQuery = ref.watch(purchaseOrderSearchProvider(arg));
    final statusFilter = ref.watch(purchaseOrderStatusFilterProvider(arg));

    if (posAsync.isLoading) {
      return PurchaseOrderListState(
        isLoading: true,
        searchQuery: searchQuery,
        selectedStatus: statusFilter,
        currentSorting: service.sortField != null
            ? SortingConfig(
                field: service.sortField!,
                sortAscending: service.sortAscending,
              )
            : null,
      );
    }

    if (posAsync.hasError) {
      return PurchaseOrderListState(
        isLoading: false,
        searchQuery: searchQuery,
        selectedStatus: statusFilter,
        error: 'Failed to load purchase orders: ${posAsync.error}',
        currentSorting: service.sortField != null
            ? SortingConfig(
                field: service.sortField!,
                sortAscending: service.sortAscending,
              )
            : null,
      );
    }

    final pos = posAsync.value ?? [];
    final adapter = ref.read(purchaseOrderAdapterProvider);

    // Use watched state for filtering
    final filteredAndSorted = _filterAndSortPurchaseOrders(
      pos,
      searchQuery,
      statusFilter,
      adapter,
    );

    return PurchaseOrderListState(
      searchQuery: searchQuery,
      selectedStatus: statusFilter,
      allPurchaseOrders: pos,
      filteredPurchaseOrders: filteredAndSorted,
      currentSorting: service.sortField != null
          ? SortingConfig(
              field: service.sortField!,
              sortAscending: service.sortAscending,
            )
          : null,
      isLoading: false,
      error: null,
    );
  }

  /// Updates the search query and filters the list
  void setSearchQuery(String query, {List<String>? searchFields}) {
    // Update persistent provider - this will trigger build automatically
    ref.read(purchaseOrderSearchProvider(arg).notifier).state = query
        .toLowerCase();
  }

  /// Updates the status filter and filters the list
  void setStatusFilter(String? status, {List<String>? searchFields}) {
    // Update persistent provider - this will trigger build automatically
    ref.read(purchaseOrderStatusFilterProvider(arg).notifier).state = status;
  }

  void setSorting(SortingConfig? sorting, {List<String>? searchFields}) {
    if (sorting != null) {
      ref
          .read(purchaseOrderServiceProvider)
          .setSortingConfig(sorting.field, sorting.sortAscending);
    }

    state = state.copyWith(
      currentSorting: sorting,
      isLoading: true, // Trigger loading state during refresh
    );

    refreshData();
  }

  /// Filters and sorts purchase orders
  List<ModelPurchaseOrder> _filterAndSortPurchaseOrders(
    List<ModelPurchaseOrder> pos,
    String query,
    String? status,
    EntityAdapter<ModelPurchaseOrder> adapter, {
    List<String>? searchFields,
  }) {
    var result = pos;

    // 1. Status Filter
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      result = result.where((po) {
        return po.status?.toLowerCase() == status.toLowerCase();
      }).toList();
    }

    // 2. Search Filter
    if (query.isNotEmpty) {
      result = result.where((po) {
        // Use provided search fields if available
        if (searchFields != null && searchFields.isNotEmpty) {
          for (final fieldName in searchFields) {
            dynamic value;
            if (fieldName.endsWith('_label')) {
              final baseFieldName = fieldName.replaceFirst(
                RegExp(r'_label$'),
                '',
              );
              value = adapter.getLabelValue(po, baseFieldName);
            } else {
              value = adapter.getFieldValue(po, fieldName);
            }

            if (value != null &&
                value.toString().toLowerCase().contains(query)) {
              return true;
            }
          }
        } else {
          // Default fallback search logic
          if (po.poId?.toLowerCase().contains(query) ?? false) return true;

          final shopName = adapter
              .getLabelValue(po, ModelPurchaseOrderFields.poShopId)
              ?.toString()
              .toLowerCase();
          if (shopName?.contains(query) ?? false) return true;

          final routeName = adapter
              .getLabelValue(po, ModelPurchaseOrderFields.poRouteId)
              ?.toString()
              .toLowerCase();
          if (routeName?.contains(query) ?? false) return true;

          if (po.status?.toLowerCase().contains(query) ?? false) return true;
          if (po.userComment?.toLowerCase().contains(query) ?? false)
            return true;
        }

        return false;
      }).toList();
    }

    return result;
  }

  /// Refreshes the purchase orders data
  Future<void> refreshData() async {
    await ref.refresh(purchaseOrdersStreamProvider.future);
  }

  /// Clears the search query
  void clearSearch({List<String>? searchFields}) {
    setSearchQuery('', searchFields: searchFields);
  }

  /// Resets all filters (search and status)
  void resetFilters({List<String>? searchFields}) {
    ref.read(purchaseOrderSearchProvider(arg).notifier).state = '';
    ref.read(purchaseOrderStatusFilterProvider(arg).notifier).state = null;
  }
}

/// Provider for Purchase Order List Controller
/// Key: 'purchaseOrderList' to isolate state per page instance
final purchaseOrderListControllerProvider = NotifierProvider.autoDispose
    .family<PurchaseOrderListController, PurchaseOrderListState, String>(
      () => PurchaseOrderListController(),
    );
