import '../models/cattle_models.dart';
import '../settings/api_connections.dart';

class CattleRepository {
  static const String _basePath = "/cattle";

  // Obtener TODO el ganado (sin filtrar empresa)
  static Future<List<Cattle>> getAll() async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        _basePath,
      );

      return dataList.map((e) => Cattle.fromMap(e)).toList();
    } catch (e) {
      print("❌ Error al obtener ganado: $e");
      return [];
    }
  }

  // Obtener ganado por empresa
  static Future<List<Cattle>> getAllByCompany(int companyId) async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        "$_basePath?companyId=$companyId",
      );

      return dataList.map((e) => Cattle.fromMap(e)).toList();
    } catch (e) {
      print("❌ Error al obtener ganado por empresa: $e");
      return [];
    }
  }

  // Crear ganado asociado a una empresa
  static Future<Cattle?> create(Cattle cattle) async {
    try {
      final response = await ApiConnection.post(_basePath, cattle.toMap());

      if (response != null) {
        return Cattle.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      print("❌ Error al crear ganado: $e");
    }
    return null;
  }

  // Actualizar ganado
  static Future<bool> update(Cattle cattle) async {
    if (cattle.id == null) return false;

    try {
      final dynamic response = await ApiConnection.patch(
        "$_basePath/${cattle.id}",
        cattle.toMap(),
      );

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      return false;
    } catch (e) {
      print("❌ Error al actualizar ganado: $e");
      return false;
    }
  }

  // Eliminar ganado
  static Future<bool> delete(int id) async {
    try {
      final dynamic response = await ApiConnection.delete("$_basePath/$id");

      if (response is int) return response > 0;
      if (response is Map && response['success'] == true) return true;

      return false;
    } catch (e) {
      print("❌ Error al eliminar ganado: $e");
      return false;
    }
  }
}
