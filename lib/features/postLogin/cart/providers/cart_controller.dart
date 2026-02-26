import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/cart_storage_service.dart';
import '../services/cart_order_service.dart';
import 'cart_providers.dart';
import 'cart_view_logic.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/router/app_routes.dart';
import '../../purchase_orders/purchase_order_barrel.dart';
import '../../po_items/providers/po_item_providers.dart';

final cartStorageServiceProvider = Provider((ref) => CartStorageService());

final cartOrderServiceProvider = Provider(
  (ref) => CartOrderService(
    client: ref.watch(supabaseClientProvider),
    poService: ref.watch(purchaseOrderServiceProvider),
    poItemService: ref.watch(poItemServiceProvider),
  ),
);

class CartController {
  final Ref ref;
  final CartStorageService _storageService;
  final CartOrderService _orderService;

  CartController(this.ref)
    : _storageService = ref.read(cartStorageServiceProvider),
      _orderService = ref.read(cartOrderServiceProvider);

  Future<void> initPendingOrder(BuildContext context) async {
    final items = await _storageService.loadPendingOrder();
    if (items == null || items.isEmpty) return;

    ref.read(cartProvider.notifier).clearCart();
    for (final item in items) {
      ref.read(cartProvider.notifier).addItem(item);
    }

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
        final confirm = await _showConfirmDialog(
          context: context,
          title: 'Place Pending Order?',
          message: 'You’re now logged in. Do you want to place this order?',
          confirmLabel: 'Place Order',
          confirmColor: Colors.green,
        );

        if (confirm == true) {
          final viewData = ref.read(cartViewLogicProvider);
          await placeOrder(context, viewData, isPending: true);
        }
        // Always clear after showing dialog
        await _storageService.clearPendingOrder();
      } else if (roleName != null) {
        // If role is determined but NOT guest/retailer, clear it
        await _storageService.clearPendingOrder();
      }
    });
  }

  Future<void> handleOrderAction(
    BuildContext context,
    ProcessedCartData viewData,
  ) async {
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) {
      await _storageService.savePendingOrder(ref.read(cartProvider).items);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart saved. Please login to complete your order.'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pushNamed(AppRoute.loginName);
      }
      return;
    }

    final roleName = ref.read(roleNameProvider)?.toLowerCase();
    final isAuthorized =
        roleName == 'salesperson' ||
        roleName == 'guest' ||
        roleName == 'retailer';

    if (!isAuthorized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only guest, salesperson, and retailer can place orders.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirm = await _showConfirmDialog(
      context: context,
      title: 'Place Order?',
      message: 'Are you sure you want to place this order?',
      confirmLabel: 'Confirm',
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
    try {
      final userId = ref.read(supabaseClientProvider).auth.currentUser!.id;
      final roleName = ref.read(roleNameProvider);

      await _orderService.placeOrder(
        viewData: viewData,
        userId: userId,
        roleName: roleName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully')),
        );
      }
      ref.read(cartProvider.notifier).clearCart();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> clearCart(BuildContext context) async {
    final confirm = await _showConfirmDialog(
      context: context,
      title: 'Empty Cart?',
      message: 'Remove all items?',
      confirmLabel: 'Clear All',
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
}

final cartControllerProvider = Provider((ref) => CartController(ref));
