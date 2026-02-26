import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/field_config.dart';
import '../../../core/services/entity_service.dart';
import 'providers/entity_card_logic.dart';

class EntityCard<T> extends StatelessWidget {
  final T entity;
  final EntityService<T> entityService;
  final List<FieldConfig> fieldConfigs;
  final String idField;
  final String? timestampField;
  final String entityLabel;
  final String entityLabelLower;
  final String viewRouteName;
  final EntityAdapter<T> adapter;

  const EntityCard({
    super.key,
    required this.entity,
    required this.adapter,
    required this.fieldConfigs,
    required this.idField,
    required this.timestampField,
    required this.entityLabel,
    required this.entityLabelLower,
    required this.viewRouteName,
    required this.entityService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use logic provider for metadata processing
    final metadata = EntityCardLogic.processMetadata(
      entity: entity,
      adapter: adapter,
      fieldConfigs: fieldConfigs,
      timestampField: timestampField,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.pushNamed(
          viewRouteName,
          pathParameters: {'id': adapter.getId(entity, idField).toString()},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      metadata.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (metadata.isActive != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: metadata.isActive!
                            ? Colors.green.withValues(alpha: 0.1)
                            : theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: metadata.isActive!
                              ? Colors.green.withValues(alpha: 0.5)
                              : theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        metadata.isActive! ? 'Active' : 'Inactive',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: metadata.isActive!
                              ? Colors.green[700]
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (metadata.title.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  metadata.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (metadata.formattedTimestamp != null) ...[
                const SizedBox(height: 8),
                Text(
                  metadata.formattedTimestamp!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
