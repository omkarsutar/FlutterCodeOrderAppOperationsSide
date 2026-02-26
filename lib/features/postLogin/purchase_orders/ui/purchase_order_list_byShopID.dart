import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/json_utils.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/shop_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/ui/shop_list_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/module_config.dart';
import '../../../../core/config/field_config.dart';
import '../../../../core/models/entity_meta.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import '../model/purchase_order_model.dart';
import '../providers/purchase_order_list_controller.dart';
import '../providers/purchase_order_providers.dart';
import 'purchase_order_list_tile.dart';
import '../../po_items/po_item_barrel.dart';

/// Custom Purchase Order List Page - Riverpod & JSON based
///
/// Single Responsibility: Display purchase orders with search, filtering, and navigation.
/// Focuses only on presentation and user interaction, delegating state management to Riverpod.
class PurchaseOrderListByShopID extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final List<String>? searchFields;
  final SortingConfig? initialSorting;

  const PurchaseOrderListByShopID({
    super.key,
    required this.entityMeta,
    required this.idField,
    required this.fieldConfigs,
    required this.timestampField,
    required this.viewRouteName,
    required this.newRouteName,
    required this.rbacModule,
    this.searchFields,
    this.initialSorting,
  });

  @override
  ConsumerState<PurchaseOrderListByShopID> createState() =>
      _PurchaseOrderListByShopIDState();
}

class _PurchaseOrderListByShopIDState
    extends ConsumerState<PurchaseOrderListByShopID> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(purchaseOrderServiceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );

        // Reset filters when entering this specialized view
        ref
            .read(
              purchaseOrderListControllerProvider('purchaseOrderList').notifier,
            )
            .resetFilters(searchFields: widget.searchFields);
      });
    } else {
      // Even if no initial sorting, reset filters to ensure a clean state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(
              purchaseOrderListControllerProvider('purchaseOrderList').notifier,
            )
            .resetFilters(searchFields: widget.searchFields);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    ref
        .read(purchaseOrderListControllerProvider('purchaseOrderList').notifier)
        .setSearchQuery(query, searchFields: widget.searchFields);
  }

  String? _getFilterShopId() {
    return GoRouterState.of(context).uri.queryParameters['filterShopId'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterShopId = _getFilterShopId();

    // Watch the controller state (handles loading, errors, filtering)
    final listState = ref.watch(
      purchaseOrderListControllerProvider('purchaseOrderList'),
    );

    final extra = GoRouterState.of(context).extra;
    final shop = extra is ModelShop ? extra : null;
    prettyPrint(shop);

    final displayList = filterShopId != null
        ? listState.filteredPurchaseOrders
              .where((po) => po.poShopId == filterShopId)
              .toList()
        : listState.filteredPurchaseOrders;

    final queryParams = getShopQueryParams(context);

    return Scaffold(
      bottomNavigationBar: buildShopBottomNav(
        context: context,
        ref: ref,
        tapCondition: queryParams.tapCondition,
        showBottomNav:
            queryParams.filterShopId !=
            null, // only show if navigated from Shops
      ),
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: widget.entityMeta.entityNamePlural,
        showBack: queryParams.showBackButton,
      ),
      drawer: queryParams.showBackButton ? null : const CustomDrawer(),
      /* floatingActionButton: CreateEntityButton(
        moduleName: ModelPurchaseOrderFields.table,
        newRouteName: widget.newRouteName,
        entityLabel: widget.entityMeta.entityName,
      ), */
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
            RouteLabelWidget(),
            // Search Bar
            if (filterShopId == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search ${widget.entityMeta.entityNamePluralLower}...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: listState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(
                                    purchaseOrderListControllerProvider(
                                      'purchaseOrderList',
                                    ).notifier,
                                  )
                                  .clearSearch(
                                    searchFields: widget.searchFields,
                                  );
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: (val) => _updateSearch(val),
                ),
              ),
            if (shop != null) ...[
              ShopListTile(
                entity: shop,
                adapter: ref.watch(shopAdapterProvider),
                idField: ModelShopFields.shopId,
                entityLabel: 'Shop',
                entityLabelLower: 'shop',
                viewRouteName: ShopsRoutesJson.viewRouteName,
                rbacModule: 'shops',
                onTap: () {
                  GoRouter.of(context).pushNamed(
                    ShopsRoutesJson.viewRouteName,
                    queryParameters: {'shop_id': shop.shopId!},
                  );
                },
              ),
              const Divider(),
            ],

            // Purchase Orders List
            Expanded(child: _buildListContent(theme, listState, displayList)),
          ],
        ),
      ),
    );
  }

  /// Builds the list content based on controller state
  /// Handles loading, error, and data states
  Widget _buildListContent(
    ThemeData theme,
    PurchaseOrderListState listState,
    List<ModelPurchaseOrder> displayList,
  ) {
    // Loading state
    if (listState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (listState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading ${widget.entityMeta.entityNamePluralLower}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              listState.error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(
                      purchaseOrderListControllerProvider(
                        'purchaseOrderList',
                      ).notifier,
                    )
                    .refreshData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (displayList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              listState.searchQuery.isEmpty
                  ? 'No ${widget.entityMeta.entityNamePluralLower} found'
                  : 'No matching ${widget.entityMeta.entityNamePluralLower}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return _buildList(displayList);
  }

  /// Builds the ListView of purchase orders
  Widget _buildList(List<ModelPurchaseOrder> displayList) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayList.length + 1,
      itemBuilder: (context, index) {
        if (index < displayList.length) {
          final displayListItem = displayList[index];
          return PurchaseOrderListTile(
            entity: displayListItem,
            adapter: ref.watch(purchaseOrderAdapterProvider),
            onTap: () => _navigateToPOItems(displayListItem),
          );
        } else {
          // Bottom padding for FAB
          return const SizedBox(height: 80);
        }
      },
    );
  }

  Future<void> _navigateToPOItems(ModelPurchaseOrder displayListItem) async {
    if (displayListItem.poId != null) {
      await GoRouter.of(context).pushNamed(
        PoItemsRoutesJson.listRouteName,
        queryParameters: {'po_id': displayListItem.poId!},
      );

      ref
          .read(
            purchaseOrderListControllerProvider('purchaseOrderList').notifier,
          )
          .refreshData();
    }
  }
}
