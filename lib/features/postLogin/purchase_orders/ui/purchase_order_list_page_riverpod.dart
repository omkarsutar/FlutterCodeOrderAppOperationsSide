import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:flutter_supabase_order_app_mobile/core/config/module_config.dart';
import '../../../../core/config/field_config.dart';
import '../../../../core/models/entity_meta.dart';
import '../../../../shared/widgets/shared_widget_barrel.dart';
import '../model/purchase_order_model.dart';
import '../providers/purchase_order_list_controller.dart';
import '../providers/purchase_order_providers.dart';
import '../providers/purchase_order_view_logic.dart';
import 'purchase_order_list_tile.dart';
import 'purchase_order_bill_page.dart';
import '../../cart/providers/cart_controller.dart';
import 'purchase_order_delivery_selectable_page.dart';
import '../../po_items/po_item_barrel.dart';

/// Custom Purchase Order List Page - Riverpod & JSON based
///
/// Single Responsibility: Display purchase orders with search, filtering, and navigation.
/// Focuses only on presentation and user interaction, delegating state management to Riverpod.
class PurchaseOrderListPageRiverpod extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final List<String>? searchFields;
  final SortingConfig? initialSorting;

  const PurchaseOrderListPageRiverpod({
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
  ConsumerState<PurchaseOrderListPageRiverpod> createState() =>
      _PurchaseOrderListPageRiverpodState();
}

class _PurchaseOrderListPageRiverpodState
    extends ConsumerState<PurchaseOrderListPageRiverpod> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filterScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final service = ref.read(purchaseOrderServiceProvider);
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
    _filterScrollController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    ref
        .read(purchaseOrderListControllerProvider('purchaseOrderList').notifier)
        .setSearchQuery(query, searchFields: widget.searchFields);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch the controller state
    final listState = ref.watch(
      purchaseOrderListControllerProvider('purchaseOrderList'),
    );

    // Watch the processed view data (SRP: status counts, FAB type)
    final viewData = ref.watch(purchaseOrderViewLogicProvider);

    final displayList = viewData.filteredOrders;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: widget.entityMeta.entityNamePlural,
        showBack: false,
      ),
      drawer: const CustomDrawer(),
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
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
                                .clearSearch(searchFields: widget.searchFields);
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
                onChanged: (val) {
                  if (!mounted) return;
                  _updateSearch(val);
                },
              ),
            ),

            // Filter Pills
            _buildFilterPills(theme, listState, viewData.statusCounts),

            // Purchase Orders List
            Expanded(child: _buildListContent(theme, listState, displayList)),
          ],
        ),
      ),
      floatingActionButton: _buildFab(
        theme,
        viewData.activeFabType,
        displayList,
      ),
    );
  }

  Widget? _buildFab(
    ThemeData theme,
    String? activeFabType,
    List<ModelPurchaseOrder> filteredOrders,
  ) {
    if (activeFabType == 'bill') {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  const PurchaseOrderBillPage(orderStatus: 'confirmed'),
            ),
          );
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate Bill'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    }

    if (activeFabType == 'delivery') {
      return FloatingActionButton.extended(
        onPressed: () {
          final adapter = ref.read(purchaseOrderAdapterProvider);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PurchaseOrderDeliverySelectablePage(
                orders: filteredOrders,
                adapter: adapter,
              ),
            ),
          );
        },
        icon: const Icon(Icons.copy_all),
        label: const Text('View Selectable Delivery Data'),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
      );
    }

    return null;
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

    return _buildList(displayList, listState);
  }

  /// Builds the ListView of purchase orders
  Widget _buildList(
    List<ModelPurchaseOrder> displayList,
    PurchaseOrderListState listState,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayList.length + 1,
      itemBuilder: (context, index) {
        if (index < displayList.length) {
          final displayListItem = displayList[index];
          return PurchaseOrderListTile(
            key: ValueKey(displayListItem.poId),
            entity: displayListItem,
            adapter: ref.watch(purchaseOrderAdapterProvider),
            onTap: () => ref
                .read(cartControllerProvider)
                .editPurchaseOrder(context, displayListItem),
            showShare: listState.selectedStatus?.toLowerCase() == 'delivered',
            onStatusChanged: (oldStatus, newStatus) {
              if (oldStatus == 'confirmed' &&
                  newStatus == 'delivered' &&
                  displayListItem.poId != null) {
                context.pushNamed(
                  'purchase_order_collection',
                  pathParameters: {'poId': displayListItem.poId!},
                );
              }
            },
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

  Widget _buildFilterPills(
    ThemeData theme,
    PurchaseOrderListState listState,
    Map<String, int> statusCounts,
  ) {
    final statuses = ['All', 'pending', 'confirmed', 'delivered', 'cancelled'];

    return Container(
      height: 50,
      child: ListView.builder(
        controller: _filterScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected =
              (status == 'All' && listState.selectedStatus == null) ||
              (status.toLowerCase() == listState.selectedStatus?.toLowerCase());

          // Get pre-calculated count
          final count = statusCounts[status] ?? 0;

          Color pillColor;
          switch (status.toLowerCase()) {
            case 'confirmed':
              pillColor = Colors.green;
              break;
            case 'delivered':
              pillColor = Colors.blue;
              break;
            case 'cancelled':
              pillColor = Colors.red;
              break;
            case 'pending':
              pillColor = Colors.orange;
              break;
            default:
              pillColor = theme.colorScheme.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                '${status.toUpperCase()} ($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white : pillColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (!mounted) return;
                // Scroll into view logic
                _scrollToTab(index);

                ref
                    .read(
                      purchaseOrderListControllerProvider(
                        'purchaseOrderList',
                      ).notifier,
                    )
                    .setStatusFilter(
                      status == 'All' ? null : status,
                      searchFields: widget.searchFields,
                    );
              },
              selectedColor: pillColor,
              backgroundColor: pillColor.withValues(alpha: 0.1),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: pillColor, width: isSelected ? 0 : 1),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  void _scrollToTab(int index) {
    const double itemWidth = 100.0; // Estimate
    final double offset = index * itemWidth;
    if (_filterScrollController.hasClients) {
      final double maxScroll = _filterScrollController.position.maxScrollExtent;
      final double target = offset.clamp(0.0, maxScroll);

      _filterScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
