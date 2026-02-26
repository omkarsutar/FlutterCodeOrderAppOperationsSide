import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/utils/file_save_helper.dart';
import '../../po_items/providers/po_item_providers.dart';
import '../../po_items/model/po_item_model.dart';
import '../model/purchase_order_model.dart';
import '../services/purchase_order_pdf_service.dart';

class PurchaseOrderBillState {
  final Set<String> selectedPoIds;
  final Map<String, bool> splitPreferences;
  final bool isGenerating;
  final bool isInitialized;

  PurchaseOrderBillState({
    required this.selectedPoIds,
    required this.splitPreferences,
    this.isGenerating = false,
    this.isInitialized = false,
  });

  PurchaseOrderBillState copyWith({
    Set<String>? selectedPoIds,
    Map<String, bool>? splitPreferences,
    bool? isGenerating,
    bool? isInitialized,
  }) {
    return PurchaseOrderBillState(
      selectedPoIds: selectedPoIds ?? this.selectedPoIds,
      splitPreferences: splitPreferences ?? this.splitPreferences,
      isGenerating: isGenerating ?? this.isGenerating,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class PurchaseOrderBillController
    extends StateNotifier<PurchaseOrderBillState> {
  final Ref _ref;

  PurchaseOrderBillController(this._ref)
    : super(PurchaseOrderBillState(selectedPoIds: {}, splitPreferences: {}));

  /// Initialize default selections if not already done
  void initializeSelections(List<ModelPurchaseOrder> orders) {
    if (state.isInitialized) return;

    final initialSelections = <String>{};
    for (final order in orders) {
      if (order.poId != null) {
        initialSelections.add(order.poId!);
      }
    }

    state = state.copyWith(
      selectedPoIds: initialSelections,
      isInitialized: true,
    );
  }

  /// Toggle selection for a single PO
  void toggleSelection(String poId) {
    final newSelections = Set<String>.from(state.selectedPoIds);
    if (newSelections.contains(poId)) {
      newSelections.remove(poId);
    } else {
      newSelections.add(poId);
    }
    state = state.copyWith(selectedPoIds: newSelections);
  }

  /// Toggle "Select All" status
  void toggleSelectAll(List<ModelPurchaseOrder> orders) {
    if (state.selectedPoIds.length == orders.length) {
      state = state.copyWith(selectedPoIds: {});
    } else {
      final allIds = orders
          .where((o) => o.poId != null)
          .map((o) => o.poId!)
          .toSet();
      state = state.copyWith(selectedPoIds: allIds);
    }
  }

  /// Set split preference for a specific PO
  void setSplitPreference(String poId, bool split) {
    final newPrefs = Map<String, bool>.from(state.splitPreferences);
    newPrefs[poId] = split;
    state = state.copyWith(splitPreferences: newPrefs);
  }

  /// Generate and layout the Bill PDF
  Future<void> generateBillPdf(
    BuildContext context,
    List<ModelPurchaseOrder> selectedOrders,
    dynamic adapter,
  ) async {
    if (selectedOrders.isEmpty) return;

    state = state.copyWith(isGenerating: true);

    try {
      // Fetch all items for selected orders
      final allItems = <List<ModelPoItem>>[];
      for (final order in selectedOrders) {
        if (order.poId != null) {
          final items = await _ref.read(
            poItemsByPoIdProvider(order.poId!).future,
          );
          allItems.add(items);
        } else {
          allItems.add([]);
        }
      }

      final pdfBytes = await PurchaseOrderPdfService.generateBillPdf(
        selectedOrders,
        allItems,
        adapter,
        splitPreferences: state.splitPreferences,
      );

      final fileName =
          'purchase_orders_bill_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await _handlePdfOutput(context, pdfBytes, fileName);
    } catch (e) {
      _showError(context, 'Error generating Bill PDF: $e');
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }

  /// Generate and layout the Collection Sheet PDF
  Future<void> generateCollectionSheetPdf(
    BuildContext context,
    List<ModelPurchaseOrder> selectedOrders,
    dynamic adapter,
  ) async {
    if (selectedOrders.isEmpty) return;

    state = state.copyWith(isGenerating: true);

    try {
      final pdfBytes = await PurchaseOrderPdfService.generateCollectionSheetPdf(
        selectedOrders,
        adapter,
      );

      final fileName =
          'collection_sheet_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await _handlePdfOutput(context, pdfBytes, fileName);
    } catch (e) {
      _showError(context, 'Error generating Collection Sheet: $e');
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }

  /// Internal helper to handle PDF display or download
  Future<void> _handlePdfOutput(
    BuildContext context,
    dynamic pdfBytes,
    String fileName,
  ) async {
    try {
      await Printing.layoutPdf(onLayout: (format) => pdfBytes, name: fileName);
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        await UniversalFileSaver.saveAndDownloadFile(
          bytes: pdfBytes,
          fileName: fileName,
        );
        _showInfo(context, 'Printing plugin error. PDF downloaded instead.');
      } else {
        rethrow;
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Provider for the Purchase Order Bill Controller
final purchaseOrderBillControllerProvider =
    StateNotifierProvider.autoDispose<
      PurchaseOrderBillController,
      PurchaseOrderBillState
    >((ref) {
      return PurchaseOrderBillController(ref);
    });

class AggregatedPoItem {
  final String itemName;
  final double totalQty;
  final String unit;

  AggregatedPoItem({
    required this.itemName,
    required this.totalQty,
    required this.unit,
  });
}

class AggregatedGroup {
  final String type;
  final List<AggregatedPoItem> products;

  AggregatedGroup({required this.type, required this.products});
}

/// Provider for aggregated items across all selected POs
final billAggregatedItemsProvider =
    FutureProvider.autoDispose<List<AggregatedGroup>>((ref) async {
      final state = ref.watch(purchaseOrderBillControllerProvider);
      final poIds = state.selectedPoIds.toList();

      if (poIds.isEmpty) return [];

      final allItems = <ModelPoItem>[];
      for (final id in poIds) {
        try {
          final items = await ref.read(poItemsByPoIdProvider(id).future);
          allItems.addAll(items);
        } catch (e) {
          debugPrint('Error fetching items for PO $id: $e');
        }
      }

      // Group by Item Type -> Product Name
      final groupedMap = <String, Map<String, AggregatedPoItem>>{};

      for (var item in allItems) {
        final type =
            item.resolvedLabels['product_type_label']?.toString() ?? 'Other';
        final name = item.itemName ?? 'Unknown';
        final unit = item.productId?.toLowerCase().contains('pouch') ?? false
            ? ''
            : '';

        final typeGroup = groupedMap.putIfAbsent(type, () => {});

        if (typeGroup.containsKey(name)) {
          final existing = typeGroup[name]!;
          typeGroup[name] = AggregatedPoItem(
            itemName: name,
            totalQty: existing.totalQty + (item.itemQty ?? 0),
            unit: unit,
          );
        } else {
          typeGroup[name] = AggregatedPoItem(
            itemName: name,
            totalQty: item.itemQty ?? 0,
            unit: unit,
          );
        }
      }

      final List<AggregatedGroup> finalGroups = [];
      final sortedTypes = groupedMap.keys.toList()..sort();

      for (var type in sortedTypes) {
        final products = groupedMap[type]!.values.toList();
        products.sort((a, b) => a.itemName.compareTo(b.itemName));
        finalGroups.add(AggregatedGroup(type: type, products: products));
      }

      return finalGroups;
    });
