import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/field_config.dart';
import 'logger_service.dart';

/// Generic entity service interface for all CRUD operations
/// All services should implement this with their specific type T
abstract class EntityService<T> {
  /// Stream all entities from the database
  Stream<List<T>> streamEntities();

  /// Fetch entity by ID
  Future<T?> fetchById(String id);

  /// Fetch all entities
  Future<List<T>> fetchAll();

  /// Create a new entity
  Future<T> create(T entity);

  /// Update an existing entity
  Future<T> update(String id, T entity);

  /// Delete an entity by ID
  Future<void> delete(String id);

  /// Set sorting configuration
  void setSortingConfig(String? field, bool ascending);

  /// Get entity by ID (legacy method, use fetchById)
  @Deprecated('Use fetchById instead')
  Future<T> getEntityById(String id) async {
    final entity = await fetchById(id);
    if (entity == null) throw Exception('Entity not found');
    return entity;
  }

  /// Insert entity (legacy method, use create)
  @Deprecated('Use create instead')
  Future<void> insertEntity(T entity) async {
    await create(entity);
  }

  /// Update entity (legacy method, use update with Map)
  @Deprecated('Use update instead')
  Future<void> updateEntity(String id, T entity) async {
    await update(id, entity);
  }

  /// Delete entity by ID (legacy method, use delete)
  @Deprecated('Use delete instead')
  Future<void> deleteEntityById(String id) async {
    await delete(id);
  }
}

/// Mapper interface for converting between Map and Entity
abstract class EntityMapper<T> {
  /// Convert Map to Entity
  T fromMap(Map<String, dynamic> map);

  /// Convert Entity to Map
  Map<String, dynamic> toMap(T entity);
}

/// Adapter interface for accessing entity properties dynamically
abstract class EntityAdapter<T> {
  /// Get a field value from entity
  dynamic getFieldValue(T entity, String fieldName);

  /// Get a label value from entity
  dynamic getLabelValue(T entity, String fieldName);

  /// Get ID from entity
  dynamic getId(T entity, String idField);

  /// Get timestamp from entity
  dynamic getTimestamp(T entity, String timestampField);
}

abstract class ForeignKeyAwareService<T> implements EntityService<T> {
  final SupabaseClient client;
  final LoggerService logger;

  ForeignKeyAwareService(this.client, this.logger);

  String get tableName;
  String? get viewName => null;
  String get idColumn;
  String get createdAt;
  EntityMapper<T> get mapper;
  Map<String, ForeignKeyConfig> get foreignKeys;

  // Sorting properties
  String? sortField;
  bool sortAscending = true;

  @override
  void setSortingConfig(String? field, bool ascending) {
    sortField = field;
    sortAscending = ascending;
  }

  // --- New EntityService<T> contract methods ---

  @override
  Future<T?> fetchById(String id) async {
    final source = viewName ?? tableName;
    try {
      logger.info('Fetching $T with id=$id from $source');
      final raw = await client
          .from(source)
          .select()
          .eq(idColumn, id)
          .maybeSingle();
      if (raw == null) {
        logger.warning('$T with id=$id not found in $source');
        return null;
      }

      // If we used a view, we assume it already has labels, but we still call
      // resolveForeignLabelsForSingle to fill in anything missing
      // (it will only fetch if not already present in the map)
      final resolved = await resolveForeignLabelsForSingle(raw);
      return mapper.fromMap(resolved);
    } catch (e, st) {
      logger.error('Failed to fetch $T with id=$id', st);
      rethrow;
    }
  }

  @override
  Future<List<T>> fetchAll() async {
    final source = viewName ?? tableName;
    try {
      logger.info('Fetching all $T from $source');
      final response = await client
          .from(source)
          .select()
          .order(sortField ?? createdAt, ascending: sortAscending);

      // Note: For fetchAll, we don't automatically resolve labels for each item
      // because it's expensive. The views should provide them.

      final result = (response as List).map((e) => mapper.fromMap(e)).toList();
      logger.info('Successfully fetched ${result.length} items of type $T');
      return result;
    } catch (e, st) {
      logger.error('Failed to fetch all $T from $source', st);
      rethrow;
    }
  }

  @override
  Future<T> create(T entity) async {
    try {
      logger.info('Creating new $T in $tableName');
      final inserted = await client
          .from(tableName)
          .insert(mapper.toMap(entity))
          .select()
          .single();
      final resolved = await resolveForeignLabelsForSingle(inserted);
      logger.info('Successfully created $T');
      return mapper.fromMap(resolved);
    } catch (e, st) {
      logger.error('Failed to create $T', st);
      rethrow;
    }
  }

  @override
  Future<T> update(String id, T entity) async {
    try {
      logger.info('Updating $T with id=$id in $tableName');
      final updated = await client
          .from(tableName)
          .update(mapper.toMap(entity))
          .eq(idColumn, id)
          .select()
          .single();
      final resolved = await resolveForeignLabelsForSingle(updated);
      logger.info('Successfully updated $T with id=$id');
      return mapper.fromMap(resolved);
    } catch (e, st) {
      logger.error('Failed to update $T with id=$id', st);
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting $T with id=$id from $tableName');
      await client.from(tableName).delete().eq(idColumn, id);
      logger.info('Successfully deleted $T with id=$id');
    } catch (e, st) {
      logger.error('Failed to delete $T with id=$id', st);
      rethrow;
    }
  }

  @override
  Stream<List<T>> streamEntities() async* {
    try {
      logger.info('Starting sorted stream for $T from $tableName');

      // Initial fetch
      final initialData = await fetchAll();
      yield initialData;

      // Subscribe to changes and re-fetch sorted data
      await for (final _
          in client.from(tableName).stream(primaryKey: [idColumn])) {
        // When any change happens, re-fetch the entire sorted list
        // Note: This is less efficient than native stream but necessary for server-side ordering
        final updatedData = await fetchAll();
        yield updatedData;
      }
    } catch (e, st) {
      logger.error('Stream error for $T', st);
      rethrow;
    }
  }

  // --- Legacy methods now delegate to the new ones ---
  @override
  Future<T> getEntityById(String id) async {
    final entity = await fetchById(id);
    if (entity == null) throw Exception('Entity not found');
    return entity;
  }

  @override
  Future<void> insertEntity(T entity) async {
    await create(entity);
  }

  @override
  Future<void> updateEntity(String id, T entity) async {
    await update(id, entity);
  }

  @override
  Future<void> deleteEntityById(String id) async {
    await delete(id);
  }

  // --- Foreign key resolution helpers ---
  Future<Map<String, dynamic>> resolveForeignLabelsForSingle(
    Map<String, dynamic> entity,
  ) async {
    final resolved = Map<String, dynamic>.from(entity);
    for (final entry in foreignKeys.entries) {
      final key = entry.key;
      final config = entry.value;
      final foreignId = entity[key];
      if (foreignId != null) {
        final labelResult = await client
            .from(config.table)
            .select(config.labelColumn)
            .eq(config.idColumn, foreignId)
            .maybeSingle();
        if (labelResult != null) {
          resolved['${key}_label'] = labelResult[config.labelColumn];
        }
      }
    }
    return resolved;
  }

  /* Future<List<Map<String, dynamic>>> resolveForeignLabelsForList(
    List<Map<String, dynamic>> entities,
  ) async {
    if (entities.isEmpty) return entities;

    // 1. Collect all unique foreign IDs for each foreign key config
    final foreignIdsMap = <String, Set<String>>{};
    for (final entry in foreignKeys.entries) {
      foreignIdsMap[entry.key] = {};
    }

    for (final entity in entities) {
      for (final entry in foreignKeys.entries) {
        final fieldName = entry.key;
        final foreignId = entity[fieldName];
        if (foreignId != null) {
          foreignIdsMap[fieldName]!.add(foreignId.toString());
        }
      }
    }

    // 2. Fetch labels for each foreign key config in batch
    final labelCache =
        <String, Map<String, dynamic>>{}; // "fieldName:id" -> label

    for (final entry in foreignKeys.entries) {
      final fieldName = entry.key;
      final config = entry.value;
      final ids = foreignIdsMap[fieldName]!;

      // Filter out empty IDs to prevent invalid UUID errors
      final validIds = ids.where((id) => id.trim().isNotEmpty).toList();

      if (validIds.isNotEmpty) {
        try {
          // debugPrint('Batch fetching labels for $fieldName from ${config.table} with IDs: $validIds');
          final results = await client
              .from(config.table)
              .select('${config.idColumn}, ${config.labelColumn}')
              .inFilter(config.idColumn, validIds);

          // debugPrint('Batch fetch results for $fieldName: ${results.length} rows');

          for (final row in results) {
            final id = row[config.idColumn].toString();
            final label = row[config.labelColumn];
            labelCache['$fieldName:$id'] = label;
          }
        } catch (e, st) {
          logger.error(
            'Failed to batch fetch foreign labels for $fieldName from ${config.table}',
            st,
          );
          debugPrint('Error batch fetching $fieldName: $e');
        }
      }
    }

    // 3. Assign labels to entities
    for (final entity in entities) {
      for (final entry in foreignKeys.entries) {
        final fieldName = entry.key;
        final foreignId = entity[fieldName];
        if (foreignId != null) {
          final cacheKey = '$fieldName:${foreignId.toString()}';
          entity['${fieldName}_label'] = labelCache[cacheKey] ?? 'Unknown';
        }
      }
    }

    return entities;
  } */
}
