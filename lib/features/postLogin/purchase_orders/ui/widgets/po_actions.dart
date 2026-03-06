import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_supabase_order_app_mobile/core/services/entity_service.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/model/purchase_order_model.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/providers/purchase_order_tile_logic.dart';
import '../purchase_order_share_preview_page.dart';

class PoActions extends ConsumerWidget {
  final ModelPurchaseOrder entity;
  final EntityAdapter<ModelPurchaseOrder> adapter;
  final bool showShare;
  final bool canDelete;
  final String status;
  final bool isUpdating;
  final ValueChanged<bool> onUpdating;

  const PoActions({
    super.key,
    required this.entity,
    required this.adapter,
    this.showShare = true,
    this.canDelete = true,
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
        // View Shop Button
        if (entity.poShopId != null)
          _IconButton(
            icon: Icons.store,
            color: theme.colorScheme.primary,
            onPressed: () => context.pushNamed(
              'viewShop',
              pathParameters: {'id': entity.poShopId!},
            ),
          ),

        // Share Button
        // Share Button (Only if delivered)
        if (showShare && status.toLowerCase() == 'delivered')
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

        // Payment Collection Button
        if (status.toLowerCase() == 'delivered')
          _IconButton(
            icon: Icons.payment,
            color: Colors.green,
            onPressed: () => context.pushNamed(
              'purchase_order_collection',
              pathParameters: {'poId': entity.poId!},
            ),
          ),

        // Delete Button
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
