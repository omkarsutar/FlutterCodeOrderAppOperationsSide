import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';

const rbacModuleEntityMeta = EntityMeta(
  entityName: 'RBAC Module',
  entityNamePlural: 'RBAC Modules',
  entityNameLower: 'rbac module',
  entityNamePluralLower: 'rbac modules',
);

class ModelRbacModuleFields {
  static const String table = 'rbac_modules';

  static const String moduleId = 'module_id';
  static const String moduleName = 'module_name';
  static const String moduleDescription = 'module_description';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isActive = 'is_active';
}

class ModelRbacModule {
  final String? moduleId;
  final String moduleName;
  final String? moduleDescription;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  ModelRbacModule({
    this.moduleId,
    required this.moduleName,
    this.moduleDescription,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory ModelRbacModule.fromMap(Map<String, dynamic> map) {
    return ModelRbacModule(
      moduleId: map[ModelRbacModuleFields.moduleId],
      moduleName: map[ModelRbacModuleFields.moduleName],
      moduleDescription: map[ModelRbacModuleFields.moduleDescription],
      createdAt: map[ModelRbacModuleFields.createdAt] != null
          ? DateTime.tryParse(map[ModelRbacModuleFields.createdAt])
          : null,
      updatedAt: map[ModelRbacModuleFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelRbacModuleFields.updatedAt])
          : null,
      isActive: map[ModelRbacModuleFields.isActive] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (moduleId != null) ModelRbacModuleFields.moduleId: moduleId,
      ModelRbacModuleFields.moduleName: moduleName,
      if (moduleDescription != null)
        ModelRbacModuleFields.moduleDescription: moduleDescription,
      if (createdAt != null)
        ModelRbacModuleFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelRbacModuleFields.updatedAt: updatedAt!.toIso8601String(),
      ModelRbacModuleFields.isActive: isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'moduleName': moduleName,
      'moduleDescription': moduleDescription,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ModelRbacModule.fromJson(Map<String, dynamic> json) {
    return ModelRbacModule(
      moduleId: json['moduleId'] as String,
      moduleName: json['moduleName'] as String,
      moduleDescription: json['moduleDescription'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ModelRbacModuleMapper implements EntityMapper<ModelRbacModule> {
  @override
  ModelRbacModule fromMap(Map<String, dynamic> map) =>
      ModelRbacModule.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelRbacModule entity) => entity.toMap();
}
