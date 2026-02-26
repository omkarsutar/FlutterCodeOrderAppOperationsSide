import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/postLogin/routes/route_barrel.dart';

class RouteLabelWidget extends ConsumerWidget {
  const RouteLabelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeNameAsync = ref.watch(currentRouteNameProvider);

    return routeNameAsync.when(
      data: (routeName) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(8),
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
        child: Center(
          child: Text(
            'Route: $routeName',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
