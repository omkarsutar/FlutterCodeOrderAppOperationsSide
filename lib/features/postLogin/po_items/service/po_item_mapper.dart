import '../../../../core/services/entity_service.dart';
import '../model/po_item_model.dart';

class PoItemMapper implements EntityMapper<ModelPoItem> {
  @override
  ModelPoItem fromMap(Map<String, dynamic> map) {
    return ModelPoItem.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelPoItem entity) {
    return entity.toMap();
  }
}
