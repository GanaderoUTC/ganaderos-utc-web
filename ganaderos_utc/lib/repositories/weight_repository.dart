import '../models/weight_models.dart';
import '../settings/api_connections.dart';

class WeightRepository {
  static const String baseEndpoint = '/Weight';

  // Obtener todos los registros con companyId
  static Future<List<Weight>> getAll({int companyId = 1}) async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        '$baseEndpoint?companyId=$companyId',
      );

      return dataList.map((data) => Weight.fromMap(data)).toList();
    } catch (e) {
      print("❌ Error al obtener registros de peso: $e");
      return [];
    }
  }

  // Crear un nuevo registro
  Future<Weight?> create(Weight weight) async {
    try {
      final response = await ApiConnection.post(baseEndpoint, weight.toMap());

      if (response != null) {
        return Weight.fromMap(response);
      }
    } catch (e) {
      print("❌ Error al crear registro de peso: $e");
    }
    return null;
  }

  // Actualizar un registro
  Future<bool> update(Weight weight) async {
    if (weight.id == null) return false;

    try {
      final response = await ApiConnection.patch(
        '$baseEndpoint/${weight.id}',
        weight.toMap(),
      );

      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      print("❌ Error al actualizar registro de peso: $e");
      return false;
    }
  }

  // Eliminar un registro
  Future<bool> delete(int id) async {
    try {
      final response = await ApiConnection.delete('$baseEndpoint/$id');

      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      print("❌ Error al eliminar registro de peso: $e");
      return false;
    }
  }
}
