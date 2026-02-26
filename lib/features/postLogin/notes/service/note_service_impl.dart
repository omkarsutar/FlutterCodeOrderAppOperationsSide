import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../model/note_model.dart';
import '../../../../core/services/supabase_entity_service.dart';

class NoteServiceImpl extends SupabaseEntityService<ModelNote> {
  final EntityMapper<ModelNote> _mapper;

  NoteServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelNote> get mapper => _mapper;

  @override
  String get entityTypeName => 'Model${noteEntityMeta.entityName}';

  @override
  String get tableName => ModelNoteFields.table;

  @override
  String get idColumn => ModelNoteFields.noteId;
  @override
  String get createdAt => ModelNoteFields.createdAt;

  // --- Convenience methods ---

  /// Get raw maps instead of typed entities
  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final notes = await fetchAll(); // uses LoggingEntityService wrapper
    return notes.map((n) => mapper.toMap(n)).toList();
  }
}
