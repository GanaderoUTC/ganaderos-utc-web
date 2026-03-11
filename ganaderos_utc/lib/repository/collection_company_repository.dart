import '../models/collection_models.dart';
import '../settings/api_connections.dart';

class CollectionCattleRepository {
  static const String _basePath = "/collection";

  /// ================================
  /// OBTENER RECOLECCIONES POR CATTLE
  /// ================================
  static Future<List<Collection>> getAllByCattle(int cattleId) async {
    try {
      final dynamic response = await ApiConnection.get(
        "$_basePath?cattleId=$cattleId",
      );

      if (response == null) return [];

      List<dynamic> rawList = [];

      // API puede devolver LIST o {data:[]}
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] is List) {
        rawList = response['data'];
      }

      final parsed =
          rawList
              .map((e) => Collection.fromMap(Map<String, dynamic>.from(e)))
              .toList();

      // filtro de respaldo si API falla
      return parsed.where((c) => c.cattleId == cattleId).toList();
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al obtener recolecciones por cattleId=$cattleId: $e");
      return [];
    }
  }

  /// ================================
  /// CREAR RECOLECCIÓN
  /// ================================
  static Future<Collection?> createForCattle(Collection collection) async {
    try {
      if (collection.cattleId <= 0) {
        throw Exception("cattleId es requerido para crear una recolección.");
      }

      final Map<String, dynamic> data = collection.toMap();

      // debug útil
      // ignore: avoid_print
      print("📤 POST Collection: $data");

      final response = await ApiConnection.post(_basePath, data);

      if (response == null) return null;

      return Collection.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al crear recolección: $e");
      return null;
    }
  }

  /// ================================
  /// ACTUALIZAR RECOLECCIÓN
  /// ================================
  static Future<bool> updateForCattle(Collection collection) async {
    try {
      final id = collection.id;

      if (id == null) {
        // ignore: avoid_print
        print("❌ No se puede actualizar: id es null");
        return false;
      }

      if (collection.cattleId <= 0) {
        throw Exception(
          "cattleId es requerido para actualizar una recolección.",
        );
      }

      final Map<String, dynamic> data = collection.toMap();
      // ignore: avoid_print
      print("📤 PATCH Collection ($id): $data");

      final int result = await ApiConnection.patch("$_basePath/$id", data);

      return result > 0;
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al actualizar recolección: $e");
      return false;
    }
  }

  /// ================================
  /// ELIMINAR RECOLECCIÓN
  /// ================================
  static Future<bool> deleteForCattle(int id) async {
    try {
      if (id <= 0) return false;
      // ignore: avoid_print
      print("🗑 DELETE Collection: $id");

      final int result = await ApiConnection.delete("$_basePath/$id");

      return result > 0;
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error al eliminar recolección: $e");
      return false;
    }
  }
}
