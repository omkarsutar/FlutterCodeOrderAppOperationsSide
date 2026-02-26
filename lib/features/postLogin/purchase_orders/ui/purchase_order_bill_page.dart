import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/purchase_order_model.dart';
import '../providers/purchase_order_providers.dart';
import '../providers/purchase_order_bill_logic.dart';
import '../providers/purchase_order_bill_controller.dart';
import 'widgets/bill_summary_card.dart';
import 'widgets/bill_po_item_summary_card.dart';
import 'widgets/bill_order_selection_card.dart';

class PurchaseOrderBillPage extends ConsumerWidget {
  final String orderStatus;

  const PurchaseOrderBillPage({super.key, this.orderStatus = 'confirmed'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(purchaseOrdersStreamProvider);
    final adapter = ref.watch(purchaseOrderAdapterProvider);
    final billState = ref.watch(purchaseOrderBillControllerProvider);
    final controller = ref.read(purchaseOrderBillControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Bill PDF'),
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (allOrders) {
          final orders = allOrders
              .where(
                (o) => o.status?.toLowerCase() == orderStatus.toLowerCase(),
              )
              .toList();

          // Initialize selections once
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.initializeSelections(orders);
          });

          // Use the logic provider for processed data
          final billData = ref.watch(
            purchaseOrderBillLogicProvider((
              allOrders: orders,
              selectedPoIds: billState.selectedPoIds,
              adapter: adapter,
            )),
          );

          final sortedOrders = billData.sortedOrders;
          final selectedOrders = billData.selectedOrders;
          final totalAmount = billData.totalAmount;
          final showHeaderAtIndex = billData.showHeaderAtIndex;

          if (billState.isGenerating) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Summary Header
                      SliverToBoxAdapter(
                        child: BillSummaryCard(
                          totalOrdersCount: orders.length,
                          selectedCount: selectedOrders.length,
                          selectedTotal: totalAmount,
                        ),
                      ),

                      // Aggregated Items Summary
                      const BillPoItemSummaryCard(),

                      // Heavy Orders Notification
                      if (billData.heavyOrdersCount > 0)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(12),
                              color: theme.colorScheme.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${billData.heavyOrdersCount} Shop(s) have more than 15 items.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onErrorContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Action PDF Buttons
                      SliverToBoxAdapter(
                        child: _buildActionButtons(
                          context,
                          theme,
                          selectedOrders,
                          adapter,
                          controller,
                        ),
                      ),

                      // Selection Controls
                      SliverToBoxAdapter(
                        child: _buildSelectionControls(
                          theme,
                          sortedOrders,
                          billState.selectedPoIds,
                          controller,
                        ),
                      ),

                      // Order Cards List
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final order = sortedOrders[index];
                            final isSelected = billState.selectedPoIds.contains(
                              order.poId,
                            );
                            final showHeader =
                                showHeaderAtIndex[index] ?? false;

                            final routeName =
                                adapter
                                    .getLabelValue(
                                      order,
                                      ModelPurchaseOrderFields.poRouteId,
                                    )
                                    ?.toString() ??
                                'Unknown Route';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader)
                                  _buildRouteHeader(theme, routeName),
                                BillOrderSelectionCard(
                                  order: order,
                                  adapter: adapter,
                                  isSelected: isSelected,
                                  splitPreference:
                                      billState.splitPreferences[order.poId],
                                  onSelectionChanged: (val) {
                                    if (order.poId != null)
                                      controller.toggleSelection(order.poId!);
                                  },
                                  onSplitChanged: (val) {
                                    if (order.poId != null)
                                      controller.setSplitPreference(
                                        order.poId!,
                                        val ?? true,
                                      );
                                  },
                                ),
                              ],
                            );
                          }, childCount: sortedOrders.length),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    List<ModelPurchaseOrder> selectedOrders,
    dynamic adapter,
    PurchaseOrderBillController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: selectedOrders.isEmpty
                  ? null
                  : () => controller.generateCollectionSheetPdf(
                      context,
                      selectedOrders,
                      adapter,
                    ),
              icon: const Icon(Icons.table_view_outlined),
              label: Text(
                'Collection Sheet (${selectedOrders.length})',
                textAlign: TextAlign.center,
              ),
              style: _actionButtonStyle(
                theme,
                theme.colorScheme.secondary,
                theme.colorScheme.onSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: selectedOrders.isEmpty
                  ? null
                  : () => controller.generateBillPdf(
                      context,
                      selectedOrders,
                      adapter,
                    ),
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(
                'Bill PDF (${selectedOrders.length})',
                textAlign: TextAlign.center,
              ),
              style: _actionButtonStyle(
                theme,
                theme.colorScheme.primary,
                theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _actionButtonStyle(ThemeData theme, Color bg, Color fg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    );
  }

  Widget _buildSelectionControls(
    ThemeData theme,
    List<ModelPurchaseOrder> sortedOrders,
    Set<String> selectedPoIds,
    PurchaseOrderBillController controller,
  ) {
    final allSelected = selectedPoIds.length == sortedOrders.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Orders List',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton.icon(
            onPressed: () => controller.toggleSelectAll(sortedOrders),
            icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
            label: Text(allSelected ? 'Deselect All' : 'Select All'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHeader(ThemeData theme, String routeName) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.directions_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            routeName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
