import '../models/collection_models.dart';
import '../settings/api_connections.dart';

class CollectionRepository {
  static const String _basePath = "/collection";

  // ✅ Obtener lista (opcional por empresa)
  static Future<List<Collection>> getAll({int? companyId}) async {
    try {
      final path =
          companyId != null ? "$_basePath?companyId=$companyId" : _basePath;

      // ✅ robusto: evita cast directo a List<Map<String,dynamic>>
      final dynamic res = await ApiConnection.get(path);
      if (res == null) return [];

      List<dynamic> rawList = [];

      if (res is List) {
        rawList = res;
      } else if (res is Map && res['data'] is List) {
        rawList = res['data'] as List;
      } else {
        // ignore: avoid_print
        print("⚠️ Formato inesperado en GET $_basePath: ${res.runtimeType}");
        return [];
      }

      return rawList
          .map((e) => Collection.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print("Error al obtener recolecciones: $e");
      return [];
    }
  }

  // ✅ Crear registro (la empresa va en el body company_id)
  Future<Collection?> create(Collection collection) async {
    try {
      final response = await ApiConnection.post(_basePath, collection.toMap());
      if (response != null) {
        // ✅ robusto: asegura Map<String,dynamic>
        return Collection.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error al crear recolección: $e");
    }
    return null;
  }

  Future<bool> update(Collection collection) async {
    if (collection.id == null) return false;

    try {
      final dynamic result = await ApiConnection.patch(
        "$_basePath/${collection.id}",
        collection.toMap(),
      );

      // ✅ patch puede devolver int o algo similar; intenta cubrir ambos
      if (result is int) return result > 0;
      if (result is bool) return result;
      return result != null;
    } catch (e) {
      // ignore: avoid_print
      print("Error al actualizar recolección: $e");
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final dynamic result = await ApiConnection.delete("$_basePath/$id");

      // ✅ delete puede devolver int o algo similar; intenta cubrir ambos
      if (result is int) return result > 0;
      if (result is bool) return result;
      return result != null;
    } catch (e) {
      // ignore: avoid_print
      print("Error al eliminar recolección: $e");
      return false;
    }
  }
}
