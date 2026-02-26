import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/field_config.dart';
import '../../../../../core/models/entity_meta.dart';
import '../../../../../core/services/entity_service.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../shared/widgets/custom_app_bar.dart';
import '../../../../../core/providers/core_providers.dart';
import '../route_shop_link_barrel.dart';

/// Route Shop Links specific View Page
/// Customized for route_shop_links module
class RouteShopLinksViewPageRiverpod<T> extends ConsumerWidget {
  final String entityId;
  final EntityMeta entityMeta;
  final List<FieldConfig> fieldConfigs;
  final String idField;
  final String? timestampField;
  final String editRouteName;
  final String rbacModule;

  // Riverpod providers
  final AutoDisposeFutureProviderFamily<T?, String> entityByIdProvider;
  final Provider<EntityAdapter<T>> adapterProvider;

  // Delete function from form provider - receives WidgetRef and entity ID
  final Future<bool> Function(WidgetRef ref, String id) deleteFunction;

  const RouteShopLinksViewPageRiverpod({
    super.key,
    required this.entityId,
    required this.entityMeta,
    required this.fieldConfigs,
    required this.idField,
    this.timestampField,
    required this.editRouteName,
    required this.rbacModule,
    required this.entityByIdProvider,
    required this.adapterProvider,
    required this.deleteFunction,
  });

  Future<void> _onDeletePressed(
    BuildContext context,
    WidgetRef ref,
    RouteShopLinksViewController controller,
  ) async {
    await controller.handleDeleteEntity(
      context: context,
      ref: ref,
      deleteFunction: deleteFunction,
      entityId: entityId,
      entityName: entityMeta.entityName,
      entityNameLower: entityMeta.entityNameLower,
    );
  }

  Widget _buildFieldCard(
    BuildContext context,
    ThemeData theme,
    FieldConfig field,
    dynamic value,
    RouteShopLinksViewController controller,
  ) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    final isPhone = controller.isPhoneField(field.name);
    final isLocation = controller.isLocationField(field.name, value.toString());
    final isRoute = controller.isRouteField(field.name);
    final isShop = controller.isShopField(field.name);

    // Build the display value with prefix/suffix
    String displayValue = (isPhone || isLocation)
        ? value.toString()
        : controller.formatDateLikeField(field, value);
    if (field.prefix != null && !isPhone && !isLocation) {
      displayValue = '${field.prefix}$displayValue';
    }
    if (field.suffix != null && !isPhone && !isLocation) {
      displayValue = '$displayValue${field.suffix}';
    }

    // Get appropriate icon and color from controller
    final fieldIconAndColor = controller.getFieldIconAndColor(field.name);
    final fieldIcon = fieldIconAndColor.icon;
    final iconColor = fieldIconAndColor.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label with icon
          Row(
            children: [
              Icon(fieldIcon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                field.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Field value
          if (isPhone)
            InkWell(
              onTap: () => controller.launchPhone(value.toString()),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    value.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else if (isLocation)
            InkWell(
              onTap: () => controller.launchUrl(value.toString()),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Open in Maps',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (field.type == FieldType.switchField)
            Row(
              children: [
                Icon(
                  value == true ? Icons.check_circle : Icons.cancel,
                  color: value == true ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  value == true ? 'Yes' : 'No',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                if (isRoute || isShop)
                  Icon(
                    fieldIcon,
                    size: 18,
                    color: iconColor.withValues(alpha: 0.7),
                  ),
                if (isRoute || isShop) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayValue,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entityAsync = ref.watch(entityByIdProvider(entityId));
    final entityAdapter = ref.watch(adapterProvider);

    // Controller
    final controllerKey = 'route_shop_links_view';
    final viewState = ref.watch(
      routeShopLinksViewControllerProvider(controllerKey),
    );
    final controller = ref.read(
      routeShopLinksViewControllerProvider(controllerKey).notifier,
    );

    // Side Effects Listener
    ref.listen<RouteShopLinksViewState>(
      routeShopLinksViewControllerProvider(controllerKey),
      (previous, next) {
        controller.handleSideEffects(next, context, entityMeta.entityName);
      },
    );

    final isInitialized = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    // Check permissions
    final canUpdate = isInitialized && rbacService.canUpdate(rbacModule);
    final canDelete = isInitialized && rbacService.canDelete(rbacModule);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'View lala ${entityMeta.entityName}',
        showBack: true,
        actions: [
          // Edit button - only show if user has update permission
          if (canUpdate)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.pushNamed(
                  editRouteName,
                  pathParameters: {'id': entityId},
                );
              },
            ),
          // Delete button - only show if user has delete permission
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: viewState.isLoading
                  ? null
                  : () => _onDeletePressed(context, ref, controller),
            ),
        ],
      ),
      body: Stack(
        children: [
          entityAsync.when(
            data: (entity) {
              if (entity == null) {
                return Center(
                  child: Text('${entityMeta.entityName} not found'),
                );
              }

              final timestampValue = timestampField != null
                  ? entityAdapter.getFieldValue(entity, timestampField!)
                  : null;
              String timestampStr = '';
              if (timestampValue is DateTime) {
                timestampStr = formatTimestamp(timestampValue);
              } else if (timestampValue is String) {
                final parsed = DateTime.tryParse(timestampValue);
                if (parsed != null) {
                  timestampStr = formatTimestamp(parsed);
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content with padding
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (timestampStr.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Text(
                                timestampStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          // Field cards
                          ...fieldConfigs.map((field) {
                            final fieldName = field.name;
                            dynamic value;

                            // For ID fields, try to get the label value first
                            if (fieldName.endsWith('_id')) {
                              value =
                                  entityAdapter.getLabelValue(
                                    entity,
                                    fieldName,
                                  ) ??
                                  entityAdapter.getFieldValue(
                                    entity,
                                    fieldName,
                                  );
                            } else {
                              value = entityAdapter.getFieldValue(
                                entity,
                                fieldName,
                              );
                            }

                            return _buildFieldCard(
                              context,
                              theme,
                              field,
                              value,
                              controller,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    'Error loading ${entityMeta.entityNameLower}',
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

          // Loading Overlay
          if (viewState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
