import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/entity_service.dart';
import '../../../../core/services/supabase_entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../model/product_model.dart';

class ProductServiceImpl extends SupabaseEntityService<ModelProduct> {
  final EntityMapper<ModelProduct> _mapper;

  ProductServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelProduct> get mapper => _mapper;

  @override
  String get entityTypeName => 'ModelProduct';

  @override
  String get tableName => ModelProductFields.table;

  @override
  String get idColumn => ModelProductFields.productId;
  @override
  String get createdAt => ModelProductFields.createdAt;

  // --- Convenience methods ---

  /// Get raw maps instead of typed entities
  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final products = await fetchAll(); // uses LoggingEntityService wrapper
    return products.map((p) => mapper.toMap(p)).toList();
  }

  /// Override streamEntitiesImpl to use the view for better performance
  @override
  Stream<List<ModelProduct>> streamEntitiesImpl() {
    final controller = StreamController<List<ModelProduct>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelProductFields.tableViewWithForeignKeyLabels)
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
      channel = client.channel('public:$tableName')
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

  /// Override fetchAll to use the view for better performance
  @override
  Future<List<ModelProduct>> fetchAll() async {
    final response = await client
        .from(ModelProductFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return (response as List).map((e) => mapper.fromMap(e)).toList();
  }

  // --- Override only the custom createImpl ---

  @override
  Future<ModelProduct> createImpl(ModelProduct entity) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No signed-in user found');

    final enriched = mapper.toMap(entity);
    enriched[ModelProductFields.createdBy] = user.id;
    enriched[ModelProductFields.updatedBy] = user.id;

    final inserted = await client
        .from(tableName)
        .insert(enriched)
        .select()
        .single();
    return mapper.fromMap(inserted);
  }
}
