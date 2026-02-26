import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../po_items/model/po_item_model.dart';

class CartStorageService {
  static const String _pendingOrderKey = 'pending_order';

  Future<void> savePendingOrder(List<ModelPoItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = json.encode(
        items.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_pendingOrderKey, itemsJson);
      debugPrint(
        '[CartStorageService] Saved ${items.length} items to pending order.',
      );
    } catch (e) {
      debugPrint('[CartStorageService] Error saving pending order: $e');
      rethrow;
    }
  }

  Future<List<ModelPoItem>?> loadPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOrderJson = prefs.getString(_pendingOrderKey);
      if (pendingOrderJson == null) return null;

      final List<dynamic> itemsJson = json.decode(pendingOrderJson);
      return itemsJson.map((item) => ModelPoItem.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[CartStorageService] Error loading pending order: $e');
      return null;
    }
  }

  Future<void> clearPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOrderKey);
      debugPrint('[CartStorageService] Cleared pending order.');
    } catch (e) {
      debugPrint('[CartStorageService] Error clearing pending order: $e');
    }
  }
}
