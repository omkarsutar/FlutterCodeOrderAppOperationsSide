import '../../../../core/config/field_config.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/utils/date_utils.dart';

/// Processed metadata for entity cards
class EntityCardMetadata {
  final String title;
  final String? formattedTimestamp;
  final bool? isActive;

  EntityCardMetadata({
    required this.title,
    this.formattedTimestamp,
    this.isActive,
  });
}

/// Logic for Entity Card metadata detection and formatting
class EntityCardLogic {
  /// Determines the best title field from available field configs
  /// Avoids numeric and boolean fields, prefers text fields
  static FieldConfig selectTitleField(List<FieldConfig> fieldConfigs) {
    return fieldConfigs.firstWhere(
      (f) => ![
        FieldType.switchField,
        FieldType.dropdown,
        FieldType.doubleField,
        FieldType.intField,
        FieldType.integer,
      ].contains(f.type),
      orElse: () => fieldConfigs.first,
    );
  }

  /// Extracts and formats the title value
  static String extractTitle<T>({
    required T entity,
    required EntityAdapter<T> adapter,
    required FieldConfig titleField,
  }) {
    final rawValue = adapter.getFieldValue(entity, titleField.name);
    final labelValue = adapter.getLabelValue(entity, titleField.name);
    return labelValue?.toString() ?? rawValue?.toString() ?? 'Untitled';
  }

  /// Extracts and formats timestamp if available
  static String? extractFormattedTimestamp<T>({
    required T entity,
    required EntityAdapter<T> adapter,
    required String? timestampField,
  }) {
    if (timestampField == null) return null;

    final timestamp = adapter.getTimestamp(entity, timestampField);
    return timestamp != null ? formatTimestamp(timestamp) : null;
  }

  /// Detects active status from entity
  static bool? extractActiveStatus<T>({
    required T entity,
    required EntityAdapter<T> adapter,
  }) {
    final isActive = adapter.getFieldValue(entity, 'is_active');
    return isActive is bool ? isActive : null;
  }

  /// Processes all metadata for an entity card
  static EntityCardMetadata processMetadata<T>({
    required T entity,
    required EntityAdapter<T> adapter,
    required List<FieldConfig> fieldConfigs,
    required String? timestampField,
  }) {
    final titleField = selectTitleField(fieldConfigs);

    return EntityCardMetadata(
      title: extractTitle(
        entity: entity,
        adapter: adapter,
        titleField: titleField,
      ),
      formattedTimestamp: extractFormattedTimestamp(
        entity: entity,
        adapter: adapter,
        timestampField: timestampField,
      ),
      isActive: extractActiveStatus(entity: entity, adapter: adapter),
    );
  }
}
