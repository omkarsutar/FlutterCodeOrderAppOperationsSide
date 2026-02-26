import 'entity_service.dart';
import 'logger_service.dart';

/// Abstract service that wraps EntityService<T> with automatic logging
/// All implementing classes automatically get logging without writing log statements
abstract class LoggingEntityService<T> implements EntityService<T> {
  final LoggerService logger;

  LoggingEntityService(this.logger);

  /// Get the entity type name for logging (e.g., "ModelNote", "ModelShop")
  String get entityTypeName;

  /// Get the table name for logging
  String get tableName;

  /// Child classes must implement actual fetch logic
  Future<T?> fetchByIdImpl(String id);
  Future<List<T>> fetchAllImpl(String source);
  Future<T> createImpl(T entity);
  Future<T> updateImpl(String id, T entity);
  Future<void> deleteImpl(String id);
  Stream<List<T>> streamEntitiesImpl();
  Future<T> getEntityByIdImpl(String id);
  Future<void> insertEntityImpl(T entity);
  Future<void> updateEntityImpl(String id, T entity);
  Future<void> deleteEntityByIdImpl(String id);

  // --- Public methods with automatic logging ---

  @override
  Future<T?> fetchById(String id) async {
    try {
      logger.info('Fetching $entityTypeName with id=$id from $tableName');
      final result = await fetchByIdImpl(id);
      if (result == null) {
        logger.warning('$entityTypeName with id=$id not found in $tableName');
      } else {
        logger.info('Successfully fetched $entityTypeName with id=$id');
      }
      return result;
    } catch (e, st) {
      logger.error('Failed to fetch $entityTypeName with id=$id', st);
      rethrow;
    }
  }

  @override
  Future<List<T>> fetchAll() async {
    try {
      logger.info('Fetching all $entityTypeName from $tableName');
      final result = await fetchAllImpl("LoggingEntityService");
      logger.info(
        'Successfully fetched ${result.length} items of type $entityTypeName',
      );
      return result;
    } catch (e, st) {
      logger.error('Failed to fetch all $entityTypeName from $tableName', st);
      rethrow;
    }
  }

  @override
  Future<T> create(T entity) async {
    try {
      logger.info('Creating new $entityTypeName in $tableName');
      final result = await createImpl(entity);
      logger.info('Successfully created $entityTypeName');
      return result;
    } catch (e, st) {
      logger.error('Failed to create $entityTypeName', st);
      rethrow;
    }
  }

  @override
  Future<T> update(String id, T entity) async {
    try {
      logger.info('Updating $entityTypeName with id=$id in $tableName');
      final result = await updateImpl(id, entity);
      logger.info('Successfully updated $entityTypeName with id=$id');
      return result;
    } catch (e, st) {
      logger.error('Failed to update $entityTypeName with id=$id', st);
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting $entityTypeName with id=$id from $tableName');
      await deleteImpl(id);
      logger.info('Successfully deleted $entityTypeName with id=$id');
    } catch (e, st) {
      logger.error('Failed to delete $entityTypeName with id=$id', st);
      rethrow;
    }
  }

  @override
  Stream<List<T>> streamEntities() async* {
    try {
      logger.info('Starting stream for $entityTypeName from $tableName');
      await for (final items in streamEntitiesImpl()) {
        logger.info(
          'Stream emitted ${items.length} items of type $entityTypeName',
        );
        yield items;
      }
    } catch (e, st) {
      logger.error('Stream error for $entityTypeName', st);
      rethrow;
    }
  }

  // Legacy methods with logging
  @override
  Future<T> getEntityById(String id) async {
    try {
      logger.info('Getting $entityTypeName with id=$id (legacy method)');
      final result = await getEntityByIdImpl(id);
      logger.info('Successfully retrieved $entityTypeName with id=$id');
      return result;
    } catch (e, st) {
      logger.error('Failed to get $entityTypeName with id=$id', st);
      rethrow;
    }
  }

  @override
  Future<void> insertEntity(T entity) async {
    try {
      logger.info('Inserting new $entityTypeName (legacy method)');
      await insertEntityImpl(entity);
      logger.info('Successfully inserted $entityTypeName');
    } catch (e, st) {
      logger.error('Failed to insert $entityTypeName', st);
      rethrow;
    }
  }

  @override
  Future<void> updateEntity(String id, T entity) async {
    try {
      logger.info('Updating $entityTypeName with id=$id (legacy method)');
      await updateEntityImpl(id, entity);
      logger.info('Successfully updated $entityTypeName with id=$id');
    } catch (e, st) {
      logger.error('Failed to update $entityTypeName with id=$id', st);
      rethrow;
    }
  }

  @override
  Future<void> deleteEntityById(String id) async {
    try {
      logger.info('Deleting $entityTypeName with id=$id (legacy method)');
      await deleteEntityByIdImpl(id);
      logger.info('Successfully deleted $entityTypeName with id=$id');
    } catch (e, st) {
      logger.error('Failed to delete $entityTypeName with id=$id', st);
      rethrow;
    }
  }
}
