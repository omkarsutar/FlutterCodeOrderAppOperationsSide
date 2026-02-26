import 'package:flutter_riverpod/flutter_riverpod.dart';

class RouteCache {
  final String? routeId;
  final String? routeName;

  const RouteCache({this.routeId, this.routeName});

  RouteCache copyWith({String? routeId, String? routeName}) {
    return RouteCache(
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
    );
  }
}

/// StateProvider for route cache
final routeCacheProvider = StateProvider<RouteCache>((ref) {
  return const RouteCache();
});
