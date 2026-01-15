import '../models/collection_models.dart';
import '../settings/api_connections.dart';

class CollectionRepository {
  static const String endpoint =
      "/collection?companyId=1"; // Ajusta según tu API real

  // Obtener lista de recolecciones desde la API
  static Future<List<Collection>> getAll() async {
    try {
      final dynamic response = await ApiConnection.get(endpoint);

      if (response == null) {
        print("La respuesta de la API es nula.");
        return [];
      }

      // Si la API devuelve directamente una lista
      if (response is List) {
        return response
            .map((item) => Collection.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }

      // Si la API devuelve un objeto con una lista dentro (por ejemplo, {"data": [...]})
      if (response is Map && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Collection.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }

      print("Formato de respuesta inesperado: $response");
      return [];
    } catch (e) {
      print("Error al obtener recolecciones: $e");
      return [];
    }
  }

  // Crear un nuevo registro de recolección
  Future<Collection?> create(Collection collection) async {
    try {
      final dynamic response = await ApiConnection.post(
        endpoint,
        collection.toMap(),
      );

      if (response != null && response is Map<String, dynamic>) {
        return Collection.fromMap(response);
      }

      print("Respuesta inesperada al crear recolección: $response");
    } catch (e) {
      print("Error al crear recolección: $e");
    }
    return null;
  }

  // Actualizar un registro de recolección existente
  Future<bool> update(Collection collection) async {
    if (collection.id == null) {
      print("No se puede actualizar: el ID es nulo.");
      return false;
    }

    try {
      final dynamic response = await ApiConnection.patch(
        '/collection/${collection.id}',
        collection.toMap(),
      );

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      print("Respuesta inesperada al actualizar: $response");
    } catch (e) {
      print("Error al actualizar recolección: $e");
    }
    return false;
  }

  // Eliminar un registro de recolección por ID
  Future<bool> delete(int id) async {
    try {
      final dynamic response = await ApiConnection.delete('/collection/$id');

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      print("Respuesta inesperada al eliminar: $response");
    } catch (e) {
      print("Error al eliminar recolección: $e");
    }
    return false;
  }
}
