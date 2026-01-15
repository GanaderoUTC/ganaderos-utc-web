import '../models/collection_models.dart';
import '../settings/api_connections.dart';

class CollectionCattleRepository {
  static const String _basePath = "/collection";

  // Obtener recolecciones por CATTLE ID
  //  Intenta filtrar por API
  // Si la API devuelve todo, filtra localmente como respaldo
  static Future<List<Collection>> getAllByCattle(int cattleId) async {
    try {
      final dynamic response = await ApiConnection.get(
        "$_basePath?cattleId=$cattleId",
      );

      if (response == null) return [];

      List<Collection> parsed = [];

      // API devuelve directamente una lista
      if (response is List) {
        parsed =
            response
                .map(
                  (item) => Collection.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList();
      }

      // API devuelve {"data":[...]}
      if (response is Map && response['data'] is List) {
        parsed =
            (response['data'] as List)
                .map(
                  (item) => Collection.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList();
      }

      // Respaldo: si por algún motivo viene mezclado, filtramos en Flutter
      return parsed.where((c) => c.cattleId == cattleId).toList();
    } catch (e) {
      print(" Error al obtener recolecciones por cattleId=$cattleId: $e");
      return [];
    }
  }

  // Crear recolección (OBLIGA a incluir cattleId)
  static Future<Collection?> createForCattle(Collection collection) async {
    try {
      final int cattleId = collection.cattleId;
      // ignore: unnecessary_null_comparison
      if (cattleId == null || cattleId <= 0) {
        throw Exception("cattleId es requerido para crear una recolección.");
      }

      final dynamic response = await ApiConnection.post(
        _basePath,
        collection.toMap(),
      );

      if (response is Map) {
        return Collection.fromMap(Map<String, dynamic>.from(response));
      }

      print(" Respuesta inesperada al crear recolección: $response");
      return null;
    } catch (e) {
      print(" Error al crear recolección: $e");
      return null;
    }
  }

  /// ✅ Actualizar recolección
  static Future<bool> updateForCattle(Collection collection) async {
    try {
      final id = collection.id;
      if (id == null) return false;

      // (opcional pero recomendado) validar cattleId en update también
      final int cattleId = collection.cattleId;
      // ignore: unnecessary_null_comparison
      if (cattleId == null || cattleId <= 0) {
        throw Exception(
          "cattleId es requerido para actualizar una recolección.",
        );
      }

      final dynamic response = await ApiConnection.patch(
        "$_basePath/$id",
        collection.toMap(),
      );

      // Soporta respuestas comunes de APIs
      if (response is int) return response > 0;
      if (response is bool) return response;
      if (response is Map && response['success'] == true) return true;
      if (response is Map && response['id'] != null) return true;

      print(" Respuesta inesperada al actualizar: $response");
      return false;
    } catch (e) {
      print(" Error al actualizar recolección: $e");
      return false;
    }
  }

  /// ✅ Eliminar recolección
  static Future<bool> deleteForCattle(int id) async {
    try {
      if (id <= 0) return false;

      final dynamic response = await ApiConnection.delete("$_basePath/$id");

      if (response is int) return response > 0;
      if (response is bool) return response;
      if (response is Map && response['success'] == true) return true;

      print(" Respuesta inesperada al eliminar: $response");
      return false;
    } catch (e) {
      print(" Error al eliminar recolección: $e");
      return false;
    }
  }
}
