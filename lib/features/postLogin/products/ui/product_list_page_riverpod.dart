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
import '../../cart/providers/cart_view_logic.dart';
import '../../cart/providers/cart_providers.dart';
import '../../../../core/providers/localization_provider.dart';
import 'package:go_router/go_router.dart';

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
    extends ConsumerState<ProductListPageRiverpod<T>>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _profitHighlightController;
  late Animation<double> _profitScaleAnimation;
  late Animation<Color?> _profitColorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize profit highlight animation
    _profitHighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _profitScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _profitHighlightController,
            curve: Curves.easeInOut,
          ),
        );

    _profitColorAnimation =
        ColorTween(
          begin: Colors.green.withValues(alpha: 0.2),
          end: Colors.transparent,
        ).animate(
          CurvedAnimation(
            parent: _profitHighlightController,
            curve: Curves.linear,
          ),
        );

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Explicitly set selected type to null (All) on startup
        ref.read(productListControllerProvider.notifier).setSelectedType(null);

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
    _profitHighlightController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(productListControllerProvider.notifier).setSearchQuery(query);
  }

  Widget _buildProfitBox(BuildContext context, WidgetRef ref) {
    final viewData = ref.watch(cartViewLogicProvider);

    return AnimatedBuilder(
      animation: _profitHighlightController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _profitHighlightController.value > 0
                ? _profitColorAnimation.value
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ScaleTransition(
            scale: _profitScaleAnimation,
            child: _buildSummaryItem(
              context,
              ref.watch(l10nProvider)['shop_profit'] ?? 'Shop Profit\nOn MRP',
              '₹${viewData.totalProfit}',
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final labelLines = label.split('\n');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...labelLines
            .map(
              (line) => Text(
                line,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      color?.withValues(alpha: 0.8) ??
                      theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            )
            .toList(),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? theme.colorScheme.primary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCartAction(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cartState = ref.watch(cartProvider);
    final itemCount = cartState.items.length;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: IconButton(
        onPressed: () => context.pushNamed('cart'),
        icon: Badge(
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              itemCount.toString(),
              key: ValueKey(itemCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          isLabelVisible: itemCount > 0,
          backgroundColor: theme.colorScheme.error,
          child: Icon(
            Icons.shopping_cart_outlined,
            color: theme.colorScheme.onPrimary,
            size: 26,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entitiesAsync = ref.watch(widget.streamProvider);
    final entityAdapter = ref.watch(widget.adapterProvider);
    final filterTypes = ref.watch(productFilterTypesProvider);

    final listState = ref.watch(productListControllerProvider);
    final controller = ref.read(productListControllerProvider.notifier);
    final l10n = ref.watch(l10nProvider);

    // Trigger animation when profit changes
    ref.listen(cartViewLogicProvider.select((v) => v.totalProfit), (
      prev,
      next,
    ) {
      if (prev != next && next != '0.00') {
        _profitHighlightController.forward(from: 0.0);
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: widget.isSelectionMode
            ? '${l10n['confirm'] ?? 'Select'} ${widget.entityMeta.entityNamePlural}'
            : l10n['products'] ?? widget.entityMeta.entityNamePlural,
        showBack: widget.isSelectionMode,
        actions: widget.isSelectionMode ? [] : [_buildCartAction(context, ref)],
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
            // Search Bar and Profit Box
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 7,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText:
                            '${l10n['search_hint'] ?? 'Search products'}...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: listState.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
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
                  const SizedBox(width: 8),
                  // Profit Box
                  Expanded(flex: 3, child: _buildProfitBox(context, ref)),
                ],
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
                                label: Text(
                                  '${l10n['home'] ?? 'All'} (${filteredBySearch.length})',
                                ),
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
                                          ? l10n['empty_cart_msg'] ??
                                                'No products found'
                                          : l10n['empty_cart_msg'] ??
                                                'No matching products',
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
