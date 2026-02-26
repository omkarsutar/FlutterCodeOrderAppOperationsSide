import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/route_adapter.dart';
import '../model/route_model.dart';
import '../service/route_service_impl.dart';

/// Mapper provider
final routeMapperProvider = Provider<EntityMapper<ModelRoute>>((ref) {
  return ModelRouteMapper();
});

/// Service provider
final routeServiceProvider = Provider<RouteServiceImpl>((ref) {
  return RouteServiceImpl(
    ref.watch(routeMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final routeAdapterProvider = Provider<RouteAdapter>((ref) {
  return RouteAdapter();
});

/// Fetches all routes with automatic disposal
/// Uses StreamProvider for real-time updates
final routesStreamProvider = StreamProvider.autoDispose<List<ModelRoute>>((
  ref,
) {
  final service = ref.read(routeServiceProvider);
  return service.streamEntities();
});

/// Fetches a single route by ID
final routeByIdProvider = FutureProvider.autoDispose
    .family<ModelRoute?, String>((ref, routeId) async {
      final service = ref.read(routeServiceProvider);
      return await service.fetchById(routeId);
    });

/// Provider for the current user's route name
final currentRouteNameProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final userProfile = ref.watch(userProfileProvider).value;
  final routeId = userProfile?.preferredRouteId;
  if (routeId == null || routeId.isEmpty) return 'Unknown';

  try {
    final route = await ref.watch(routeByIdProvider(routeId).future);
    return route?.routeName ?? 'Unknown';
  } catch (e) {
    return 'Unknown';
  }
});

/// State provider for managing route creation/editing
final routeFormProvider =
    StateNotifierProvider.autoDispose<RouteFormNotifier, RouteFormState>(
      (ref) => RouteFormNotifier(ref),
    );

/// Form state for route
class RouteFormState {
  final String routeName;
  final String routeNote;
  final bool isActive;
  final bool isLoading;
  final String? error;

  RouteFormState({
    this.routeName = '',
    this.routeNote = '',
    this.isActive = true,
    this.isLoading = false,
    this.error,
  });

  RouteFormState copyWith({
    String? routeName,
    String? routeNote,
    bool? isActive,
    bool? isLoading,
    String? error,
  }) {
    return RouteFormState(
      routeName: routeName ?? this.routeName,
      routeNote: routeNote ?? this.routeNote,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing route form state
class RouteFormNotifier extends StateNotifier<RouteFormState> {
  final Ref ref;

  RouteFormNotifier(this.ref) : super(RouteFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateRouteName(String name) {
    if (!_mounted) return;
    state = state.copyWith(routeName: name, error: null);
  }

  void updateRouteNote(String note) {
    if (!_mounted) return;
    state = state.copyWith(routeNote: note, error: null);
  }

  void updateIsActive(bool isActive) {
    if (!_mounted) return;
    state = state.copyWith(isActive: isActive, error: null);
  }

  void loadEntity(ModelRoute entity) {
    if (!_mounted) return;
    state = RouteFormState(
      routeName: entity.routeName,
      routeNote: entity.routeNote ?? '',
      isActive: entity.isActive,
    );
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(routeServiceProvider);

      final entity = ModelRoute(
        routeId: entityId,
        routeName: state.routeName,
        routeNote: state.routeNote.isEmpty ? null : state.routeNote,
        isActive: state.isActive,
      );

      if (entityId == null) {
        // Create new
        await service.create(entity);
      } else {
        // Update existing
        await service.update(entityId, entity);
      }

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(routeServiceProvider);
      await service.deleteEntityById(entityId);

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelRouteFields.routeName:
        updateRouteName(value as String);
        break;
      case ModelRouteFields.routeNote:
        updateRouteNote(value as String);
        break;
      case ModelRouteFields.isActive:
        updateIsActive(value as bool);
        break;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}
