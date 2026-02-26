import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/config/module_config.dart';
import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../shared/widgets/shared_widget_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/entity_page/entity_page_barrel.dart';
import '../route_shop_link_barrel.dart';

class RouteShopLinkListPageRiverpod extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final bool isSelectionMode;
  final SortingConfig? initialSorting;

  // Search function
  final bool Function(ModelRouteShopLink entity, String query)? searchMatcher;
  final List<String>? searchFields;

  // Custom Item Builder
  final Widget Function(
    BuildContext context,
    ModelRouteShopLink entity,
    EntityAdapter<ModelRouteShopLink> adapter,
    VoidCallback onTap,
  )?
  customItemBuilder;

  const RouteShopLinkListPageRiverpod({
    super.key,
    required this.entityMeta,
    required this.idField,
    required this.viewRouteName,
    required this.fieldConfigs,
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
  ConsumerState<RouteShopLinkListPageRiverpod> createState() =>
      _RouteShopLinkListPageRiverpodState();
}

class _RouteShopLinkListPageRiverpodState
    extends ConsumerState<RouteShopLinkListPageRiverpod> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(routeShopLinkServiceProvider);
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
    final adapter = ref.watch(routeShopLinkAdapterProvider);
    final service = ref.watch(routeShopLinkServiceProvider);

    final listState = ref.watch(routeShopLinkListControllerProvider);
    final controller = ref.read(routeShopLinkListControllerProvider.notifier);

    // Watch the Backend Data
    final asyncEntities = listState.selectedRouteId == null
        ? const AsyncValue<List<ModelRouteShopLink>>.loading()
        : ref.watch(routeShopLinksByRouteProvider(listState.selectedRouteId!));

    // Sync local state when provider data changes
    if (listState.selectedRouteId != null) {
      ref.listen<AsyncValue<List<ModelRouteShopLink>>>(
        routeShopLinksByRouteProvider(listState.selectedRouteId!),
        (previous, next) {
          next.whenData((data) {
            controller.setEntities(data);
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Route Shop Links',
        showBack: widget.isSelectionMode,
      ),
      drawer: widget.isSelectionMode ? null : const CustomDrawer(),
      floatingActionButton: widget.isSelectionMode
          ? null
          : CreateEntityButton(
              moduleName: widget.rbacModule,
              newRouteName: widget.newRouteName,
              entityLabel: widget.entityMeta.entityName,
              queryParameters: listState.selectedRouteId != null
                  ? {'routeId': listState.selectedRouteId!}
                  : null,
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
            // 1. Collapsible Search Bar with Route Dropdown
            CollapsibleSearchBar(
              dropdown: Container(
                padding: const EdgeInsets.only(right: 8),
                child: RouteDropdown(
                  initialRouteId: listState.selectedRouteId,
                  onRouteSelected: controller.setRouteId,
                ),
              ),
              controller: _searchController,
              onChanged: controller.setSearchQuery,
            ),

            // 2. Scrollable Reorderable List Content
            Expanded(
              child: listState.selectedRouteId == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.alt_route_rounded,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please select a route',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a route from the dropdown above to view shops.',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        // If still loading and no local entities, show loader from AsyncValue
                        if (listState.localEntities.isEmpty &&
                            asyncEntities.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (listState.localEntities.isEmpty &&
                            asyncEntities.hasError) {
                          return Center(
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
                                  'Error loading data',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  asyncEntities.error.toString(),
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        // Use Controller for filtering
                        final filteredEntities = controller.getFilteredEntities(
                          adapter: adapter,
                          customMatcher: widget.searchMatcher,
                          searchFields: widget.searchFields,
                        );

                        if (filteredEntities.isEmpty) {
                          final isSearchEmpty =
                              listState.searchQuery.isNotEmpty;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isSearchEmpty
                                      ? 'No matching ${widget.entityMeta.entityNamePluralLower}'
                                      : 'No ${widget.entityMeta.entityNamePluralLower} in this route',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final bool canReorder = listState.searchQuery.isEmpty;

                        return canReorder
                            ? ReorderableListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: filteredEntities.length,
                                onReorder: (oldIndex, newIndex) => controller
                                    .reorder(oldIndex, newIndex, widget.idField)
                                    .catchError((e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to reorder: $e',
                                          ),
                                          backgroundColor:
                                              theme.colorScheme.error,
                                        ),
                                      );
                                    }),
                                itemBuilder: (context, index) {
                                  final entity = filteredEntities[index];
                                  final key = ValueKey(
                                    adapter.getId(entity, widget.idField),
                                  );

                                  return Container(
                                    key: key,
                                    child: _buildItem(
                                      context,
                                      entity,
                                      adapter,
                                      service,
                                      listState.selectedRouteId,
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: filteredEntities.length,
                                itemBuilder: (context, index) {
                                  final entity = filteredEntities[index];
                                  return _buildItem(
                                    context,
                                    entity,
                                    adapter,
                                    service,
                                    listState.selectedRouteId,
                                  );
                                },
                              );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    ModelRouteShopLink entity,
    EntityAdapter<ModelRouteShopLink> adapter,
    EntityService<ModelRouteShopLink> service,
    String? selectedRouteId,
  ) {
    if (widget.customItemBuilder != null) {
      return widget.customItemBuilder!(context, entity, adapter, () async {
        await context.pushNamed(
          widget.viewRouteName,
          pathParameters: {
            'id': adapter.getId(entity, widget.idField).toString(),
          },
        );
        // Refresh data on return
        if (mounted && selectedRouteId != null) {
          ref
              .read(routeShopLinkListControllerProvider.notifier)
              .setEntities([]); // Optional: clear list to show loading/refresh
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(routeShopLinksByRouteProvider(selectedRouteId));
        }
      });
    }
    return EntityCard<ModelRouteShopLink>(
      entity: entity,
      adapter: adapter,
      entityService: service,
      fieldConfigs: widget.fieldConfigs.where((f) => f.visibleInList).toList(),
      idField: widget.idField,
      timestampField: widget.timestampField,
      entityLabel: widget.entityMeta.entityName,
      entityLabelLower: widget.entityMeta.entityNameLower,
      viewRouteName: widget.viewRouteName,
    );
  }
}
