import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/cart_order_service.dart';
import 'cart_providers.dart';
import 'cart_view_logic.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/router/app_routes.dart';
import '../../purchase_orders/purchase_order_barrel.dart';
import '../../po_items/providers/po_item_providers.dart';
import '../../po_items/po_item_barrel.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../shops/shop_barrel.dart';
import '../../../../core/globals.dart';

final cartOrderServiceProvider = Provider(
  (ref) => CartOrderService(
    client: ref.watch(supabaseClientProvider),
    poService: ref.watch(purchaseOrderServiceProvider),
    poItemService: ref.watch(poItemServiceProvider),
  ),
);

class CartController {
  final Ref ref;
  final CartOrderService _orderService;

  CartController(this.ref) : _orderService = ref.read(cartOrderServiceProvider);

  Future<void> initPendingOrder(BuildContext context) async {
    // If already acknowledged, don't show
    if (ref.read(cartProvider).isPromptAcknowledged) return;

    // Wait for the cart to finish loading its initial state if it's currently loading
    // This is crucial for post-login redirects where the notifier just started
    if (ref.read(cartProvider).isLoading) {
      // Poll briefly for loading to finish (max 2 seconds)
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!ref.read(cartProvider).isLoading) break;
      }
    }

    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty || cartState.isPromptAcknowledged) return;

    // Show dialog after UI has rebuilt and role is determined
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;

      // Wait for role to be resolved (up to 3 seconds)
      String? roleName;
      for (int i = 0; i < 15; i++) {
        roleName = ref.read(roleNameProvider);
        if (roleName != null) break;
        await Future.delayed(const Duration(milliseconds: 200));
        if (!context.mounted) return;
      }

      final normalizedRole = roleName?.toLowerCase();
      final isGuestOrRetailer =
          normalizedRole == 'guest' || normalizedRole == 'retailer';

      if (isGuestOrRetailer) {
        // Re-check acknowledgement just before showing
        if (!ref.read(cartProvider).isPromptAcknowledged) {
          final l10n = ref.read(l10nProvider);
          final confirm = await _showConfirmDialog(
            context: context,
            title: l10n['place_pending_order_title'] ?? 'Place Pending Order?',
            message:
                l10n['place_pending_order_msg'] ??
                'You have items in your cart. Do you want to place this order now?',
            confirmLabel: l10n['place_order'] ?? 'Place Order',
            confirmColor: Colors.green,
          );

          if (confirm == true) {
            final viewData = ref.read(cartViewLogicProvider);
            await placeOrder(context, viewData, isPending: true);
          }

          // Mark as acknowledged regardless of action
          ref.read(cartProvider.notifier).markPromptAsAcknowledged();
        }
      }
    });
  }

  Future<void> handleOrderAction(
    BuildContext context,
    ProcessedCartData viewData,
  ) async {
    final l10n = ref.read(l10nProvider);
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n['cart_saved_login'] ??
                  'Cart saved. Please login to complete your order.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        context.pushNamed(AppRoute.loginName);
      }
      return;
    }

    final roleName = ref.read(roleNameProvider)?.toLowerCase();
    final isAuthorized = roleName == 'salesperson' || roleName == 'admin';

    if (!isAuthorized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n['only_authorized_order'] ??
                  'Only salesperson and admin can place orders.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Authorized Flow (Salesperson / Admin)
    final cartState = ref.read(cartProvider);
    final poId = cartState.purchaseOrderId;

    if (poId == null || poId.isEmpty) {
      // No PO selected -> Redirect for shop selection
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Redirecting to Today\'s Shops for selection...'),
            backgroundColor: Colors.blue,
          ),
        );
        context.goNamed(
          ShopsRoutesJson.listRouteName,
          queryParameters: {'tapCondition': 'listWithoutTodaysPOs'},
        );
      }
      return;
    }

    // PO already selected -> Confirm and Place/Update
    final bool isUpdate = (cartState.itemCountInPo ?? 0) > 0;
    final String title = isUpdate ? 'Update Order?' : 'Create Order?';
    final String message = isUpdate
        ? 'Are you sure you want to update this order?'
        : 'Are you sure you want to create this purchase order?';

    final confirm = await _showConfirmDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: l10n['confirm'] ?? 'Confirm',
      confirmColor: Colors.green,
    );

    if (confirm == true) {
      await placeOrder(context, viewData);
    }
  }

  Future<void> placeOrder(
    BuildContext context,
    ProcessedCartData viewData, {
    bool isPending = false,
  }) async {
    final l10n = ref.read(l10nProvider);
    // Show loading dialog
    showLoadingDialog(
      context: context,
      message: l10n['please_wait'] ?? 'Placing order...',
    );

    try {
      final userId = ref.read(supabaseClientProvider).auth.currentUser!.id;
      final roleName = ref.read(roleNameProvider);
      final cartState = ref.read(cartProvider);

      await _orderService.placeOrder(
        viewData: viewData,
        userId: userId,
        roleName: roleName,
        shopId: cartState.shopId,
        routeId: cartState.routeId,
        purchaseOrderId: cartState.purchaseOrderId,
      );

      if (context.mounted) {
        // Dismiss loading dialog
        Navigator.of(context).pop();

        // Show premium Thank You dialog
        await _showThankYouDialog(context);
      }
      ref.read(cartProvider.notifier).clearCart();
    } catch (e) {
      if (context.mounted) {
        // Dismiss loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> editPurchaseOrder(
    BuildContext context,
    ModelPurchaseOrder po,
  ) async {
    final l10n = ref.read(l10nProvider);

    // 1. Show loading dialog
    showLoadingDialog(
      context: context,
      message: l10n['please_wait'] ?? 'Loading order details...',
    );

    try {
      final poId = po.poId;
      if (poId == null || poId.isEmpty) throw Exception('Invalid PO ID');

      final dbItems = await ref
          .read(poItemServiceProvider)
          .fetchEntitiesByPo(poId);

      if (context.mounted) {
        final cartState = ref.read(cartProvider);
        final dbItemCount = po.poLineItemCount ?? dbItems.length;
        final localItemCountInPo = cartState.itemCountInPo;

        List<ModelPoItem> itemsToLoad;

        if (dbItemCount == 0) {
          // Incoming PO is in "Create Mode" (empty)
          if (localItemCountInPo == null || localItemCountInPo == 0) {
            // Previous was also "Create Mode" or fresh cart -> KEEP items
            // But update their poId to the new PO
            itemsToLoad = cartState.items
                .map((item) => item.copyWith(poId: poId))
                .toList();
          } else {
            // Previous was a real "Edit Mode" PO -> CLEAR items
            itemsToLoad = [];
          }
        } else {
          // Incoming PO is in "Edit Mode" (has items) -> REPLACE items
          itemsToLoad = dbItems;
        }

        // 3. Update cart with the determined items and metadata
        ref
            .read(cartProvider.notifier)
            .loadOrderIntoCart(
              shopId: po.poShopId ?? '',
              routeId: po.poRouteId ?? '',
              purchaseOrderId: poId,
              status: po.status ?? 'pending',
              itemCountInPo: dbItemCount,
              items: itemsToLoad,
            );

        // 4. Dismiss loading dialog
        Navigator.of(context).pop();

        // 5. Navigate to cart page
        context.pushNamed('cart');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> clearCart(BuildContext context) async {
    final l10n = ref.read(l10nProvider);
    final confirm = await _showConfirmDialog(
      context: context,
      title: l10n['clear_cart_title'] ?? 'Empty Cart?',
      message: l10n['clear_cart_msg'] ?? 'Remove all items?',
      confirmLabel: l10n['clear_all'] ?? 'Clear All',
      confirmColor: Colors.red,
    );
    if (confirm == true) {
      ref.read(cartProvider.notifier).clearCart();
    }
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showThankYouDialog(BuildContext context) {
    final l10n = ref.read(l10nProvider);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green[700],
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n['thank_you'] ?? 'Thank You!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n['order_success'] ??
                      'Your order has been placed successfully.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.goNamed('products');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n['continue_shopping'] ?? 'Continue Shopping',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final cartControllerProvider = Provider((ref) => CartController(ref));
