import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';

const noteEntityMeta = EntityMeta(
  entityName: 'Note',
  entityNameLower: 'note',
  entityNamePlural: 'Notes',
  entityNamePluralLower: 'notes',
);

class ModelNoteFields {
  static const String table = 'tbl_notes';

  static const String noteId = 'note_id';
  static const String body = 'body';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class ModelNote {
  final String? noteId;
  final String body;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ModelNote({this.noteId, required this.body, this.createdAt, this.updatedAt});

  factory ModelNote.fromMap(Map<String, dynamic> map) {
    return ModelNote(
      noteId: map[ModelNoteFields.noteId],
      body: map[ModelNoteFields.body] ?? '',
      createdAt: map[ModelNoteFields.createdAt] != null
          ? DateTime.tryParse(map[ModelNoteFields.createdAt])
          : null,
      updatedAt: map[ModelNoteFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelNoteFields.updatedAt])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (noteId != null) ModelNoteFields.noteId: noteId,
      ModelNoteFields.body: body,
      if (createdAt != null)
        ModelNoteFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelNoteFields.updatedAt: updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'body': body,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ModelNote.fromJson(Map<String, dynamic> json) {
    return ModelNote(
      noteId: json['noteId'] as String,
      body: json['body'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ModelNoteMapper implements EntityMapper<ModelNote> {
  @override
  ModelNote fromMap(Map<String, dynamic> map) => ModelNote.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelNote entity) => entity.toMap();
}
