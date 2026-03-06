import 'package:flutter/material.dart';
import '../../providers/purchase_order_tile_logic.dart';

class PoShopRouteInfo extends StatelessWidget {
  final String shopName;
  final String routeName;
  final String? poId;
  final String? status;
  final Widget? trailing;

  const PoShopRouteInfo({
    super.key,
    required this.shopName,
    required this.routeName,
    this.poId,
    this.status,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shopName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                poId != null
                    ? 'Route: $routeName | PO: #$poId'
                    : 'Route: $routeName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (status != null) _buildStatusBadge(context, status!),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    final statusColor = PurchaseOrderTileLogic.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
