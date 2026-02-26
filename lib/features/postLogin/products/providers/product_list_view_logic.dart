import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/entity_service.dart';
import '../model/product_model.dart';
import 'product_list_controller.dart';
import 'product_providers.dart';

class ProcessedProductListData<T> {
  final List<T> filteredBySearch;
  final List<T> filteredEntities;
  final Map<String, int> counts;
  final Map<String, List<T>> groupedEntities;
  final List<String> sortedTypes;

  ProcessedProductListData({
    required this.filteredBySearch,
    required this.filteredEntities,
    required this.counts,
    required this.groupedEntities,
    required this.sortedTypes,
  });
}

/// Provider to handle all data processing for the product list page
final productListViewLogicProvider = Provider.autoDispose
    .family<
      ProcessedProductListData<Object?>,
      ({
        List<Object?> entities,
        EntityAdapter<Object?> adapter,
        List<String>? searchFields,
        bool Function(Object?, String)? searchMatcher,
      })
    >((ref, params) {
      final entities = params.entities;
      final adapter = params.adapter;
      final filterTypes = ref.watch(productFilterTypesProvider);
      final listState = ref.watch(productListControllerProvider);
      final controller = ref.read(productListControllerProvider.notifier);

      // 1. Filter entities based on search
      final filteredBySearch = controller.filterEntities(
        entities: entities,
        adapter: adapter,
        searchFields: params.searchFields,
        customMatcher: params.searchMatcher,
      );

      // 2. Calculate counts for each filter type (based on search results)
      final Map<String, int> counts = {};
      for (var entity in filteredBySearch) {
        final type =
            adapter
                .getFieldValue(entity, ModelProductFields.productType)
                ?.toString() ??
            'Other';
        counts[type] = (counts[type] ?? 0) + 1;
      }

      // 3. Filter entities by selected type
      final filteredEntities = filteredBySearch.where((entity) {
        if (listState.selectedType == null) return true;
        final type = adapter
            .getFieldValue(entity, ModelProductFields.productType)
            ?.toString();
        return type == listState.selectedType;
      }).toList();

      // 4. Sort alphabetically by product name
      filteredEntities.sort((a, b) {
        final nameA =
            adapter
                .getFieldValue(a, ModelProductFields.productName)
                ?.toString()
                .toLowerCase() ??
            '';
        final nameB =
            adapter
                .getFieldValue(b, ModelProductFields.productName)
                ?.toString()
                .toLowerCase() ??
            '';
        return nameA.compareTo(nameB);
      });

      // 5. Group the filtered entities
      final Map<String, List<Object?>> groupedEntities = {};
      for (var entity in filteredEntities) {
        final type =
            adapter
                .getFieldValue(entity, ModelProductFields.productType)
                ?.toString() ??
            'Other';
        groupedEntities.putIfAbsent(type, () => []).add(entity);
      }

      // 6. Sort the types based on filterTypes order
      final listOrder = filterTypes.map((e) => e.values.first).toList();
      final sortedTypes = groupedEntities.keys.toList()
        ..sort((a, b) {
          final indexA = listOrder.indexOf(a);
          final indexB = listOrder.indexOf(b);
          if (indexA != -1 && indexB != -1) {
            return indexA.compareTo(indexB);
          }
          return a.compareTo(b);
        });

      return ProcessedProductListData(
        filteredBySearch: filteredBySearch,
        filteredEntities: filteredEntities,
        counts: counts,
        groupedEntities: groupedEntities,
        sortedTypes: sortedTypes,
      );
    });
