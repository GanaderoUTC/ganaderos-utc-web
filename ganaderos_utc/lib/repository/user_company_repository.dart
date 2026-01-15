import '../models/user_models.dart';
import '../settings/api_connections.dart';

class UserCompanyRepository {
  static const String _basePath = "/users";

  // Obtener usuarios por COMPANY ID (filtrado seguro)
  static Future<List<User>> getAllByCompany(int companyId) async {
    try {
      final dynamic response = await ApiConnection.get(
        "$_basePath?companyId=$companyId",
      );

      if (response == null) return [];

      // Parseo flexible: List o {data: []}
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] is List) {
        rawList = response['data'] as List;
      } else {
        print(" Formato inesperado en $_basePath: $response");
        return [];
      }

      final parsed =
          rawList
              .map((item) => User.fromMap(Map<String, dynamic>.from(item)))
              .toList();

      // FILTRO FINAL (por si la API NO filtra)
      final filtered =
          parsed.where((u) {
            // prioridad 1: companyId directo
            if (u.companyId != null) return u.companyId == companyId;

            // prioridad 2: company anidada
            final nestedId = u.company?.id;
            if (nestedId != null) return nestedId == companyId;

            return false;
          }).toList();

      return filtered;
    } catch (e) {
      print("❌ Error al obtener usuarios por companyId=$companyId: $e");
      return [];
    }
  }

  // Crear usuario (OBLIGA companyId)
  static Future<User?> createForCompany(User user, {String? password}) async {
    try {
      if (user.companyId == null || user.companyId == 0) {
        throw Exception("companyId es requerido para crear un usuario.");
      }

      // Aquí enviamos un map compatible con tu patrón.
      final payload = user.toMap(includePassword: true);
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }

      final dynamic response = await ApiConnection.post(_basePath, payload);

      if (response != null && response is Map) {
        return User.fromMap(Map<String, dynamic>.from(response));
      }

      print(" Respuesta inesperada al crear usuario: $response");
      return null;
    } catch (e) {
      print(" Error al crear usuario: $e");
      return null;
    }
  }

  // Actualizar usuario
  static Future<bool> updateForCompany(
    User user, {
    bool updatePassword = false,
    String? password,
  }) async {
    try {
      if (user.id == null) return false;

      final payload = user.toMap(includePassword: updatePassword);
      if (updatePassword && password != null && password.isNotEmpty) {
        payload['password'] = password;
      }

      final dynamic response = await ApiConnection.patch(
        "$_basePath/${user.id}",
        payload,
      );

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;
      if (response is Map && response['id'] != null) return true;

      print(" Respuesta inesperada al actualizar: $response");
      return false;
    } catch (e) {
      print(" Error al actualizar usuario: $e");
      return false;
    }
  }

  // Eliminar usuario
  static Future<bool> deleteForCompany(int id) async {
    try {
      final dynamic response = await ApiConnection.delete("$_basePath/$id");

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      return false;
    } catch (e) {
      print(" Error al eliminar usuario: $e");
      return false;
    }
  }
}
