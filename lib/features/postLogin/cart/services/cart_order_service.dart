import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../purchase_orders/purchase_order_barrel.dart';
import '../../po_items/model/po_item_model.dart';
import '../../po_items/service/po_item_service_impl.dart';
import '../providers/cart_view_logic.dart';

class CartOrderService {
  final SupabaseClient client;
  final PurchaseOrderServiceImpl poService;
  final PoItemServiceImpl poItemService;

  CartOrderService({
    required this.client,
    required this.poService,
    required this.poItemService,
  });

  Future<void> placeOrder({
    required ProcessedCartData viewData,
    required String userId,
    required String? roleName,
    String? shopId,
    String? routeId,
    String? purchaseOrderId,
  }) async {
    // Check connectivity before placing order
    if (!await ConnectivityService.isOnline()) {
      throw NoInternetException();
    }

    // Default hardcoded IDs for guest and salesperson
    String poShopId =
        shopId ??
        (roleName?.toLowerCase() == 'retailer'
            ? '322d2aeb-34b3-47ef-aa5b-e411add1c7ba'
            : '322d2aeb-34b3-47ef-aa5b-e411add1c7ba');
    String poRouteId =
        routeId ??
        (roleName?.toLowerCase() == 'retailer'
            ? '1ce6a931-4866-4645-a680-102b4b9e923b'
            : '1ce6a931-4866-4645-a680-102b4b9e923b');

    // Handle Retailer specific IDs if not provided
    if (shopId == null && roleName?.toLowerCase() == 'retailer') {
      try {
        final link = await client
            .from('retailer_shop_link')
            .select('shop_id, shops!inner(shops_primary_route)')
            .eq('user_id', userId)
            .maybeSingle();

        if (link != null) {
          poShopId = link['shop_id'] as String;
          poRouteId = link['shops']['shops_primary_route'] as String;
        }
      } catch (e) {
        debugPrint('[CartOrderService] Error fetching retailer link: $e');
      }
    }

    final currentUser = client.auth.currentUser;
    final userEmail = currentUser?.email ?? '';
    final userName =
        currentUser?.userMetadata?['full_name'] ??
        currentUser?.userMetadata?['name'] ??
        userEmail.split('@').first;

    final prefs = await SharedPreferences.getInstance();
    final utmSource = prefs.getString('utm_source') ?? '';

    String userRoleStr = roleName != null ? ' [$roleName]' : '';
    String adminComment = '$userName ($userEmail)$userRoleStr';
    if (utmSource.isNotEmpty) {
      adminComment += ' [UTM: $utmSource]';
    }

    String finalAdminComment = adminComment;
    String? finalUserComment;
    if (purchaseOrderId != null && purchaseOrderId.isNotEmpty) {
      try {
        final existingPo = await poService.fetchById(purchaseOrderId);
        finalUserComment = existingPo.userComment;
        if (existingPo.adminComment != null && existingPo.adminComment!.isNotEmpty) {
          if (!existingPo.adminComment!.contains(adminComment)) {
            finalAdminComment = '${existingPo.adminComment} | $adminComment';
          } else {
            finalAdminComment = existingPo.adminComment!;
          }
        }
      } catch (e) {
        debugPrint('[CartOrderService] Error fetching existing PO comment: $e');
      }
    }

    final po = ModelPurchaseOrder(
      poId: purchaseOrderId,
      poTotalAmount: double.tryParse(viewData.totalAmount.replaceAll(',', '')),
      poLineItemCount: viewData.itemCount,
      poShopId: poShopId,
      poRouteId: poRouteId,
      status: 'confirmed',
      userComment: finalUserComment,
      adminComment: finalAdminComment,
      createdBy: userId,
      updatedBy: userId,
    );

    String finalPoId;
    if (purchaseOrderId != null && purchaseOrderId.isNotEmpty) {
      // Update existing PO
      await poService.update(purchaseOrderId, po);
      finalPoId = purchaseOrderId;
      // Delete old items
      await poItemService.deleteAllByPo(finalPoId);
    } else {
      // Create new PO
      final createdPo = await poService.create(po);
      finalPoId = createdPo.poId ?? '';
    }

    if (finalPoId.isEmpty) {
      throw Exception('Failed to get generated PO ID');
    }

    for (final processedItem in viewData.items) {
      final item = ModelPoItem(
        poItemId: null,
        poId: finalPoId,
        productId: processedItem.item.productId,
        itemName: processedItem.item.itemName,
        itemQty: processedItem.item.itemQty,
        itemSellRate: processedItem.item.itemSellRate,
        itemPrice: processedItem.item.itemPrice,
        itemUnitMrp: processedItem.item.itemUnitMrp,
        profitToShop: processedItem.item.profitToShop,
        createdBy: userId,
        updatedBy: userId,
      );
      await poItemService.create(item);
    }

    // WhatsApp sharing
    await shareOrderToWhatsApp(viewData);
  }

  Future<void> shareOrderToWhatsApp(ProcessedCartData viewData) async {
    final buffer = StringBuffer();
    buffer.writeln('🛒 *Order Details*');
    buffer.writeln('');
    buffer.writeln('Total Items: ${viewData.itemCount}');
    buffer.writeln('');
    buffer.writeln('📋 *Items:*');

    for (var processedItem in viewData.items) {
      buffer.writeln('');
      buffer.writeln('▪️ ${processedItem.productName}');
      buffer.writeln('   Qty: ${processedItem.formattedQty}');
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *Total Amount:* ₹${viewData.totalAmount}');
    buffer.writeln('📈 *Shop Profit:* ₹${viewData.totalProfit}');

    final message = Uri.encodeComponent(buffer.toString());
    final whatsappUrl = 'https://wa.me/919421582162?text=$message';
    final uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('[CartOrderService] Could not launch WhatsApp');
    }
  }
}
