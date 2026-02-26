/// Metadata class for entity naming conventions
/// Used to centralize entity names across the application
class EntityMeta {
  final String entityName;
  final String entityNamePlural;
  final String entityNameLower;
  final String entityNamePluralLower;

  const EntityMeta({
    required this.entityName,
    required this.entityNamePlural,
    required this.entityNameLower,
    required this.entityNamePluralLower,
  });
}
