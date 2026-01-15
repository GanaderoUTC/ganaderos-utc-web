import '../models/cattle_models.dart';
import '../settings/api_connections.dart';

class CattleCompanyRepository {
  // Obtener ganado por empresa
  static Future<List<Cattle>> getAllByCompany(int companyId) async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        "/cattle?companyId=$companyId",
      );

      return dataList.map((e) => Cattle.fromMap(e)).toList();
    } catch (e) {
      print("❌ Error al obtener ganado por empresa: $e");
      return [];
    }
  }

  // Crear ganado asociado a una empresa
  static Future<Cattle?> createForCompany(Cattle cattle) async {
    try {
      final response = await ApiConnection.post("/cattle", cattle.toMap());

      if (response != null) {
        return Cattle.fromMap(response);
      }
    } catch (e) {
      print("❌ Error al crear ganado para empresa: $e");
    }
    return null;
  }

  // Actualizar ganado
  static Future<bool> updateForCompany(Cattle cattle) async {
    if (cattle.id == null) return false;

    try {
      final result = await ApiConnection.patch(
        "/cattle/${cattle.id}",
        cattle.toMap(),
      );

      return result > 0;
    } catch (e) {
      print("❌ Error al actualizar ganado de empresa: $e");
      return false;
    }
  }

  // Eliminar ganado de una empresa
  static Future<bool> deleteForCompany(int id) async {
    try {
      final result = await ApiConnection.delete("/cattle/$id");
      return result > 0;
    } catch (e) {
      print("❌ Error al eliminar ganado de empresa: $e");
      return false;
    }
  }
}
