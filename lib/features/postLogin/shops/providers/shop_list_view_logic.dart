import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/shop_model.dart';
import 'shop_list_controller.dart';
import 'shop_providers.dart';
import 'shops_by_po_status_provider.dart';

class ProcessedShopListData {
  final List<ModelShop> filteredShops;
  final int? shopCount;
  final bool isLoading;
  final Object? error;

  ProcessedShopListData({
    required this.filteredShops,
    this.shopCount,
    this.isLoading = false,
    this.error,
  });
}

final shopListViewLogicProvider = Provider.autoDispose
    .family<ProcessedShopListData, String?>((ref, tapCondition) {
      final listState = ref.watch(shopListControllerProvider);
      final adapter = ref.watch(shopAdapterProvider);

      // Configuration (matching ShopRoutesJson)
      const routeIdField = 'shops_primary_route';
      const searchFields = ['shop_name', 'shop_person_name'];

      List<ModelShop> filterAndSort(List<ModelShop> entities) {
        var result = entities;

        // 1. Route Filter
        if (listState.selectedRouteId != null) {
          result = result.where((entity) {
            final routeVal = adapter.getFieldValue(entity, routeIdField);
            return routeVal.toString() == listState.selectedRouteId;
          }).toList();
        }

        // 2. Search Filter
        if (listState.searchQuery.isNotEmpty) {
          final query = listState.searchQuery.toLowerCase();
          result = result.where((entity) {
            for (final fieldName in searchFields) {
              dynamic value;
              if (fieldName.endsWith('_label')) {
                final baseFieldName = fieldName.replaceFirst(
                  RegExp(r'_label$'),
                  '',
                );
                value = adapter.getLabelValue(entity, baseFieldName);
              } else {
                value = adapter.getFieldValue(entity, fieldName);
              }

              if (value != null &&
                  value.toString().toLowerCase().contains(query)) {
                return true;
              }
            }
            return false;
          }).toList();
        }

        return result;
      }

      if (tapCondition == 'listWithTodaysEmptyPOs' ||
          tapCondition == 'listWithTodaysFilledPOs' ||
          tapCondition == 'listWithoutTodaysPOs') {
        final poStatusAsync = ref.watch(
          shopsByPOStatusProvider(listState.selectedRouteId),
        );

        return poStatusAsync.when(
          data: (poStatusMap) {
            final rawShops = tapCondition == 'listWithTodaysEmptyPOs'
                ? (poStatusMap['emptyPOs'] ?? []).cast<ModelShop>()
                : tapCondition == 'listWithTodaysFilledPOs'
                ? (poStatusMap['filledPOs'] ?? []).cast<ModelShop>()
                : (poStatusMap['noPOs'] ?? []).cast<ModelShop>();

            return ProcessedShopListData(
              filteredShops: filterAndSort(rawShops),
              shopCount: rawShops.length,
            );
          },
          loading: () =>
              ProcessedShopListData(filteredShops: [], isLoading: true),
          error: (err, _) =>
              ProcessedShopListData(filteredShops: [], error: err),
        );
      } else {
        // Regular list
        final regularShopsAsync = ref.watch(
          regularShopsProvider(listState.selectedRouteId),
        );

        return regularShopsAsync.when(
          data: (entityList) {
            final filtered = filterAndSort(entityList.cast<ModelShop>());
            return ProcessedShopListData(
              filteredShops: filtered,
              shopCount: filtered.length,
            );
          },
          loading: () =>
              ProcessedShopListData(filteredShops: [], isLoading: true),
          error: (err, _) =>
              ProcessedShopListData(filteredShops: [], error: err),
        );
      }
    });
