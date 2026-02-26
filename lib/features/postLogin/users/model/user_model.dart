import '../../../../core/services/entity_service.dart';

class ModelUserFields {
  static const String table = 'users';
  static const String tableViewWithForeignKeyLabels = 'view_users';

  static const String userId = 'user_id';
  static const String fullName = 'full_name';
  static const String roleId = 'role_id';
  static const String preferredRouteId = 'preferred_route_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class ModelUser {
  final String userId; // required, PK
  final String? fullName; // nullable
  final String? roleId; // nullable FK
  final String? preferredRouteId; // nullable FK
  final DateTime? createdAt; // nullable, DB default
  final DateTime? updatedAt; // nullable, DB default
  final Map<String, dynamic> _resolvedLabels;

  ModelUser({
    required this.userId,
    this.fullName,
    this.roleId,
    this.preferredRouteId,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  factory ModelUser.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelUser(
      userId: map[ModelUserFields.userId].toString(),
      fullName: map[ModelUserFields.fullName],
      roleId: map[ModelUserFields.roleId],
      preferredRouteId: map[ModelUserFields.preferredRouteId],
      createdAt: _parseDate(map[ModelUserFields.createdAt]),
      updatedAt: _parseDate(map[ModelUserFields.updatedAt]),
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (userId.isNotEmpty && userId != 'null') ModelUserFields.userId: userId,
      if (fullName != null) ModelUserFields.fullName: fullName,
      if (roleId != null) ModelUserFields.roleId: roleId,
      if (preferredRouteId != null)
        ModelUserFields.preferredRouteId: preferredRouteId,
      if (createdAt != null)
        ModelUserFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelUserFields.updatedAt: updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'roleId': roleId,
      'preferredRouteId': preferredRouteId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedLabels': resolvedLabels,
    };
  }

  factory ModelUser.fromJson(Map<String, dynamic> json) {
    return ModelUser(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String?,
      roleId: json['roleId'] as String?,
      preferredRouteId: json['preferredRouteId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      resolvedLabels: json['resolvedLabels'] ?? {},
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class ModelUserMapper implements EntityMapper<ModelUser> {
  @override
  ModelUser fromMap(Map<String, dynamic> map) => ModelUser.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelUser entity) => entity.toMap();
}
