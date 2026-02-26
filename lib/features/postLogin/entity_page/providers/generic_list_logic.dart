import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/entity_service.dart';
import 'generic_list_controller.dart';

class GenericListLogic {
  /// Filters and sorts a list of entities based on search query
  static List<T> filterEntities<T>({
    required List<T> entities,
    required String searchQuery,
    required EntityAdapter<T> adapter,
    List<String>? searchFields,
    bool Function(T, String)? customMatcher,
  }) {
    if (searchQuery.isEmpty) return entities;

    final query = searchQuery.toLowerCase();

    return entities.where((entity) {
      // 1. Custom Matcher
      if (customMatcher != null) {
        return customMatcher(entity, query);
      }

      // 2. Default Field Matcher
      if (searchFields != null && searchFields.isNotEmpty) {
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

          if (value != null && value.toString().toLowerCase().contains(query)) {
            return true;
          }
        }
        return false;
      }
      return true;
    }).toList();
  }
}

/// Provider for processed list data (using dynamic to support various entity types)
final genericListViewLogicProvider = Provider.autoDispose
    .family<
      List<dynamic>,
      ({
        String controllerKey,
        List<dynamic> allEntities,
        EntityAdapter<dynamic> adapter,
        List<String>? searchFields,
        dynamic customMatcher, // Cast to bool Function(dynamic, String)?
      })
    >((ref, arg) {
      final listState = ref.watch(
        genericListControllerProvider(arg.controllerKey),
      );

      return GenericListLogic.filterEntities<dynamic>(
        entities: arg.allEntities,
        searchQuery: listState.searchQuery,
        adapter: arg.adapter,
        searchFields: arg.searchFields,
        customMatcher: arg.customMatcher as bool Function(dynamic, String)?,
      );
    });
