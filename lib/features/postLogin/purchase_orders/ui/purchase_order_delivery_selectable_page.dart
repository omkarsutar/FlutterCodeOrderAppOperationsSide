import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../model/purchase_order_model.dart';
import '../../po_items/providers/po_item_providers.dart';

class PurchaseOrderDeliverySelectablePage extends ConsumerWidget {
  final List<ModelPurchaseOrder> orders;
  final dynamic adapter;

  const PurchaseOrderDeliverySelectablePage({
    super.key,
    required this.orders,
    required this.adapter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selectable Delivery Data'),
        actions: const [
          Tooltip(
            message: 'Highlight and copy the table data into Google Sheets',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.info_outline),
            ),
          ),
        ],
      ),
      body: SelectionArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final shopName =
                adapter
                    .getLabelValue(order, ModelPurchaseOrderFields.poShopId)
                    ?.toString() ??
                'Unknown Shop';
            final routeName =
                adapter
                    .getLabelValue(order, ModelPurchaseOrderFields.poRouteId)
                    ?.toString() ??
                'Unknown Route';

            return Card(
              margin: const EdgeInsets.only(bottom: 24.0),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shopName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy items to Spreadsheet',
                      onPressed: () =>
                          _copyOrderToClipboard(ref, context, order),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Updated: ${DateFormat('dd-MMM-yyyy').format(order.updatedAt ?? DateTime.now())} | Route: $routeName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                childrenPadding: const EdgeInsets.all(16.0),
                children: [
                  _OrderItemsTable(orderId: order.poId),
                  const SizedBox(height: 16),
                  Text(
                    'Items: ${order.poLineItemCount ?? 0}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyOrderToClipboard(
    WidgetRef ref,
    BuildContext context,
    ModelPurchaseOrder order,
  ) async {
    try {
      if (order.poId == null) return;

      final messenger = ScaffoldMessenger.of(context);
      final sb = StringBuffer();

      // Fetch items directly from the provider
      final items = await ref.read(poItemsByPoIdProvider(order.poId!).future);

      for (final item in items) {
        final name = item.itemName ?? 'Unknown';
        final qty = _formatQuantity(item.itemQty);
        sb.writeln('$name\t$qty'); // Tab separated, no headers
      }

      await Clipboard.setData(ClipboardData(text: sb.toString()));

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Items copied to clipboard (TSV)!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _formatQuantity(dynamic qty) {
    if (qty == null) return '-';
    final quantity = double.tryParse(qty.toString()) ?? 0.0;
    final rounded = quantity.round();
    if (quantity == rounded) {
      return rounded.toString();
    } else {
      return quantity.toStringAsFixed(1);
    }
  }
}

class _OrderItemsTable extends ConsumerWidget {
  final String? orderId;

  const _OrderItemsTable({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orderId == null) return const Text('No Order ID');

    final itemsAsync = ref.watch(poItemsByPoIdProvider(orderId!));

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const Text('No items found');

        return Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1)},
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blue.shade50),
              children: [
                _buildCell('Item Name', isHeader: true),
                _buildCell('Qty', isHeader: true, alignRight: true),
              ],
            ),
            ...items.asMap().entries.map((entry) {
              final item = entry.value;
              return TableRow(
                children: [
                  _buildCell(item.itemName ?? 'Unknown'),
                  _buildCell(
                    PurchaseOrderDeliverySelectablePage._formatQuantity(
                      item.itemQty,
                    ),
                    alignRight: true,
                  ),
                ],
              );
            }).toList(),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool alignRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }
}
