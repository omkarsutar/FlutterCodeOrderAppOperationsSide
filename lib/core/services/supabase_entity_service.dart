import 'package:supabase_flutter/supabase_flutter.dart';

import 'entity_service.dart';
import 'logging_entity_service.dart';
import 'logger_service.dart';

/// A generic base class for Supabase-backed services.
/// Provides default implementations of CRUD and streaming using Supabase.
abstract class SupabaseEntityService<T> extends LoggingEntityService<T> {
  final SupabaseClient client;

  SupabaseEntityService(this.client, LoggerService logger) : super(logger);

  /// Table name in Supabase
  String get tableName;

  /// Primary key column
  String get idColumn;
  String get createdAt;

  /// Mapper to convert between Map and entity
  EntityMapper<T> get mapper;

  // Sorting properties
  String? sortField;
  bool sortAscending = true;

  @override
  void setSortingConfig(String? field, bool ascending) {
    sortField = field;
    sortAscending = ascending;
  }

  @override
  Future<T?> fetchByIdImpl(String id) async {
    final map = await client
        .from(tableName)
        .select()
        .eq(idColumn, id)
        .maybeSingle();
    return map != null ? mapper.fromMap(map) : null;
  }

  @override
  Future<List<T>> fetchAllImpl(String source) async {
    print(
      "From $source For $tableName Inside fetchAllImpl of SupabaseEntityService",
    );
    final maps = await client
        .from(tableName)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return maps.map<T>((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<T> createImpl(T entity) async {
    final inserted = await client
        .from(tableName)
        .insert(mapper.toMap(entity))
        .select()
        .single();
    return mapper.fromMap(inserted);
  }

  @override
  Future<T> updateImpl(String id, T entity) async {
    final updated = await client
        .from(tableName)
        .update(mapper.toMap(entity))
        .eq(idColumn, id)
        .select()
        .single();
    return mapper.fromMap(updated);
  }

  @override
  Future<void> deleteImpl(String id) async {
    await client.from(tableName).delete().eq(idColumn, id);
  }

  @override
  Stream<List<T>> streamEntitiesImpl() async* {
    // Initial fetch
    final initialData = await fetchAllImpl("Initial");
    yield initialData;

    // Listen for changes and re-fetch sorted list
    await for (final _
        in client.from(tableName).stream(primaryKey: [idColumn])) {
      final updatedData = await fetchAllImpl("Listen");
      yield updatedData;
    }
  }

  // Legacy Impl methods
  @override
  Future<T> getEntityByIdImpl(String id) async {
    final entity = await fetchByIdImpl(id);
    if (entity == null) throw Exception('Entity not found');
    return entity;
  }

  @override
  Future<void> insertEntityImpl(T entity) async {
    await createImpl(entity);
  }

  @override
  Future<void> updateEntityImpl(String id, T entity) async {
    await updateImpl(id, entity);
  }

  @override
  Future<void> deleteEntityByIdImpl(String id) async {
    await deleteImpl(id);
  }
}
