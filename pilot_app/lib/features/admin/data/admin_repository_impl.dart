import 'package:pilot_app/core/domain/dto/auth_dto.dart';
import 'package:pilot_app/core/network/api_client.dart';
import 'package:pilot_app/features/admin/domain/admin_repository.dart';

/// Implementação: GET /api/v1/users, DELETE /api/v1/users/{id}. Requer Bearer (admin).
class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<UserListItemDto>> getUsers() async {
    final r = await _apiClient.dio.get<dynamic>('/api/v1/users');
    final data = r.data;
    if (data == null) return [];
    List<dynamic> list;
    if (data is List<dynamic>) {
      list = data;
    } else if (data is Map<String, dynamic> && data['content'] != null) {
      list = data['content'] as List<dynamic>;
    } else {
      return [];
    }
    return list
        .map((e) => UserListItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteUser(String id) async {
    await _apiClient.dio.delete<void>('/api/v1/users/$id');
  }
}
