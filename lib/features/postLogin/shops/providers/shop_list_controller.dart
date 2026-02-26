import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/config/module_config.dart';
import 'shop_providers.dart';

class ShopListState {
  final String searchQuery;
  final String? selectedRouteId;
  final SortingConfig? currentSorting;

  const ShopListState({
    this.searchQuery = '',
    this.selectedRouteId,
    this.currentSorting,
  });

  ShopListState copyWith({
    String? searchQuery,
    String? selectedRouteId,
    SortingConfig? currentSorting,
  }) {
    return ShopListState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      currentSorting: currentSorting ?? this.currentSorting,
    );
  }
}

class ShopListController extends AutoDisposeNotifier<ShopListState> {
  @override
  ShopListState build() {
    // Initialize with user's preferred route
    final profile = ref.watch(userProfileStateProvider).profile;
    final service = ref.read(shopServiceProvider);

    return ShopListState(
      selectedRouteId: profile?.preferredRouteId,
      currentSorting: service.sortField != null
          ? SortingConfig(
              field: service.sortField!,
              sortAscending: service.sortAscending,
            )
          : null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
  }

  void setRouteId(String? routeId) {
    state = state.copyWith(selectedRouteId: routeId);
  }

  void setSorting(SortingConfig? sorting) {
    if (sorting != null) {
      ref
          .read(shopServiceProvider)
          .setSortingConfig(sorting.field, sorting.sortAscending);
    }
    state = state.copyWith(currentSorting: sorting);
    refreshData();
  }

  Future<void> refreshData() async {
    final _ = ref.refresh(shopsStreamProvider.future);
  }
}

final shopListControllerProvider =
    NotifierProvider.autoDispose<ShopListController, ShopListState>(
      () => ShopListController(),
    );
