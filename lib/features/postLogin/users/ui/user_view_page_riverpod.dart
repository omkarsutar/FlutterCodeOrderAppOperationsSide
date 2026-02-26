import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/json_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/utils/core_utils_barrel.dart';
import '../../../../shared/widgets/shared_widget_barrel.dart';
import '../../../../core/providers/core_providers.dart';

/// Users Riverpod version of Entity View Page
class UserViewPageRiverpod<T> extends ConsumerWidget {
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

  const UserViewPageRiverpod({
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

  Future<void> _deleteEntity(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entityMeta.entityName}'),
        content: Text(
          'Are you sure you want to delete this ${entityMeta.entityNameLower}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final success = await deleteFunction(ref, entityId);

        if (context.mounted) {
          if (success) {
            SnackbarUtils.showSuccess(
              '${entityMeta.entityName} deleted successfully!',
            );
            context.pop(); // Go back to previous page
          } else {
            ErrorHandler.handle(
              Exception('Failed to delete ${entityMeta.entityNameLower}'),
              StackTrace.current,
              context: 'Deleting ${entityMeta.entityName}',
              showToUser: true,
            );
          }
        }
      } catch (e, stackTrace) {
        ErrorHandler.handle(
          e,
          stackTrace,
          context: 'Deleting ${entityMeta.entityName}',
          showToUser: true,
        );
      }
    }
  }

  /* bool _isPhotoUrlField(String fieldName) {
    final lowerName = fieldName.toLowerCase();
    return lowerName.contains('photo') ||
        lowerName.contains('image') ||
        lowerName.contains('picture');
  } */

  bool _isLocationUrlField(String fieldName, String? value) {
    final lowerName = fieldName.toLowerCase();
    final isLocationField =
        lowerName.contains('location') || lowerName.contains('map');
    final isGoogleMapsUrl = value?.contains('google.com/maps') ?? false;
    return isLocationField || isGoogleMapsUrl;
  }

  bool _isPhoneField(String fieldName) {
    final lowerName = fieldName.toLowerCase();
    return lowerName.contains('mobile') ||
        lowerName.contains('phone') ||
        lowerName.contains('contact');
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$cleanNumber');
      await launchUrl(uri);
    } catch (e) {
      // Error handled silently
    }
  }

  /* String? _getLabelFieldName(String fieldName) {
    if (fieldName.endsWith('_id')) {
      return '${fieldName}_label';
    }
    return null;
  }

  Map<String, dynamic> _entityToMap(
    dynamic entity,
    EntityAdapter<dynamic> adapter,
    List<FieldConfig> fields,
  ) {
    final map = <String, dynamic>{};
    for (final field in fields) {
      final value = adapter.getFieldValue(entity, field.name);
      // Check for label fields
      final labelField = _getLabelFieldName(field.name);
      if (labelField != null) {
        final labelValue = adapter.getFieldValue(entity, labelField);
        if (labelValue != null) {
          map['${field.name} (label)'] = labelValue;
        }
      }
      map[field.name] = value;
    }
    return map;
  } */

  Widget _buildFieldCard(
    BuildContext context,
    ThemeData theme,
    FieldConfig field,
    dynamic value,
  ) {
    if (value == null || value.toString().isEmpty)
      return const SizedBox.shrink();

    final isPhone = _isPhoneField(field.name);
    final isLocation = _isLocationUrlField(field.name, value.toString());

    // Build the display value with prefix/suffix
    String displayValue = value.toString();
    if (field.prefix != null && !isPhone && !isLocation) {
      displayValue = '${field.prefix}$displayValue';
    }
    if (field.suffix != null && !isPhone && !isLocation) {
      displayValue = '$displayValue${field.suffix}';
    }

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
          // Field label
          Text(
            field.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          // Field value
          if (isPhone)
            InkWell(
              onTap: () => _launchPhone(value.toString()),
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
              onTap: () => _launchUrl(value.toString()),
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
            Text(
              displayValue,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.5,
              ),
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
    final isInitialized = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    // Check permissions
    final canUpdate = isInitialized && rbacService.canUpdate(rbacModule);
    final canDelete = isInitialized && rbacService.canDelete(rbacModule);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'View max ${entityMeta.entityName}',
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
              onPressed: () => _deleteEntity(context, ref),
            ),
        ],
      ),
      body: entityAsync.when(
        data: (entity) {
          prettyPrint(entity);
          if (entity == null) {
            return Center(child: Text('${entityMeta.entityName} not found'));
          }

          final timestampValue = timestampField != null
              ? entityAdapter.getFieldValue(entity, timestampField!)
              : null;
          final timestampStr = timestampValue != null
              ? formatTimestamp(timestampValue as DateTime)
              : '';

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
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            toPrettyJson(entity),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
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
                              entityAdapter.getLabelValue(entity, fieldName) ??
                              entityAdapter.getFieldValue(entity, fieldName);
                        } else {
                          value = entityAdapter.getFieldValue(
                            entity,
                            fieldName,
                          );
                        }

                        return _buildFieldCard(context, theme, field, value);
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
    );
  }
}
