import 'package:flutter_supabase_order_app_mobile/core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';

/// Entity metadata for RBAC permissions
final rbacPermissionEntityMeta = EntityMeta(
  entityName: 'RBAC Permission',
  entityNamePlural: 'Permissions',
  entityNameLower: 'permission',
  entityNamePluralLower: 'permissions',
);

class ModelRbacPermissionFields {
  static const String table = 'rbac_permissions';
  static const String tableViewWithForeignKeyLabels = 'view_rbac_permissions';

  static const String permissionId = 'permission_id';
  static const String roleId = 'role_id';
  static const String moduleId = 'module_id';
  static const String canRead = 'can_read';
  static const String canCreate = 'can_create';
  static const String canUpdate = 'can_update';
  static const String canDelete = 'can_delete';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const Map<String, String> labels = {
    permissionId: 'RBAC Permission',
    roleId: 'Role',
    moduleId: 'Module',
    canRead: 'Can Read',
    canCreate: 'Can Create',
    canUpdate: 'Can Update',
    canDelete: 'Can Delete',
    createdAt: 'Created At',
    updatedAt: 'Updated At',
  };

  static String getLabel(String field) => labels[field] ?? field;
}

class ModelRbacPermission {
  final String? permissionId;
  final String roleId;
  final String moduleId;
  final bool canRead;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> _resolvedLabels;

  ModelRbacPermission({
    this.permissionId,
    required this.roleId,
    required this.moduleId,
    this.canRead = false,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  ModelRbacPermission copyWith({
    String? permissionId,
    String? roleId,
    String? moduleId,
    bool? canRead,
    bool? canCreate,
    bool? canUpdate,
    bool? canDelete,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? resolvedLabels,
  }) {
    return ModelRbacPermission(
      permissionId: permissionId ?? this.permissionId,
      roleId: roleId ?? this.roleId,
      moduleId: moduleId ?? this.moduleId,
      canRead: canRead ?? this.canRead,
      canCreate: canCreate ?? this.canCreate,
      canUpdate: canUpdate ?? this.canUpdate,
      canDelete: canDelete ?? this.canDelete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedLabels: resolvedLabels ?? this.resolvedLabels,
    );
  }

  factory ModelRbacPermission.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelRbacPermission(
      permissionId: map[ModelRbacPermissionFields.permissionId],
      roleId: map[ModelRbacPermissionFields.roleId],
      moduleId: map[ModelRbacPermissionFields.moduleId],
      canRead: map[ModelRbacPermissionFields.canRead] ?? false,
      canCreate: map[ModelRbacPermissionFields.canCreate] ?? false,
      canUpdate: map[ModelRbacPermissionFields.canUpdate] ?? false,
      canDelete: map[ModelRbacPermissionFields.canDelete] ?? false,
      createdAt: _parseDate(map[ModelRbacPermissionFields.createdAt]),
      updatedAt: _parseDate(map[ModelRbacPermissionFields.updatedAt]),
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (permissionId != null)
        ModelRbacPermissionFields.permissionId: permissionId,
      ModelRbacPermissionFields.roleId: roleId,
      ModelRbacPermissionFields.moduleId: moduleId,
      ModelRbacPermissionFields.canRead: canRead,
      ModelRbacPermissionFields.canCreate: canCreate,
      ModelRbacPermissionFields.canUpdate: canUpdate,
      ModelRbacPermissionFields.canDelete: canDelete,
      if (createdAt != null)
        ModelRbacPermissionFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelRbacPermissionFields.updatedAt: updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'permissionId': permissionId,
      'roleId': roleId,
      'moduleId': moduleId,
      'canRead': canRead,
      'canCreate': canCreate,
      'canUpdate': canUpdate,
      'canDelete': canDelete,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ModelRbacPermission.fromJson(Map<String, dynamic> json) {
    return ModelRbacPermission(
      permissionId: json['permissionId'] as String,
      roleId: json['roleId'] as String,
      moduleId: json['moduleId'] as String,
      canRead: json['canRead'] as bool? ?? false,
      canCreate: json['canCreate'] as bool? ?? false,
      canUpdate: json['canUpdate'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class ModelRbacPermissionMapper implements EntityMapper<ModelRbacPermission> {
  @override
  ModelRbacPermission fromMap(Map<String, dynamic> map) =>
      ModelRbacPermission.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelRbacPermission entity) => entity.toMap();
}
