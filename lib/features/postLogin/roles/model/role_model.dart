import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';

const roleEntityMeta = EntityMeta(
  entityName: 'Role',
  entityNamePlural: 'Roles',
  entityNameLower: 'role',
  entityNamePluralLower: 'roles',
);

class ModelRoleFields {
  static const String table = 'rbac_roles'; // ✅ updated table name

  static const String roleId = 'role_id';
  static const String roleName = 'role_name';
  static const String roleDescription = 'role_description'; // ✅ renamed
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isActive = 'is_active'; // ✅ new column
}

class ModelRole {
  final String? roleId;
  final String roleName;
  final String? roleDescription; // ✅ renamed
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive; // ✅ new field

  ModelRole({
    this.roleId,
    required this.roleName,
    this.roleDescription,
    this.createdAt,
    this.updatedAt,
    this.isActive = true, // default true
  });

  factory ModelRole.fromMap(Map<String, dynamic> map) {
    return ModelRole(
      roleId: map[ModelRoleFields.roleId],
      roleName: map[ModelRoleFields.roleName],
      roleDescription: map[ModelRoleFields.roleDescription],
      createdAt: map[ModelRoleFields.createdAt] != null
          ? DateTime.tryParse(map[ModelRoleFields.createdAt])
          : null,
      updatedAt: map[ModelRoleFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelRoleFields.updatedAt])
          : null,
      isActive: map[ModelRoleFields.isActive] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (roleId != null) ModelRoleFields.roleId: roleId,
      ModelRoleFields.roleName: roleName,
      if (roleDescription != null)
        ModelRoleFields.roleDescription: roleDescription,
      if (createdAt != null)
        ModelRoleFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelRoleFields.updatedAt: updatedAt!.toIso8601String(),
      ModelRoleFields.isActive: isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'roleName': roleName,
      'roleDescription': roleDescription,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory ModelRole.fromJson(Map<String, dynamic> json) {
    return ModelRole(
      roleId: json['roleId'] as String,
      roleName: json['roleName'] as String,
      roleDescription: json['roleDescription'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class ModelRoleMapper implements EntityMapper<ModelRole> {
  @override
  ModelRole fromMap(Map<String, dynamic> map) => ModelRole.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelRole entity) => entity.toMap();
}
