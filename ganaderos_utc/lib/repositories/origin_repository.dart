import '../models/origin_models.dart';
import '../settings/api_connections.dart';

class OriginRepository {
  static const String endpoint = "/origin"; // Ruta del endpoint en tu API

  // Obtener todos los orígenes
  static Future<List<Origin>> getAll() async {
    try {
      final List<dynamic> dataList = await ApiConnection.get(endpoint);
      return dataList.map((data) => Origin.fromMap(data)).toList();
    } catch (e) {
      print("Error al obtener orígenes: $e");
      return [];
    }
  }

  // Crear un nuevo origen
  Future<Origin?> insertOrigin(Origin origin) async {
    try {
      final response = await ApiConnection.post(endpoint, origin.toMap());
      if (response != null) {
        return Origin.fromMap(response);
      }
    } catch (e) {
      print("Error al crear origen: $e");
    }
    return null;
  }

  // Actualizar un origen existente
  Future<bool> updateOrigin(Origin origin) async {
    if (origin.id == null) return false;
    try {
      final response = await ApiConnection.patch(
        '$endpoint/${origin.id}',
        origin.toMap(),
      );
      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      print("Error al actualizar origen: $e");
      return false;
    }
  }

  // Eliminar un origen por ID
  Future<bool> deleteOrigin(int id) async {
    try {
      final response = await ApiConnection.delete('$endpoint/$id');
      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      print("Error al eliminar origen: $e");
      return false;
    }
  }
}
