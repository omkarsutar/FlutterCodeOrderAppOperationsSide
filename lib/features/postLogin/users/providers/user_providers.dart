import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/user_adapter.dart';
import '../model/user_model.dart';
import '../service/user_service_impl.dart';

/// Mapper provider
final userMapperProvider = Provider<EntityMapper<ModelUser>>((ref) {
  return ModelUserMapper();
});

/// Service provider
final userServiceProvider = Provider<UserServiceImpl>((ref) {
  return UserServiceImpl(
    ref.watch(userMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final userAdapterProvider = Provider<UserAdapter>((ref) {
  return UserAdapter();
});

/// Fetches all Users with automatic disposal
/// Uses StreamProvider for real-time updates
final usersStreamProvider = StreamProvider.autoDispose<List<ModelUser>>((ref) {
  final service = ref.read(userServiceProvider);
  return service.streamEntities();
});

/// Fetches a single User by ID
final userByIdProvider = FutureProvider.autoDispose.family<ModelUser?, String>((
  ref,
  userId,
) async {
  final service = ref.read(userServiceProvider);
  return await service.fetchById(userId);
});

/// State provider for managing User creation/editing
final userFormProvider =
    StateNotifierProvider.autoDispose<UserFormNotifier, UserFormState>((ref) {
      return UserFormNotifier(ref);
    });

/// Form state for User
class UserFormState {
  final String fullName;
  final String? roleId;
  final String? preferredRouteId;
  final bool isLoading;
  final String? error;

  UserFormState({
    this.fullName = '',
    this.roleId,
    this.preferredRouteId,
    this.isLoading = false,
    this.error,
  });

  UserFormState copyWith({
    String? fullName,
    String? roleId,
    String? preferredRouteId,
    bool? isLoading,
    String? error,
  }) {
    return UserFormState(
      fullName: fullName ?? this.fullName,
      roleId: roleId ?? this.roleId,
      preferredRouteId: preferredRouteId ?? this.preferredRouteId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing User form state
class UserFormNotifier extends StateNotifier<UserFormState> {
  final Ref ref;

  UserFormNotifier(this.ref) : super(UserFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateFullName(String name) {
    if (!_mounted) return;
    state = state.copyWith(fullName: name, error: null);
  }

  void updateRoleId(String? roleId) {
    if (!_mounted) return;
    state = state.copyWith(roleId: roleId, error: null);
  }

  void updatePreferredRouteId(String? routeId) {
    if (!_mounted) return;
    state = state.copyWith(preferredRouteId: routeId, error: null);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelUserFields.fullName:
        updateFullName(value as String);
        break;
      case ModelUserFields.roleId:
        updateRoleId(value as String?);
        break;
      case ModelUserFields.preferredRouteId:
        updatePreferredRouteId(value as String?);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(userServiceProvider);

      final entity = ModelUser(
        userId:
            entityId ?? '', // entityId ignored on create usually, or generated
        fullName: state.fullName,
        roleId: state.roleId,
        preferredRouteId: state.preferredRouteId,
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

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(userServiceProvider);
      await service.deleteEntityById(id);
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
}
