import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/user_profile_state_provider.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/model/shop_model.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/providers/shop_providers.dart';

/// Provider to fetch shops classified by purchase order item status
/// Returns a map with keys: 'noPOs', 'emptyPOs', 'filledPOs'
final shopsByPOStatusProvider = StreamProvider.autoDispose
    .family<Map<String, List<ModelShop>>, String?>((ref, routeId) {
      final effectiveRouteId = (routeId != null && routeId.isNotEmpty)
          ? routeId
          : ref.watch(userProfileStateProvider).profile?.preferredRouteId;

      final service = ref.read(shopServiceProvider);

      if (effectiveRouteId == null || effectiveRouteId.isEmpty) {
        // emit empty classification
        return Stream.value({
          'noPOs': <ModelShop>[],
          'emptyPOs': <ModelShop>[],
          'filledPOs': <ModelShop>[],
        });
      }

      // service.streamShopsByPOItemStatus already handles classification + sorting
      return service.streamShopsByPOItemStatus(effectiveRouteId);
    });

final regularShopsProvider = FutureProvider.autoDispose
    .family<List<ModelShop>, String?>((ref, routeId) async {
      final effectiveRouteId = (routeId != null && routeId.isNotEmpty)
          ? routeId
          : ref.watch(userProfileStateProvider).profile?.preferredRouteId;

      if (effectiveRouteId == null || effectiveRouteId.isEmpty) return [];

      final service = ref.read(shopServiceProvider);
      return await service.fetchAllShopsForRoute(effectiveRouteId);
    });
