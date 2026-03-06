import '../models/user_models.dart';
import '../settings/api_connections.dart';

class UserCompanyRepository {
  static const String _basePath = "/users";

  static Future<List<User>> getAllByCompany(int companyId) async {
    try {
      // ✅ getList siempre es lista y es coherente con tu ApiConnection
      final List<Map<String, dynamic>> rawList = await ApiConnection.getList(
        "$_basePath?companyId=$companyId",
      );

      final parsed =
          rawList
              .map((item) => User.fromMap(Map<String, dynamic>.from(item)))
              .toList();

      // ✅ FILTRO FINAL (por si la API NO filtra)
      return parsed.where((u) {
        if (u.companyId != null) return u.companyId == companyId;
        final nestedId = u.company?.id;
        if (nestedId != null) return nestedId == companyId;
        return false;
      }).toList();
    } catch (e) {
      print("❌ Error al obtener usuarios por companyId=$companyId: $e");
      return [];
    }
  }

  static Future<User?> createForCompany(User user, {String? password}) async {
    try {
      if (user.companyId == null || user.companyId == 0) {
        throw Exception("companyId es requerido para crear un usuario.");
      }

      final payload = user.toApiMap(includePassword: password != null);

      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }

      final response = await ApiConnection.post(_basePath, payload);
      if (response == null) return null;

      // ✅ normaliza: {data:{...}} o {...}
      final Map<String, dynamic> userMap =
          (response['data'] is Map)
              ? Map<String, dynamic>.from(response['data'])
              : Map<String, dynamic>.from(response);

      if (userMap.isEmpty) return null;
      return User.fromMap(userMap);
    } catch (e) {
      print("❌ Error al crear usuario: $e");
      return null;
    }
  }

  static Future<bool> updateForCompany(
    User user, {
    bool updatePassword = false,
    String? password,
  }) async {
    try {
      if (user.id == null) return false;

      final payload = user.toApiMap(includePassword: updatePassword);

      if (updatePassword && password != null && password.isNotEmpty) {
        payload['password'] = password;
      }

      final dynamic response = await ApiConnection.patch(
        "$_basePath/${user.id}",
        payload,
      );

      // ✅ Acepta varias respuestas
      if (response is int) return response > 0;
      if (response is bool) return response;
      if (response is Map &&
          (response['success'] == true || response['ok'] == true)) {
        return true;
      }
      if (response is Map &&
          (response['id'] != null || response['data'] != null)) {
        return true;
      }

      print("⚠️ Respuesta inesperada al actualizar: $response");
      return false;
    } catch (e) {
      print("❌ Error al actualizar usuario: $e");
      return false;
    }
  }

  static Future<bool> deleteForCompany(int id) async {
    try {
      final dynamic response = await ApiConnection.delete("$_basePath/$id");

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      return false;
    } catch (e) {
      print("❌ Error al eliminar usuario: $e");
      return false;
    }
  }
}
