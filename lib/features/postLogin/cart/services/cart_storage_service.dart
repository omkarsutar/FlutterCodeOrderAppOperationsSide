import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../po_items/model/po_item_model.dart';

class CartStorageService {
  static const String _pendingOrderKey = 'pending_order';
  static const String _orderMetadataKey = 'order_metadata';

  Future<void> savePendingOrder(
    List<ModelPoItem> items, {
    String? shopId,
    String? routeId,
    String? purchaseOrderId,
    String? status,
    int? itemCountInPo,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = json.encode(
        items.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_pendingOrderKey, itemsJson);

      final metadata = {
        'shopId': shopId,
        'routeId': routeId,
        'purchaseOrderId': purchaseOrderId,
        'status': status,
        'itemCountInPo': itemCountInPo,
      };
      await prefs.setString(_orderMetadataKey, json.encode(metadata));

      debugPrint(
        '[CartStorageService] Saved ${items.length} items and metadata to pending order.',
      );
    } catch (e) {
      debugPrint('[CartStorageService] Error saving pending order: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loadPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOrderJson = prefs.getString(_pendingOrderKey);
      if (pendingOrderJson == null) return null;

      final List<dynamic> itemsJson = json.decode(pendingOrderJson);
      final items = itemsJson
          .map((item) => ModelPoItem.fromJson(item))
          .toList();

      final metadataJson = prefs.getString(_orderMetadataKey);
      final Map<String, dynamic> metadata = metadataJson != null
          ? json.decode(metadataJson)
          : {};

      return {'items': items, ...metadata};
    } catch (e) {
      debugPrint('[CartStorageService] Error loading pending order: $e');
      return null;
    }
  }

  Future<void> clearPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOrderKey);
      await prefs.remove(_orderMetadataKey);
      debugPrint('[CartStorageService] Cleared pending order and metadata.');
    } catch (e) {
      debugPrint('[CartStorageService] Error clearing pending order: $e');
    }
  }
}
