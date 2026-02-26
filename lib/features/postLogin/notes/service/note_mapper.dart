import '../../../../core/services/entity_service.dart';
import '../model/note_model.dart';

class NoteMapper implements EntityMapper<ModelNote> {
  @override
  ModelNote fromMap(Map<String, dynamic> map) {
    // print("Mapping from map: $map");
    return ModelNote.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelNote entity) {
    return entity.toMap();
  }
}
