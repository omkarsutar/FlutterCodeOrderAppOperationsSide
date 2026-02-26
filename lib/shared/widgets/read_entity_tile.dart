import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:go_router/go_router.dart';

class ReadEntityTile extends ConsumerWidget {
  final String moduleName; // e.g. "products", "notes"
  final String routeName; // GoRouter named route
  final String title; // Display text
  final IconData icon; // Icon to show
  final Map<String, dynamic>? queryParameters;
  final bool visible;
  final bool allowAnonymous;

  const ReadEntityTile({
    super.key,
    required this.moduleName,
    required this.routeName,
    required this.title,
    required this.icon,
    this.queryParameters,
    this.visible = true,
    this.allowAnonymous = false,
  });

  void navigate(BuildContext context, WidgetRef ref) {
    final rbacService = ref.read(rbacServiceProvider);
    if (!allowAnonymous && !rbacService.canRead(moduleName)) return;

    context.goNamed(
      routeName,
      queryParameters: queryParameters ?? <String, dynamic>{},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch initialization state to trigger rebuilds
    ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    final canRead = allowAnonymous || rbacService.canRead(moduleName);

    if (!canRead || !visible) {
      // Hide tile if user lacks read permission OR explicitly hidden
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => navigate(context, ref),
    );
  }
}
