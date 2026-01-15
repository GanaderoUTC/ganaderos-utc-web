import 'dart:convert';
import '../models/user_models.dart';
import '../settings/api_connections.dart';
import '../utils/storage.dart';

class UserRepository {
  static const String endpoint = "/users";
  static const String endpointLogin = "/users/auth";

  //  LOGIN (username + password)
  static Future<User?> login(String username, String password) async {
    try {
      final response = await ApiConnection.post(endpointLogin, {
        "username": username,
        "password": password,
      });

      if (response == null) {
        print("❌ Error: API no respondió.");
        return null;
      }

      if (!response.containsKey("id")) {
        print("❌ Credenciales incorrectas");
        return null;
      }

      final user = User.fromMap(response);

      // Guardar sesión
      await storageSave("isLoggedIn", "true");
      await storageSave("user", jsonEncode(response));

      print("✅ Login exitoso");
      return user;
    } catch (e) {
      print("❌ Error en login: $e");
      return null;
    }
  }

  //  REGISTRO DE USUARIO
  static Future<Map<String, dynamic>> register(User user) async {
    try {
      final payload = user.toMap(includePassword: true);

      final response = await ApiConnection.post(endpoint, payload);

      if (response == null) {
        return {"success": false, "message": "El servidor no respondió."};
      }

      if (response.containsKey("error")) {
        return {"success": false, "message": response["error"]};
      }

      return {"success": true, "message": "Usuario registrado correctamente"};
    } catch (e) {
      return {"success": false, "message": "Error en registro: $e"};
    }
  }

  //  LISTA DE USUARIOS
  static Future<List<User>> getAll() async {
    try {
      final List<dynamic> dataList = await ApiConnection.get(endpoint);
      return dataList.map((data) => User.fromMap(data)).toList();
    } catch (e) {
      print("❌ Error al obtener usuarios: $e");
      return [];
    }
  }

  //  CREAR USUARIO
  Future<User?> create(User user) async {
    try {
      final response = await ApiConnection.post(
        endpoint,
        user.toMap(includePassword: true),
      );

      if (response != null) {
        return User.fromMap(response);
      }
    } catch (e) {
      print("❌ Error al crear usuario: $e");
    }
    return null;
  }

  //  ACTUALIZAR USUARIO
  Future<bool> update(User user, {bool updatePassword = false}) async {
    if (user.id == null) return false;

    try {
      final payload = user.toMap(includePassword: updatePassword);

      final int result = await ApiConnection.patch(
        "$endpoint/${user.id}",
        payload,
      );

      return result > 0;
    } catch (e) {
      print("❌ Error al actualizar usuario: $e");
      return false;
    }
  }

  //  ELIMINAR USUARIO
  Future<bool> delete(int id) async {
    try {
      final int result = await ApiConnection.delete("$endpoint/$id");
      return result > 0;
    } catch (e) {
      print("❌ Error al eliminar usuario: $e");
      return false;
    }
  }

  //  SESIÓN
  static Future<bool> isLoggedIn() async {
    final val = await storageRead("isLoggedIn");
    return val == "true";
  }

  static Future<User?> getUser() async {
    final data = await storageRead("user");
    if (data == null) return null;
    return User.fromMap(jsonDecode(data));
  }

  static Future<void> logout() async {
    await storageRemove("isLoggedIn");
    await storageRemove("user");
  }
}
