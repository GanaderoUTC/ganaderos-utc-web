import '../models/checkup_models.dart';
import '../settings/api_connections.dart';

class CheckupRepository {
  static const String endpoint =
      "/checkup?companyId=1"; // Ajusta según tu API real

  // Obtener lista de chequeos desde la API
  static Future<List<Checkup>> getAll() async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        endpoint,
      );

      return dataList.map((data) => Checkup.fromMap(data)).toList();
    } catch (e) {
      print("Error al obtener chequeos: $e");
      return [];
    }
  }

  // Crear un nuevo registro de chequeo
  Future<Checkup?> create(Checkup checkup) async {
    try {
      final response = await ApiConnection.post(endpoint, checkup.toMap());
      if (response != null) {
        return Checkup.fromMap(response);
      }
    } catch (e) {
      print("Error al crear chequeo: $e");
    }
    return null;
  }

  // Actualizar un registro de chequeo existente
  Future<bool> update(Checkup checkup) async {
    if (checkup.id == null) return false;
    try {
      final int result = await ApiConnection.patch(
        '/checkup/${checkup.id}', // ruta directa al ID
        checkup.toMap(),
      );
      return result > 0;
    } catch (e) {
      print("Error al actualizar chequeo: $e");
      return false;
    }
  }

  // Eliminar un registro de chequeo por ID
  Future<bool> delete(int id) async {
    try {
      final int result = await ApiConnection.delete('/checkup/$id');
      return result > 0;
    } catch (e) {
      print("Error al eliminar chequeo: $e");
      return false;
    }
  }
}
