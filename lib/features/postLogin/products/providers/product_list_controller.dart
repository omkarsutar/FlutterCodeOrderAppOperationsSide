import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/entity_service.dart';
import '../model/product_model.dart';

class ProductListState {
  final String searchQuery;
  final String? selectedType;

  const ProductListState({this.searchQuery = '', this.selectedType = null});

  ProductListState copyWith({
    String? searchQuery,
    String? Function()? selectedType,
  }) {
    return ProductListState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType != null ? selectedType() : this.selectedType,
    );
  }
}

class ProductListController extends AutoDisposeNotifier<ProductListState> {
  Timer? _searchDebounce;

  @override
  ProductListState build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    // Explicitly return a state with null selectedType
    return const ProductListState(searchQuery: '', selectedType: null);
  }

  void setSearchQuery(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(
        searchQuery: query.toLowerCase(),
        selectedType: () => null, // Always clear category filter when searching
      );
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    state = state.copyWith(searchQuery: '', selectedType: () => null);
  }

  void setSelectedType(String? type) {
    state = state.copyWith(selectedType: () => type);
  }

  /// Orchestrates navigation or selection when a product is tapped
  void handleProductTap({
    required BuildContext context,
    required ModelProduct product,
    required bool isSelectionMode,
    required String viewRouteName,
    required String idField,
    required EntityAdapter<ModelProduct> adapter,
  }) {
    try {
      if (isSelectionMode) {
        if (context.canPop()) {
          context.pop(product);
        } else {
          debugPrint(
            'ProductListController: Selection mode but nothing to pop',
          );
          // If we can't pop, fall back to pushing the view page as if it weren't selection mode
          context.pushNamed(
            viewRouteName,
            pathParameters: {'id': adapter.getId(product, idField).toString()},
          );
        }
      } else {
        context.pushNamed(
          viewRouteName,
          pathParameters: {'id': adapter.getId(product, idField).toString()},
        );
      }
    } catch (e) {
      debugPrint('ProductListController: Navigation error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Generic helper to filter products based on current state
  List<T> filterEntities<T>({
    required List<T> entities,
    required EntityAdapter<T> adapter,
    List<String>? searchFields,
    bool Function(T, String)? customMatcher,
  }) {
    if (state.searchQuery.isEmpty) return entities;

    return entities.where((entity) {
      // Custom Matcher
      if (customMatcher != null) {
        return customMatcher(entity, state.searchQuery);
      }

      // Default Field Matcher
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

final productListControllerProvider =
    NotifierProvider.autoDispose<ProductListController, ProductListState>(
      () => ProductListController(),
    );
