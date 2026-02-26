import 'package:flutter/material.dart';
import '../../model/purchase_order_model.dart';
import 'package:flutter_supabase_order_app_mobile/core/services/entity_service.dart';

class BillOrderSelectionCard extends StatelessWidget {
  final ModelPurchaseOrder order;
  final EntityAdapter<ModelPurchaseOrder> adapter;
  final bool isSelected;
  final bool? splitPreference;
  final ValueChanged<bool?> onSelectionChanged;
  final ValueChanged<bool?> onSplitChanged;

  const BillOrderSelectionCard({
    super.key,
    required this.order,
    required this.adapter,
    required this.isSelected,
    this.splitPreference,
    required this.onSelectionChanged,
    required this.onSplitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopName =
        adapter
            .getLabelValue(order, ModelPurchaseOrderFields.poShopId)
            ?.toString() ??
        'Unknown Shop';
    final totalAmount = (order.poTotalAmount ?? 0).ceil();
    final itemCount = order.poLineItemCount ?? 0;

    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.05)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: () => onSelectionChanged(!isSelected),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: onSelectionChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              shopName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$itemCount items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹$totalAmount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (itemCount > 15) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: splitPreference ?? true,
                            onChanged: onSplitChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Split Bill (Page per 15 items)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
