import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/field_config.dart';
import '../../../core/config/module_config.dart';
import '../../../core/models/entity_meta.dart';
import '../../../core/services/entity_service.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import 'entity_card.dart';
import 'providers/generic_list_controller.dart';
import 'providers/generic_list_logic.dart';

/// Generic Riverpod version of Entity List Page
/// Can be used for any entity type (Role, Note, etc.)
class EntityListPageRiverpod<T> extends ConsumerStatefulWidget {
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

  const EntityListPageRiverpod({
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
  ConsumerState<EntityListPageRiverpod<T>> createState() =>
      _EntityListPageRiverpodState<T>();
}

class _EntityListPageRiverpodState<T>
    extends ConsumerState<EntityListPageRiverpod<T>> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    // This prevents the infinite loop issue while ensuring sorting is applied
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
    final service = ref.watch(widget.serviceProvider);

    final entitiesAsync = ref.watch(widget.streamProvider);

    // Use entityName as unique key for the controller family
    final controllerKey = widget.entityMeta.entityName;
    final listState = ref.watch(genericListControllerProvider(controllerKey));
    final controller = ref.read(
      genericListControllerProvider(controllerKey).notifier,
    );

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
              theme.colorScheme.surfaceContainerHighest.withAlpha(64),
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
                onChanged: (value) {
                  if (!mounted) return;
                  controller.setSearchQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search ${widget.entityMeta.entityNamePlural}...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: listState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            controller.setSearchQuery('');
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
                  // Watch the processed view data (SRP: filtering, searching)
                  final filteredEntities = ref.watch(
                    genericListViewLogicProvider((
                      controllerKey: controllerKey,
                      allEntities: entities,
                      adapter: entityAdapter,
                      searchFields: widget.searchFields,
                      customMatcher: widget.searchMatcher,
                    )),
                  );

                  if (filteredEntities.isEmpty) {
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
                            listState.searchQuery.isEmpty
                                ? 'No ${widget.entityMeta.entityNamePluralLower} found'
                                : 'No matching ${widget.entityMeta.entityNamePluralLower}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredEntities.length,
                    itemBuilder: (context, index) {
                      final entity = filteredEntities[index];
                      // Use custom builder if provided
                      if (widget.customItemBuilder != null) {
                        return widget.customItemBuilder!(
                          context,
                          entity,
                          entityAdapter,
                          () => context.pushNamed(
                            widget.viewRouteName,
                            pathParameters: {
                              'id': entityAdapter
                                  .getId(entity, widget.idField)
                                  .toString(),
                            },
                          ),
                        );
                      }

                      return EntityCard<T>(
                        entity: entity,
                        adapter: entityAdapter,
                        entityService: service,
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
}
