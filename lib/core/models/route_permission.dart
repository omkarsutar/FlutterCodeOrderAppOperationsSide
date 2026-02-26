import '../services/rbac_service.dart';

/// Represents the permission required to access a route
class RoutePermission {
  final String moduleId;
  final RbacAction action;

  const RoutePermission({required this.moduleId, required this.action});

  @override
  String toString() =>
      'RoutePermission(module: $moduleId, action: ${action.name})';
}
