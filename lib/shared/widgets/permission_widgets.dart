import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import '../../core/services/rbac_service.dart';

/// Provide a singleton RbacService via Riverpod
final rbacServiceProvider = Provider<RbacService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RbacService(client);
});

class PermissionGuard extends ConsumerWidget {
  final String moduleId;
  final RbacAction action;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.moduleId,
    required this.action,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rbacService = ref.read(rbacServiceProvider);
    final hasPermission = rbacService.hasPermission(moduleId, action);

    if (hasPermission) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

class PermissionGuardAll extends ConsumerWidget {
  final String moduleId;
  final List<RbacAction> actions;
  final Widget child;
  final Widget? fallback;

  const PermissionGuardAll({
    super.key,
    required this.moduleId,
    required this.actions,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rbacService = ref.read(rbacServiceProvider);
    final hasPermission = rbacService.hasAllPermissions(moduleId, actions);

    return hasPermission ? child : (fallback ?? const SizedBox.shrink());
  }
}

class PermissionGuardAny extends ConsumerWidget {
  final String moduleId;
  final List<RbacAction> actions;
  final Widget child;
  final Widget? fallback;

  const PermissionGuardAny({
    super.key,
    required this.moduleId,
    required this.actions,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rbacService = ref.read(rbacServiceProvider);
    final hasPermission = rbacService.hasAnyPermission(moduleId, actions);

    return hasPermission ? child : (fallback ?? const SizedBox.shrink());
  }
}

class PermissionDisable extends ConsumerWidget {
  final String moduleId;
  final RbacAction action;
  final Widget child;

  const PermissionDisable({
    super.key,
    required this.moduleId,
    required this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rbacService = ref.read(rbacServiceProvider);
    final hasPermission = rbacService.hasPermission(moduleId, action);

    return IgnorePointer(
      ignoring: !hasPermission,
      child: Opacity(opacity: hasPermission ? 1.0 : 0.5, child: child),
    );
  }
}

class PermissionButton extends ConsumerWidget {
  final String moduleId;
  final RbacAction action;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;

  const PermissionButton({
    super.key,
    required this.moduleId,
    required this.action,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rbacService = ref.read(rbacServiceProvider);
    final hasPermission = rbacService.hasPermission(moduleId, action);

    if (!hasPermission) return const SizedBox.shrink();

    return ElevatedButton(onPressed: onPressed, style: style, child: child);
  }
}

class PermissionIconButton extends ConsumerWidget {
  final String moduleId;
  final RbacAction action;
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  const PermissionIconButton({
    super.key,
    required this.moduleId,
    required this.action,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rbacService = ref.read(rbacServiceProvider);
    final hasPermission = rbacService.hasPermission(moduleId, action);

    if (!hasPermission) return const SizedBox.shrink();

    return IconButton(onPressed: onPressed, icon: Icon(icon), tooltip: tooltip);
  }
}
