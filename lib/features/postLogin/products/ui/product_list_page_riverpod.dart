import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/field_config.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/module_config.dart';
import 'package:flutter_supabase_order_app_mobile/core/models/entity_meta.dart';
import 'package:flutter_supabase_order_app_mobile/core/services/entity_service.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/product_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/ui/product_list_tile.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';

class ProductListPageRiverpod<T> extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final bool isSelectionMode;
  final SortingConfig? initialSorting;
  // Riverpod providers
  final ProviderListenable<AsyncValue<List<T>>> streamProvider;
  final Provider<EntityAdapter<T>> adapterProvider;
  final Provider<EntityService<T>> serviceProvider;

  // Search function
  final bool Function(T entity, String query)? searchMatcher;
  final List<String>? searchFields;

  // Custom Item Builder
  final Widget Function(
    BuildContext context,
    T entity,
    EntityAdapter<T> adapter,
    VoidCallback onTap,
  )?
  customItemBuilder;

  const ProductListPageRiverpod({
    super.key,
    required this.entityMeta,
    required this.idField,
    required this.viewRouteName,
    required this.fieldConfigs,
    required this.streamProvider,
    required this.adapterProvider,
    required this.serviceProvider,
    this.searchMatcher,
    this.searchFields,
    this.timestampField,
    required this.newRouteName,
    required this.rbacModule,
    this.isSelectionMode = false,
    this.customItemBuilder,
    this.initialSorting,
  });

  @override
  ConsumerState<ProductListPageRiverpod<T>> createState() =>
      _ProductListPageRiverpodState<T>();
}

class _ProductListPageRiverpodState<T>
    extends ConsumerState<ProductListPageRiverpod<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final service = ref.read(widget.serviceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );

        // Delay autofocus to allow page to render first
        // Only autofocus if user is logged in
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && widget.isSelectionMode) {
            final session = ref
                .read(supabaseClientProvider)
                .auth
                .currentSession;
            if (session != null) {
              _focusNode.requestFocus();
            }
          }
        });
      });
    } else {
      // Still set settled if no sorting config
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && widget.isSelectionMode) {
            final session = ref
                .read(supabaseClientProvider)
                .auth
                .currentSession;
            if (session != null) {
              _focusNode.requestFocus();
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(productListControllerProvider.notifier).setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entitiesAsync = ref.watch(widget.streamProvider);
    final entityAdapter = ref.watch(widget.adapterProvider);
    final filterTypes = ref.watch(productFilterTypesProvider);

    final listState = ref.watch(productListControllerProvider);
    final controller = ref.read(productListControllerProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: widget.isSelectionMode
            ? 'Select ${widget.entityMeta.entityNamePlural}'
            : widget.entityMeta.entityNamePlural,
        showBack: widget.isSelectionMode,
      ),
      drawer: widget.isSelectionMode ? null : const CustomDrawer(),
      floatingActionButton: widget.isSelectionMode
          ? null
          : CreateEntityButton(
              moduleName: widget.rbacModule,
              newRouteName: widget.newRouteName,
              entityLabel: widget.entityMeta.entityName,
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText:
                      'Search ${widget.entityMeta.entityNamePluralLower}...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: listState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            controller.clearSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ),

            // Entity List
            Expanded(
              child: entitiesAsync.when(
                data: (entities) {
                  // Use the SRP-compliant logic provider
                  final viewDataResult = ref.watch(
                    productListViewLogicProvider((
                      entities: entities as List<Object?>,
                      adapter: entityAdapter as EntityAdapter<Object?>,
                      searchFields: widget.searchFields,
                      searchMatcher:
                          widget.searchMatcher
                              as bool Function(Object?, String)?,
                    )),
                  );

                  // Extract pre-processed data
                  final filteredBySearch = viewDataResult.filteredBySearch
                      .cast<T>();
                  final filteredEntities = viewDataResult.filteredEntities
                      .cast<T>();
                  final counts = viewDataResult.counts;
                  final groupedEntities = viewDataResult.groupedEntities.map(
                    (key, value) => MapEntry(key, value.cast<T>()),
                  );
                  final sortedTypes = viewDataResult.sortedTypes;

                  return Column(
                    children: [
                      // Top Filter Pills
                      Container(
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('All (${filteredBySearch.length})'),
                                selected: listState.selectedType == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    controller.setSelectedType(null);
                                  }
                                },
                              ),
                            ),
                            ...filterTypes.map((config) {
                              final displayName = config.keys.first;
                              final filterValue = config.values.first;
                              final count = counts[filterValue] ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('$displayName ($count)'),
                                  selected:
                                      listState.selectedType == filterValue,
                                  onSelected: (selected) {
                                    if (!mounted) return;
                                    if (selected) {
                                      _searchController.clear();
                                      controller.setSelectedType(filterValue);
                                    } else {
                                      controller.setSelectedType(null);
                                    }
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      // Entity List
                      Expanded(
                        child: filteredEntities.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      listState.searchQuery.isEmpty &&
                                              listState.selectedType == null
                                          ? 'No ${widget.entityMeta.entityNamePluralLower} found'
                                          : 'No matching ${widget.entityMeta.entityNamePluralLower}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : CustomScrollView(
                                slivers: [
                                  if (listState.searchQuery.isNotEmpty)
                                    SliverPadding(
                                      padding: const EdgeInsets.all(12),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              childAspectRatio: 0.65,
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 10,
                                            ),
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          final entity =
                                              filteredEntities[index];
                                          return _buildProductTile(
                                            context,
                                            entity,
                                            entityAdapter,
                                          );
                                        }, childCount: filteredEntities.length),
                                      ),
                                    )
                                  else
                                    for (var type in sortedTypes) ...[
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            16,
                                            12,
                                            16,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                type.toUpperCase(),
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                      letterSpacing: 1.2,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Divider(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SliverPadding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        sliver: SliverGrid(
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                childAspectRatio: 0.65,
                                                crossAxisSpacing: 10,
                                                mainAxisSpacing: 10,
                                              ),
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              final entity =
                                                  groupedEntities[type]![index];
                                              return _buildProductTile(
                                                context,
                                                entity,
                                                entityAdapter,
                                              );
                                            },
                                            childCount:
                                                groupedEntities[type]!.length,
                                          ),
                                        ),
                                      ),
                                    ],
                                  const SliverToBoxAdapter(
                                    child: SizedBox(height: 80),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading ${widget.entityMeta.entityNamePluralLower}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(
    BuildContext context,
    T entity,
    EntityAdapter<T> entityAdapter,
  ) {
    if (widget.customItemBuilder != null) {
      return widget.customItemBuilder!(
        context,
        entity,
        entityAdapter,
        () => ref
            .read(productListControllerProvider.notifier)
            .handleProductTap(
              context: context,
              product: entity as ModelProduct,
              isSelectionMode: widget.isSelectionMode,
              viewRouteName: widget.viewRouteName,
              idField: widget.idField,
              adapter: entityAdapter as EntityAdapter<ModelProduct>,
            ),
      );
    }

    // Default: always use ProductListTile
    return ProductListTile(
      entity: entity as ModelProduct,
      adapter: entityAdapter as EntityAdapter<ModelProduct>,
      onTap: () => ref
          .read(productListControllerProvider.notifier)
          .handleProductTap(
            context: context,
            product: entity as ModelProduct,
            isSelectionMode: widget.isSelectionMode,
            viewRouteName: widget.viewRouteName,
            idField: widget.idField,
            adapter: entityAdapter as EntityAdapter<ModelProduct>,
          ),
    );
  }
}
