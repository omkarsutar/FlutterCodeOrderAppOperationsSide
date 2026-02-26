import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/config/field_config.dart';
import '../model/po_collection_model.dart';
import '../../purchase_orders/purchase_order_barrel.dart';

class PoCollectionServiceImpl
    extends ForeignKeyAwareService<ModelPoCollection> {
  final EntityMapper<ModelPoCollection> _mapper;

  PoCollectionServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger) {
    sortAscending = false;
  }

  @override
  EntityMapper<ModelPoCollection> get mapper => _mapper;

  @override
  String get tableName => ModelPoCollectionFields.table;

  @override
  String get idColumn => ModelPoCollectionFields.collectionId;

  @override
  Future<List<ModelPoCollection>> fetchAll() async {
    try {
      final response = await client
          .from(ModelPoCollectionFields.tableViewWithForeignKeyLabels)
          .select()
          .order(sortField ?? createdAt, ascending: sortAscending);
      return (response as List).map((e) => mapper.fromMap(e)).toList();
    } catch (e, st) {
      logger.error('Failed to fetch all collections', st);
      rethrow;
    }
  }

  @override
  Future<ModelPoCollection?> fetchById(String id) async {
    try {
      final response = await client
          .from(ModelPoCollectionFields.tableViewWithForeignKeyLabels)
          .select()
          .eq(idColumn, id)
          .maybeSingle();
      if (response == null) return null;
      return mapper.fromMap(response);
    } catch (e, st) {
      logger.error('Failed to fetch collection by id', st);
      rethrow;
    }
  }

  @override
  Stream<List<ModelPoCollection>> streamEntities() async* {
    try {
      // Initial fetch from view
      yield await fetchAll();

      // Listen to base table
      await for (final _
          in client.from(tableName).stream(primaryKey: [idColumn])) {
        yield await fetchAll();
      }
    } catch (e, st) {
      logger.error('Stream error for collections', st);
      rethrow;
    }
  }

  @override
  String get createdAt => ModelPoCollectionFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelPoCollectionFields.poId: const ForeignKeyConfig(
      table: ModelPurchaseOrderFields.table,
      idColumn: ModelPurchaseOrderFields.poId,
      labelColumn: ModelPurchaseOrderFields.poId, // Fallback
    ),
  };

  /// Fetch collection for a specific purchase order
  Future<ModelPoCollection?> fetchByPoId(String poId) async {
    try {
      final response = await client
          .from(tableName)
          .select()
          .eq(ModelPoCollectionFields.poId, poId)
          .maybeSingle();

      if (response == null) return null;
      return mapper.fromMap(response);
    } catch (e, st) {
      logger.error('Error fetching collection for PO $poId', st);
      rethrow;
    }
  }
}
