import '../../../../core/services/entity_service.dart';
import '../model/note_model.dart';

class NoteAdapter implements EntityAdapter<ModelNote> {
  @override
  dynamic getFieldValue(ModelNote entity, String fieldName) {
    if (fieldName == ModelNoteFields.body) return entity.body;
    if (fieldName == ModelNoteFields.createdAt) return entity.createdAt;
    if (fieldName == ModelNoteFields.updatedAt) return entity.updatedAt;
    return null;
  }

  @override
  dynamic getLabelValue(ModelNote entity, String fieldName) {
    return null; // or custom label logic
  }

  @override
  dynamic getId(ModelNote entity, String idField) => entity.noteId;

  @override
  dynamic getTimestamp(ModelNote entity, String timestampField) {
    return entity.createdAt;
  }
}
