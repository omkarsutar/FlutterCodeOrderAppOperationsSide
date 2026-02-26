import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/module_config.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/field_config.dart';
import 'package:flutter_supabase_order_app_mobile/core/models/entity_meta.dart';
import 'package:flutter_supabase_order_app_mobile/core/services/entity_service.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/entity_page/entity_page_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/providers/shop_list_view_logic.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/providers/shop_list_controller.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/providers/shop_list_page_logic.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/shop_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';

/// Generic Riverpod version of Entity List Page
/// Can be used for any entity type (Role, Note, etc.)
class ShopListPageRiverpod extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final bool isSelectionMode;
  final String? routeIdField;
  final SortingConfig? initialSorting;

  // Riverpod providers
  final ProviderListenable<AsyncValue<List<ModelShop>>> streamProvider;
  final Provider<EntityAdapter<ModelShop>> adapterProvider;
  final Provider<EntityService<ModelShop>> serviceProvider;

  // Search function
  final bool Function(ModelShop entity, String query)? searchMatcher;
  final List<String>? searchFields;

  // Custom Item Builder
  final Widget Function(
    BuildContext context,
    ModelShop entity,
    EntityAdapter<ModelShop> adapter,
    VoidCallback onTap,
  )?
  customItemBuilder;

  const ShopListPageRiverpod({
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
    this.routeIdField,
    this.initialSorting,
  });

  @override
  ConsumerState<ShopListPageRiverpod> createState() =>
      _ShopListPageRiverpodState();
}

class _ShopListPageRiverpodState extends ConsumerState<ShopListPageRiverpod> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(widget.serviceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entityAdapter = ref.watch(widget.adapterProvider);
    final entityService = ref.watch(widget.serviceProvider);

    final listState = ref.watch(shopListControllerProvider);
    final controller = ref.read(shopListControllerProvider.notifier);

    final queryParams = getShopQueryParams(context);
    final tapCondition = queryParams.tapCondition;

    // Watch the processed data from logic provider
    final viewData = ref.watch(shopListViewLogicProvider(tapCondition));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: getAppBarTitle(tapCondition),
        showBack: false,
      ),
      drawer: const CustomDrawer(),
      floatingActionButton: queryParams.isTapConditionEmpty
          ? CreateEntityButton(
              moduleName: widget.rbacModule,
              newRouteName: widget.newRouteName,
              entityLabel: widget.entityMeta.entityName,
              queryParameters:
                  listState.selectedRouteId != null &&
                      widget.routeIdField != null
                  ? {widget.routeIdField!: listState.selectedRouteId!}
                  : null,
            )
          : null,
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
            // Search Bar & Route Dropdown
            Row(
              children: [
                Expanded(
                  child: CollapsibleSearchBar(
                    dropdown: RouteDropdown(
                      initialRouteId: listState.selectedRouteId,
                      onRouteSelected: controller.setRouteId,
                      allowAll: true,
                    ),
                    controller: _searchController,
                    onChanged: controller.setSearchQuery,
                  ),
                ),
                if (viewData.shopCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${viewData.shopCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Entity List
            Expanded(
              child: _buildListContent(
                theme: theme,
                tapCondition: tapCondition,
                entityAdapter: entityAdapter,
                entityService: entityService,
                viewData: viewData,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildShopBottomNav(
        context: context,
        ref: ref,
        tapCondition: tapCondition,
        showBottomNav:
            tapCondition == 'listWithoutTodaysPOs' ||
            tapCondition == 'listWithTodaysEmptyPOs' ||
            tapCondition == 'listWithTodaysFilledPOs',
      ),
    );
  }

  /// Builds the list content based on processed data
  Widget _buildListContent({
    required ThemeData theme,
    required String? tapCondition,
    required EntityAdapter<ModelShop> entityAdapter,
    required EntityService<ModelShop> entityService,
    required ProcessedShopListData viewData,
  }) {
    if (viewData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewData.error != null) {
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
              viewData.error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final shops = viewData.filteredShops;

    if (shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${widget.entityMeta.entityNamePluralLower} found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];

        if (widget.customItemBuilder != null) {
          final onTap = getOnTapForShop(
            context: context,
            entity: shop,
            adapter: entityAdapter,
            tapCondition: tapCondition,
          );

          return widget.customItemBuilder!(context, shop, entityAdapter, onTap);
        }

        return EntityCard<ModelShop>(
          entity: shop,
          adapter: entityAdapter,
          entityService: entityService,
          fieldConfigs: widget.fieldConfigs
              .where((f) => f.visibleInList)
              .toList(),
          idField: widget.idField,
          timestampField: widget.timestampField,
          entityLabel: widget.entityMeta.entityName,
          entityLabelLower: widget.entityMeta.entityNameLower,
          viewRouteName: widget.viewRouteName,
        );
      },
    );
  }

  /// Decides what happens when a shop tile is tapped
  VoidCallback getOnTapForShop({
    required BuildContext context,
    required ModelShop entity,
    required EntityAdapter<ModelShop> adapter,
    required String? tapCondition,
  }) {
    return ShopListPageLogic.getOnTapForShop(
      context: context,
      entity: entity,
      adapter: adapter,
      tapCondition: tapCondition,
      isSelectionMode: widget.isSelectionMode,
      viewRouteName: widget.viewRouteName,
      idField: widget.idField,
      handleCreatePO: (ctx, ent, adp) =>
          ShopListPageLogic.handleCreatePurchaseOrder(
            context: ctx,
            ref: ref,
            entity: ent,
            adapter: adp,
          ),
    );
  }
}
