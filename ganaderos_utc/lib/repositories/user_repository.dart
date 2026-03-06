import 'dart:convert';
import '../models/user_models.dart';
import '../settings/api_connections.dart';
import '../utils/storage.dart';

class UserRepository {
  static const String endpoint = "/users";
  static const String endpointLogin = "/users/auth";

  /// ⚠️ ESTA RUTA DEBE EXISTIR EN TU BACKEND
  /// Si tu backend registra en otra ruta, cambia esto:
  /// Ej: "/auth/register" o "/user/register" o "/users"
  static const String endpointRegister = "/users/register";

  // ---------------------------
  // LOGIN (username + password)
  // ---------------------------
  static Future<User?> login(String username, String password) async {
    try {
      final response = await ApiConnection.post(endpointLogin, {
        "username": username.trim(),
        "password": password,
      });

      if (response == null) {
        print("❌ Error: API no respondió.");
        return null;
      }

      // ✅ soporta {user:{...}} o {data:{...}} o {...}
      Map<String, dynamic> userMap = {};
      // ignore: unnecessary_type_check
      if (response is Map) {
        if (response['user'] is Map) {
          userMap = Map<String, dynamic>.from(response['user']);
        } else if (response['data'] is Map) {
          userMap = Map<String, dynamic>.from(response['data']);
        } else {
          userMap = Map<String, dynamic>.from(response);
        }
      }

      if (!userMap.containsKey("id")) {
        print("❌ Credenciales incorrectas / respuesta sin id.");
        return null;
      }

      final user = User.fromMap(userMap);

      await storageSave("isLoggedIn", "true");
      await storageSave("user", jsonEncode(userMap));

      print("✅ Login exitoso");
      return user;
    } catch (e) {
      print("❌ Error en login: $e");
      return null;
    }
  }

  // ---------------------------
  // REGISTRO (POST /users/register)
  // ---------------------------
  static Future<Map<String, dynamic>> register(User user) async {
    try {
      final payload = user.toApiMap(includePassword: true);

      final response = await ApiConnection.register(payload);

      if (response == null) {
        return {"success": false, "message": "El servidor no respondió."};
      }

      if (response["error"] != null) {
        return {"success": false, "message": response["error"].toString()};
      }

      return {"success": true, "message": response["message"] ?? "OK"};
    } catch (e) {
      return {"success": false, "message": "Error en registro: $e"};
    }
  }

  // ---------------------------
  // LISTAR USUARIOS
  // ---------------------------
  static Future<List<User>> getAll() async {
    try {
      final dynamic response = await ApiConnection.get(endpoint);

      // ✅ soporta List o {data:[...]}
      List<dynamic> raw = [];
      if (response is List) {
        raw = response;
      } else if (response is Map && response["data"] is List) {
        raw = response["data"];
      } else {
        return [];
      }

      return raw
          .map((e) => User.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print("❌ Error al obtener usuarios: $e");
      return [];
    }
  }

  // ---------------------------
  // CREAR USUARIO (ADMIN)  POST /users
  // ---------------------------
  Future<User?> create(User user, {bool includePassword = true}) async {
    try {
      final payload = user.toApiMap(includePassword: includePassword);
      final response = await ApiConnection.post(endpoint, payload);
      if (response == null) return null;

      Map<String, dynamic> userMap = {};
      // ignore: unnecessary_type_check
      if (response is Map) {
        if (response['data'] is Map) {
          userMap = Map<String, dynamic>.from(response['data']);
        } else if (response['user'] is Map) {
          userMap = Map<String, dynamic>.from(response['user']);
        } else {
          userMap = Map<String, dynamic>.from(response);
        }
      }

      if (userMap.isEmpty) return null;
      return User.fromMap(userMap);
    } catch (e) {
      print("❌ Error al crear usuario: $e");
      return null;
    }
  }

  // ---------------------------
  // ACTUALIZAR USUARIO (PATCH /users/:id)
  // ---------------------------
  Future<bool> update(User user, {bool updatePassword = false}) async {
    if (user.id == null) return false;

    try {
      final payload = user.toApiMap(includePassword: updatePassword);

      final dynamic response = await ApiConnection.patch(
        "$endpoint/${user.id}",
        payload,
      );

      if (response is int) return response > 0;
      if (response is bool) return response;

      if (response is Map) {
        if (response['success'] == true) return true;
        if (response['ok'] == true) return true;
        if (response.containsKey('id')) return true;
        if (response['data'] is Map && (response['data'] as Map).isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print("❌ Error al actualizar usuario: $e");
      return false;
    }
  }

  // ---------------------------
  // ELIMINAR USUARIO (DELETE /users/:id)
  // ---------------------------
  Future<bool> delete(int id) async {
    try {
      final dynamic response = await ApiConnection.delete("$endpoint/$id");

      if (response is int) return response > 0;
      if (response is bool) return response;

      if (response is Map &&
          (response['success'] == true || response['ok'] == true)) {
        return true;
      }

      return false;
    } catch (e) {
      print("❌ Error al eliminar usuario: $e");
      return false;
    }
  }

  // ---------------------------
  // SESIÓN
  // ---------------------------
  static Future<bool> isLoggedIn() async {
    final val = await storageRead("isLoggedIn");
    return val == "true";
  }

  static Future<User?> getUser() async {
    final data = await storageRead("user");
    if (data == null) return null;

    final decoded = jsonDecode(data);
    if (decoded is! Map) return null;

    return User.fromMap(Map<String, dynamic>.from(decoded));
  }

  static Future<void> logout() async {
    await storageRemove("isLoggedIn");
    await storageRemove("user");
  }

  // ---------------------------
  // EXTRA: validar "1 admin por empresa" (front)
  // (NO reemplaza backend)
  // ---------------------------
  static Future<bool> companyHasAdmin(int companyId) async {
    final users = await getAll();
    return users.any((u) => u.companyId == companyId && u.role == 'admin');
  }
}
