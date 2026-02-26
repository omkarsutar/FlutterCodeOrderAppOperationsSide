import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../model/route_model.dart';

class RouteServiceImpl extends SupabaseEntityService<ModelRoute> {
  final EntityMapper<ModelRoute> _mapper;

  RouteServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelRoute> get mapper => _mapper;

  @override
  String get entityTypeName => 'ModelRoute';

  @override
  String get tableName => ModelRouteFields.table;

  @override
  String get idColumn => ModelRouteFields.routeId;
  @override
  String get createdAt => ModelRouteFields.createdAt;

  Future<List<Map<String, dynamic>>> fetchRoutes() async {
    final response = await client
        .from(tableName)
        .select('$idColumn, ${ModelRouteFields.routeName}')
        .order(sortField ?? createdAt, ascending: sortAscending);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> fetchRouteName(String routeId) async {
    try {
      final response = await client
          .from(tableName)
          .select(ModelRouteFields.routeName)
          .eq(idColumn, routeId)
          .single();
      return response[ModelRouteFields.routeName] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final routes = await fetchAllImpl("RouteServiceImpl");
    return routes.map((r) => mapper.toMap(r)).toList();
  }
}
