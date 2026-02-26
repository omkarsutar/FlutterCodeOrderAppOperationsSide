import '../../../../core/services/entity_service.dart';
import '../model/user_model.dart';

class UserMapper implements EntityMapper<ModelUser> {
  @override
  ModelUser fromMap(Map<String, dynamic> map) {
    return ModelUser.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelUser entity) {
    return entity.toMap();
  }
}
