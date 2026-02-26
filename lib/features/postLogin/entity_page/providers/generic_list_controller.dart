import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/module_config.dart';

class GenericListState {
  final String searchQuery;
  final SortingConfig? currentSorting;

  const GenericListState({this.searchQuery = '', this.currentSorting});

  GenericListState copyWith({
    String? searchQuery,
    SortingConfig? currentSorting,
  }) {
    return GenericListState(
      searchQuery: searchQuery ?? this.searchQuery,
      currentSorting: currentSorting ?? this.currentSorting,
    );
  }
}

class GenericListController
    extends AutoDisposeFamilyNotifier<GenericListState, String> {
  @override
  GenericListState build(String arg) {
    return const GenericListState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
  }

  void setSorting(SortingConfig? sorting) {
    state = state.copyWith(currentSorting: sorting);
  }
}

/// Key: usually entityName or routeName to isolate state per page usage
final genericListControllerProvider = NotifierProvider.autoDispose
    .family<GenericListController, GenericListState, String>(
      () => GenericListController(),
    );
