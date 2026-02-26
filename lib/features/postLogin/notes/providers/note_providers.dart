import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/note_adapter.dart';
import '../model/note_model.dart';
import '../service/note_service_impl.dart';

/// Mapper provider
final noteMapperProvider = Provider<EntityMapper<ModelNote>>((ref) {
  return ModelNoteMapper();
});

/// Service provider
final noteServiceProvider = Provider<NoteServiceImpl>((ref) {
  return NoteServiceImpl(
    ref.watch(noteMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final noteAdapterProvider = Provider<NoteAdapter>((ref) {
  return NoteAdapter();
});

/// Fetches all notes with automatic disposal
/// Uses StreamProvider for real-time updates
final notesStreamProvider = StreamProvider.autoDispose<List<ModelNote>>((ref) {
  final service = ref.read(noteServiceProvider);
  return service.streamEntities();
});

/// Fetches a single note by ID
final noteByIdProvider = FutureProvider.autoDispose.family<ModelNote?, String>((
  ref,
  noteId,
) async {
  final service = ref.read(noteServiceProvider);
  return await service.fetchById(noteId);
});

/// State provider for managing note creation/editing
final noteFormProvider =
    StateNotifierProvider.autoDispose<NoteFormNotifier, NoteFormState>(
      (ref) => NoteFormNotifier(ref),
    );

/// Form state for note
class NoteFormState {
  final String body;
  final bool isLoading;
  final String? error;

  NoteFormState({this.body = '', this.isLoading = false, this.error});

  NoteFormState copyWith({String? body, bool? isLoading, String? error}) {
    return NoteFormState(
      body: body ?? this.body,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing note form state
class NoteFormNotifier extends StateNotifier<NoteFormState> {
  final Ref ref;

  NoteFormNotifier(this.ref) : super(NoteFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateBody(String body) {
    if (!_mounted) return;
    state = state.copyWith(body: body, error: null);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (field == ModelNoteFields.body) {
      updateBody(value as String);
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;
    if (state.body.trim().isEmpty) {
      state = state.copyWith(
        error: '${noteEntityMeta.entityName} body cannot be empty',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(noteServiceProvider);
      final entity = ModelNote(noteId: entityId, body: state.body.trim());

      if (entityId == null) {
        // Create new entity
        await service.create(entity);
      } else {
        // Update existing entity
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save ${noteEntityMeta.entityNameLower}: $e',
      );
      return false;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(noteServiceProvider);
      await service.deleteEntityById(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete ${noteEntityMeta.entityNameLower}: $e',
      );
      return false;
    }
  }

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);

  void loadEntity(ModelNote entity) {
    if (!_mounted) return;
    state = state.copyWith(body: entity.body);
  }

  void reset() {
    if (!_mounted) return;
    state = NoteFormState();
  }
}
