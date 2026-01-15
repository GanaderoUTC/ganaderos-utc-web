import '../models/vaccine_models.dart';
import '../settings/api_connections.dart';

class VaccineRepository {
  static const String endpoint = "/Vaccines?companyId=1";

  // Obtener lista de vacunas desde la API
  static Future<List<Vaccine>> getAll() async {
    try {
      final List<Map<String, dynamic>> dataList = await ApiConnection.get(
        endpoint,
      );
      return dataList.map((data) => Vaccine.fromMap(data)).toList();
    } catch (e) {
      print("❌ Error al obtener vacunas: $e");
      return [];
    }
  }

  // Crear un nuevo registro de vacuna
  Future<Vaccine?> create(Vaccine vaccine) async {
    try {
      final response = await ApiConnection.post(endpoint, vaccine.toMap());
      if (response != null) {
        return Vaccine.fromMap(response);
      }
    } catch (e) {
      print("❌ Error al crear vacuna: $e");
    }
    return null;
  }

  // Actualizar un registro existente
  Future<bool> update(Vaccine vaccine) async {
    if (vaccine.id == null) return false;
    try {
      final int result = await ApiConnection.patch(
        '/vaccines/${vaccine.id}',
        vaccine.toMap(),
      );
      return result > 0;
    } catch (e) {
      print("❌ Error al actualizar vacuna: $e");
      return false;
    }
  }

  // Eliminar una vacuna por ID
  Future<bool> delete(int id) async {
    try {
      final int result = await ApiConnection.delete('/vaccines/$id');
      return result > 0;
    } catch (e) {
      print("❌ Error al eliminar vacuna: $e");
      return false;
    }
  }
}
