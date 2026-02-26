import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/utils/core_utils_barrel.dart';
import '../../../../shared/widgets/shop_bottom_nav.dart';
import '../../purchase_orders/purchase_order_barrel.dart';
import '../model/shop_model.dart';

/// Logic for Shop List Page navigation and actions
class ShopListPageLogic {
  /// Determines the tap action based on tapCondition
  static VoidCallback getOnTapForShop({
    required BuildContext context,
    required ModelShop entity,
    required EntityAdapter<ModelShop> adapter,
    required String? tapCondition,
    required bool isSelectionMode,
    required String viewRouteName,
    required String idField,
    required Future<void> Function(
      BuildContext,
      ModelShop,
      EntityAdapter<ModelShop>,
    )
    handleCreatePO,
  }) {
    // Handle selection mode - pop with selected entity
    if (isSelectionMode) {
      return () => context.pop(entity);
    }

    final shopId = adapter.getFieldValue(entity, ModelShopFields.shopId);

    // Create new PO for shops without today's POs
    if (tapCondition == 'listWithoutTodaysPOs') {
      return () => handleCreatePO(context, entity, adapter);
    }

    // Navigate to PO list for shops with today's POs
    if (tapCondition == 'listWithTodaysEmptyPOs' ||
        tapCondition == 'listWithTodaysFilledPOs') {
      return () => context.pushNamed(
        PurchaseOrdersRoutesJson.listRouteName,
        queryParameters: {
          'filterShopId': shopId,
          'showBackButton': 'true',
          'tapCondition': tapCondition!,
        },
        extra: entity,
      );
    }

    // Default: navigate to shop view page
    return () => context.pushNamed(
      viewRouteName,
      pathParameters: {'id': adapter.getId(entity, idField).toString()},
    );
  }

  /// Handles the complete PO creation workflow
  static Future<void> handleCreatePurchaseOrder({
    required BuildContext context,
    required WidgetRef ref,
    required ModelShop entity,
    required EntityAdapter<ModelShop> adapter,
  }) async {
    final routeId = ref
        .read(userProfileStateProvider)
        .profile
        ?.preferredRouteId;
    final shopId = adapter.getFieldValue(entity, ModelShopFields.shopId);

    // Validation
    if (routeId == null || shopId == null) {
      SnackbarUtils.showError('Missing route or shop ID');
      return;
    }

    // Confirmation dialog
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'New Purchase Order',
      content: 'Are you sure you want to create a new Purchase Order?',
      confirmLabel: 'Create',
    );
    if (!confirmed) return;

    // Create PO
    try {
      await ref
          .read(purchaseOrderServiceProvider)
          .createEmptyPurchaseOrder(poRouteId: routeId, poShopId: shopId);

      if (!context.mounted) return;
      SnackbarUtils.showSuccess('Purchase Order Created');
      if (!context.mounted) return;

      // Navigate to PO list with tapCondition
      final queryParams = getShopQueryParams(context);

      context.pushNamed(
        PurchaseOrdersRoutesJson.listRouteName,
        queryParameters: {
          'filterShopId': shopId,
          if (queryParams.tapCondition != null)
            'tapCondition': queryParams.tapCondition,
          'showBackButton': 'true',
        },
        extra: entity,
      );
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        context: 'Creating purchase order for shop',
        showToUser: true,
      );
    }
  }
}
