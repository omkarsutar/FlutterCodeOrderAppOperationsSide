import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/services/entity_service.dart';
import '../model/route_shop_link_model.dart';
import 'route_shop_link_providers.dart';

class RouteShopLinkListState {
  final String searchQuery;
  final String? selectedRouteId;
  final List<ModelRouteShopLink> localEntities;
  final bool isSearchActive; // If we want to move this here too

  const RouteShopLinkListState({
    this.searchQuery = '',
    this.selectedRouteId,
    this.localEntities = const [],
    this.isSearchActive = false,
  });

  RouteShopLinkListState copyWith({
    String? searchQuery,
    String? selectedRouteId,
    List<ModelRouteShopLink>? localEntities,
    bool? isSearchActive,
  }) {
    return RouteShopLinkListState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      localEntities: localEntities ?? this.localEntities,
      isSearchActive: isSearchActive ?? this.isSearchActive,
    );
  }
}

class RouteShopLinkListController
    extends AutoDisposeNotifier<RouteShopLinkListState> {
  @override
  RouteShopLinkListState build() {
    // Initialize with user's preferred route
    final profile = ref.watch(userProfileStateProvider).profile;
    return RouteShopLinkListState(selectedRouteId: profile?.preferredRouteId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
  }

  void setRouteId(String? routeId) {
    if (routeId == null) return;
    state = state.copyWith(
      selectedRouteId: routeId,
      localEntities: [], // Clear on new route
    );
  }

  /// Syncs local entities with data from the source/provider
  void setEntities(List<ModelRouteShopLink> entities) {
    // Only update if the list content has actually changed or we are empty?
    // For now, always sync to keep fresh data.
    state = state.copyWith(localEntities: entities);
  }

  @override
  bool updateShouldNotify(
    RouteShopLinkListState previous,
    RouteShopLinkListState next,
  ) {
    return previous.searchQuery != next.searchQuery ||
        previous.selectedRouteId != next.selectedRouteId ||
        previous.isSearchActive != next.isSearchActive ||
        previous.localEntities != next.localEntities;
  }

  // Reorder logic
  Future<void> reorder(int oldIndex, int newIndex, String idField) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final currentList = state.localEntities;
    final originalList = List<ModelRouteShopLink>.from(currentList);

    // 1. Optimistic Update
    final items = List<ModelRouteShopLink>.from(currentList);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    final updatedList = items.asMap().entries.map((entry) {
      final index = entry.key;
      final entity = entry.value;
      return entity.copyWith(visitOrder: index + 1);
    }).toList();

    state = state.copyWith(localEntities: updatedList);

    // 2. Call Backend
    final movedEntity = updatedList[newIndex];
    final adapter = ref.read(routeShopLinkAdapterProvider);
    final linkId = adapter.getId(movedEntity, idField).toString();
    final newPosition = newIndex + 1;

    try {
      final service = ref.read(routeShopLinkServiceProvider);
      await service.reorderRouteShopLink(linkId, newPosition);
    } catch (e) {
      // Revert on error
      state = state.copyWith(localEntities: originalList);
      rethrow; // Let UI handle error display
    }
  }

  // Helper filter logic
  List<ModelRouteShopLink> getFilteredEntities({
    bool Function(ModelRouteShopLink, String)? customMatcher,
    List<String>? searchFields,
    required EntityAdapter<ModelRouteShopLink> adapter,
  }) {
    if (state.searchQuery.isEmpty) return state.localEntities;

    return state.localEntities.where((entity) {
      if (customMatcher != null) {
        return customMatcher(entity, state.searchQuery);
      }

      if (searchFields != null && searchFields.isNotEmpty) {
        for (final fieldName in searchFields) {
          dynamic value;
          if (fieldName.endsWith('_label')) {
            final base = fieldName.replaceAll(RegExp(r'_label$'), '');
            value = adapter.getLabelValue(entity, base);
          } else {
            value = adapter.getFieldValue(entity, fieldName);
          }
          if (value != null &&
              value.toString().toLowerCase().contains(state.searchQuery)) {
            return true;
          }
        }
        return false;
      }
      return true;
    }).toList();
  }
}

final routeShopLinkListControllerProvider =
    NotifierProvider.autoDispose<
      RouteShopLinkListController,
      RouteShopLinkListState
    >(() => RouteShopLinkListController());
