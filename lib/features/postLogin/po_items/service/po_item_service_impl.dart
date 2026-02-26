import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/purchase_order_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/field_config.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/entity_service.dart';
import '../model/po_item_model.dart';

abstract class PoFilteredEntityService<T> {
  Stream<List<T>> streamItemsByPo(String poId);
  Future<List<T>> fetchEntitiesByPo(String poId);
}

class PoItemServiceImpl extends ForeignKeyAwareService<ModelPoItem>
    implements PoFilteredEntityService<ModelPoItem> {
  final EntityMapper<ModelPoItem> _mapper;

  PoItemServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelPoItem> get mapper => _mapper;

  @override
  String get tableName => ModelPoItemFields.table;

  @override
  String get idColumn => ModelPoItemFields.poItemId;
  @override
  String get createdAt => ModelPoItemFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelPoItemFields.poId: ForeignKeyConfig(
      table: ModelPurchaseOrderFields.table,
      idColumn: ModelPurchaseOrderFields.poId,
      labelColumn: ModelPurchaseOrderFields.poId,
    ),
    ModelPoItemFields.createdBy: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
    ModelPoItemFields.updatedBy: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
  };

  @override
  Stream<List<ModelPoItem>> streamEntities() {
    final controller = StreamController<List<ModelPoItem>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelPoItemFields.tableViewWithForeignKeyLabels)
            .select()
            .order(sortField ?? createdAt, ascending: sortAscending);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:po_items_all')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (_) => fetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  /// Alias for streamEntities() for consistent naming
  Stream<List<ModelPoItem>> stream() => streamEntities();

  @override
  Future<List<ModelPoItem>> fetchAll() async {
    final List<dynamic> data = await client
        .from(ModelPoItemFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);

    return data.map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelPoItem?> fetchById(String id) async {
    try {
      final raw = await client
          .from(ModelPoItemFields.tableViewWithForeignKeyLabels)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      if (raw == null) return null;
      return mapper.fromMap(raw);
    } catch (e) {
      rethrow;
    }
  }

  // --- Custom helpers ---

  /// Fetch raw items for a given purchase order (without mapping)
  Future<List<Map<String, dynamic>>> fetchItemsForPo(String poId) async {
    if (poId.isEmpty) {
      throw Exception('PO ID not provided');
    }

    final items = await client
        .from(tableName)
        .select('*')
        .eq(ModelPoItemFields.poId, poId);

    return List<Map<String, dynamic>>.from(items);
  }

  @override
  Stream<List<ModelPoItem>> streamItemsByPo(String poId) {
    final controller = StreamController<List<ModelPoItem>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelPoItemFields.tableViewWithForeignKeyLabels)
            .select()
            .eq(ModelPoItemFields.poId, poId)
            .order(sortField ?? createdAt, ascending: sortAscending);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName:$poId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: ModelPoItemFields.poId,
            value: poId,
          ),
          callback: (_) => fetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  @override
  Future<List<ModelPoItem>> fetchEntitiesByPo(String poId) async {
    final List<dynamic> result = await client
        .from(ModelPoItemFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(ModelPoItemFields.poId, poId)
        .order(sortField ?? createdAt, ascending: sortAscending);

    return result.map((e) => mapper.fromMap(e)).toList();
  }

  /// Calculate profit for a PO item
  double? calculateProfit(Map<String, dynamic> data) {
    final sellRate = data[ModelPoItemFields.itemSellRate];
    final price = data[ModelPoItemFields.itemPrice];
    if (sellRate == null || price == null) return null;
    return (sellRate as num).toDouble() - (price as num).toDouble();
  }

  /// Insert a PO item linked to a specific PO
  Future<ModelPoItem> insertEntityForPo(
    ModelPoItem entity,
    String selectedPoId,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No signed-in user found');

    final data = mapper.toMap(entity);
    data[ModelPoItemFields.poId] = selectedPoId;
    data[ModelPoItemFields.createdBy] = user.id;
    data[ModelPoItemFields.updatedBy] = user.id;
    data[ModelPoItemFields.profitToShop] = calculateProfit(data);

    final inserted = await client
        .from(tableName)
        .insert(data)
        .select()
        .single();

    return mapper.fromMap(inserted);
  }
}
