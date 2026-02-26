import 'package:flutter/material.dart';
import '../../../../core/services/entity_service.dart';
import '../model/user_model.dart';

class UserListTile extends StatelessWidget {
  final ModelUser entity;
  final EntityAdapter<ModelUser> adapter;
  final VoidCallback? onTap;

  const UserListTile({
    super.key,
    required this.entity,
    required this.adapter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fullName =
        adapter.getFieldValue(entity, ModelUserFields.fullName)?.toString() ??
        'Unnamed User';
    final role =
        adapter.getLabelValue(entity, ModelUserFields.roleId)?.toString() ??
        'Role not set';
    final preferredRoute =
        adapter
            .getLabelValue(entity, ModelUserFields.preferredRouteId)
            ?.toString() ??
        'Route not set';

    // Optional: status badge if you add is_active / is_available fields
    final isActive =
        adapter.getFieldValue(entity, 'is_active') as bool? ?? true;
    final isAvailable =
        adapter.getFieldValue(entity, 'is_available') as bool? ?? true;

    Color statusColor;
    String statusText;
    if (!isActive) {
      statusColor = Colors.red;
      statusText = 'INACTIVE';
    } else if (!isAvailable) {
      statusColor = Colors.orange;
      statusText = 'UNAVAILABLE';
    } else {
      statusColor = Colors.green;
      statusText = 'AVAILABLE';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Full Name + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Role
              Text(
                role,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Row 3: Preferred Route
              Text(
                'Preferred Route: $preferredRoute',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
