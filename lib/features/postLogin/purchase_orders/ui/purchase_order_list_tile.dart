import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/date_utils.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/entity_service.dart';
import '../../po_items/po_item_barrel.dart';
import '../model/purchase_order_model.dart';
import '../providers/purchase_order_tile_logic.dart';
import 'purchase_order_share_preview_page.dart';

class PurchaseOrderListTile extends ConsumerStatefulWidget {
  final ModelPurchaseOrder entity;
  final EntityAdapter<ModelPurchaseOrder> adapter;
  final VoidCallback? onTap;
  final bool? poItemTile;
  final bool showShare;
  final void Function(String oldStatus, String newStatus)? onStatusChanged;

  const PurchaseOrderListTile({
    super.key,
    required this.entity,
    required this.adapter,
    this.onTap,
    this.poItemTile,
    this.showShare = false,
    this.onStatusChanged,
  });

  @override
  ConsumerState<PurchaseOrderListTile> createState() =>
      _PurchaseOrderListTileState();
}

class _PurchaseOrderListTileState extends ConsumerState<PurchaseOrderListTile> {
  bool _isExpanded = false;
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRbacReady = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    final canUpdate = isRbacReady && rbacService.canUpdate('purchase_order');
    final canDelete = isRbacReady && rbacService.canDelete('purchase_order');

    final dateStr = widget.entity.createdAt != null
        ? formatTimestamp(widget.entity.createdAt!)
        : '';
    final shopName =
        widget.adapter
            .getLabelValue(widget.entity, ModelPurchaseOrderFields.poShopId)
            ?.toString() ??
        'Unknown Shop';
    final routeName =
        widget.adapter
            .getLabelValue(widget.entity, ModelPurchaseOrderFields.poRouteId)
            ?.toString() ??
        'Unknown Route';
    final status = widget.entity.status ?? 'pending';
    final itemCount = widget.entity.poLineItemCount ?? 0;
    final commentStr = widget.entity.userComment ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            widget.onTap ??
            () {
              final poId = widget.entity.poId;
              if (poId != null) {
                context.pushNamed(
                  'poItemListForPO',
                  pathParameters: {'poId': poId},
                );
              }
            },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.poItemTile != true) ...[
                _buildHeader(theme, dateStr, status, canUpdate),
                const SizedBox(height: 8),
              ],
              _buildShopInfo(context, theme, shopName, canDelete, status),
              const SizedBox(height: 4),
              _buildRouteInfo(theme, routeName),
              const SizedBox(height: 8),
              _buildStatsRow(theme, itemCount),
              if (_isExpanded && widget.entity.poId != null) ...[
                const SizedBox(height: 16),
                PoItemSummaryList(poId: widget.entity.poId!, status: status),
              ],
              if (commentStr.isNotEmpty) _buildComment(theme, commentStr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    String dateStr,
    String status,
    bool canUpdate,
  ) {
    final statusColor = PurchaseOrderTileLogic.getStatusColor(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            dateStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_isUpdating)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (canUpdate)
          _StatusSelector(
            status: status,
            statusColor: statusColor,
            onChanged: (newValue) async {
              if (newValue != null && newValue != status) {
                final success = await PurchaseOrderTileLogic.updateStatus(
                  context: context,
                  ref: ref,
                  entity: widget.entity,
                  newStatus: newValue,
                  setUpdating: (updating) {
                    if (mounted) setState(() => _isUpdating = updating);
                  },
                );
                if (success) widget.onStatusChanged?.call(status, newValue);
              }
            },
          )
        else
          _StatusBadge(status: status, statusColor: statusColor),
      ],
    );
  }

  Widget _buildShopInfo(
    BuildContext context,
    ThemeData theme,
    String shopName,
    bool canDelete,
    String status,
  ) {
    return Row(
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
        _OrderActions(
          entity: widget.entity,
          adapter: widget.adapter,
          showShare: widget.showShare,
          canDelete: canDelete,
          status: status,
          isUpdating: _isUpdating,
          onUpdating: (val) {
            if (mounted) setState(() => _isUpdating = val);
          },
        ),
      ],
    );
  }

  Widget _buildRouteInfo(ThemeData theme, String routeName) {
    return Text(
      'Route: $routeName',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatsRow(ThemeData theme, int itemCount) {
    final profitStr = PurchaseOrderTileLogic.formatCurrency(
      widget.entity.profitToShop,
    );
    final amountStr = PurchaseOrderTileLogic.formatCurrency(
      widget.entity.poTotalAmount,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (itemCount > 0)
          _ExpandToggle(
            isExpanded: _isExpanded,
            onToggle: () => setState(() => _isExpanded = !_isExpanded),
          ),
        _StatItem(label: 'Items', value: '$itemCount'),
        _StatItem(
          label: 'Shop Profit',
          value: '₹$profitStr',
          valueColor: Colors.green,
        ),
        _StatItem(
          label: 'Total Amount',
          value: '₹$amountStr',
          valueColor: theme.colorScheme.primary,
          crossAxisAlignment: CrossAxisAlignment.end,
        ),
      ],
    );
  }

  Widget _buildComment(ThemeData theme, String commentStr) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        'Comment: $commentStr',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String status;
  final Color statusColor;
  final ValueChanged<String?> onChanged;

  const _StatusSelector({
    required this.status,
    required this.statusColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status.toLowerCase(),
          icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          onChanged: onChanged,
          items: PurchaseOrderTileLogic.statusOptions
              .map(
                (s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color statusColor;

  const _StatusBadge({required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
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

class _OrderActions extends ConsumerWidget {
  final ModelPurchaseOrder entity;
  final EntityAdapter<ModelPurchaseOrder> adapter;
  final bool showShare;
  final bool canDelete;
  final String status;
  final bool isUpdating;
  final ValueChanged<bool> onUpdating;

  const _OrderActions({
    required this.entity,
    required this.adapter,
    required this.showShare,
    required this.canDelete,
    required this.status,
    required this.isUpdating,
    required this.onUpdating,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entity.poShopId != null)
          _IconButton(
            icon: Icons.store,
            color: theme.colorScheme.primary,
            onPressed: () => context.pushNamed(
              'viewShop',
              pathParameters: {'id': entity.poShopId!},
            ),
          ),
        if (entity.poShopId != null && showShare)
          _IconButton(
            icon: Icons.share,
            color: theme.colorScheme.secondary,
            onPressed: () => showDialog(
              context: context,
              useSafeArea: false,
              builder: (context) => PurchaseOrderSharePreviewPage(
                entity: entity,
                adapter: adapter,
              ),
            ),
          ),
        if (status.toLowerCase() == 'delivered')
          _IconButton(
            icon: Icons.payment,
            color: Colors.green,
            onPressed: () => context.pushNamed(
              'purchase_order_collection',
              pathParameters: {'poId': entity.poId!},
            ),
          ),
        if (canDelete &&
            status.toLowerCase() == 'cancelled' &&
            entity.poId != null)
          _IconButton(
            icon: Icons.delete_forever,
            color: Colors.red,
            onPressed: isUpdating
                ? null
                : () => PurchaseOrderTileLogic.deleteOrder(
                    context: context,
                    ref: ref,
                    poId: entity.poId!,
                    setUpdating: onUpdating,
                  ),
          ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _IconButton({required this.icon, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      color: color,
    );
  }
}

class _ExpandToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandToggle({required this.isExpanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 32,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final CrossAxisAlignment crossAxisAlignment;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
