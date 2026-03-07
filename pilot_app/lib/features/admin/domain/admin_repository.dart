import 'package:pilot_app/core/domain/dto/auth_dto.dart';

/// Contrato para operações admin-only (lista de usuários, remover). APP-1007.
abstract class AdminRepository {
  Future<List<UserListItemDto>> getUsers();
  Future<void> deleteUser(String id);
}
