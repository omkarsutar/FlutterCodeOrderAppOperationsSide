import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import '../../core/providers/auth_providers.dart'; // for userProfileProvider

class RouteDropdown extends ConsumerStatefulWidget {
  final void Function(String?) onRouteSelected;
  final String? initialRouteId;
  final bool allowAll;

  const RouteDropdown({
    super.key,
    required this.onRouteSelected,
    this.initialRouteId,
    this.allowAll = false,
  });

  @override
  ConsumerState<RouteDropdown> createState() => _RouteDropdownState();
}

class _RouteDropdownState extends ConsumerState<RouteDropdown> {
  String? selectedRouteId;

  @override
  void initState() {
    super.initState();
    // initialRouteId is passed in OR fallback to profile provider
    final profile = ref.read(userProfileProvider).value;
    selectedRouteId = widget.initialRouteId ?? profile?.preferredRouteId;
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesStreamProvider);
    final theme = Theme.of(context);

    return routesAsync.when(
      data: (routes) {
        if (routes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: null,
              decoration: _buildDecoration(theme),
              items: const [],
              onChanged: null,
              hint: const Text('No routes available'),
            ),
          );
        }

        final items = routes.map((route) {
          return DropdownMenuItem<String>(
            value: route.routeId,
            child: Text(route.routeName),
          );
        }).toList();

        if (widget.allowAll) {
          items.insert(
            0,
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Routes'),
            ),
          );
        }

        final validValues = items.map((item) => item.value).toSet();
        final safeInitialValue = validValues.contains(selectedRouteId)
            ? selectedRouteId
            : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: safeInitialValue,
            decoration: _buildDecoration(theme),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            items: items,
            onChanged: (value) {
              setState(() {
                selectedRouteId = value;
              });
              widget.onRouteSelected(value);
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Error loading routes',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  InputDecoration _buildDecoration(ThemeData theme) {
    return InputDecoration(
      labelText: 'Select Route',
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      prefixIcon: Icon(
        Icons.alt_route_rounded,
        color: theme.colorScheme.primary,
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
